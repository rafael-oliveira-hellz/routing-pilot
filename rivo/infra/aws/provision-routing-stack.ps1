param(
    [string]$ProjectName = 'rivo',
    [string]$AwsRegion = 'sa-east-1',
    [string]$VpcCidr = '10.40.0.0/16',
    [string[]]$AvailabilityZones = @('sa-east-1a', 'sa-east-1b'),
    [string[]]$PublicSubnetCidrs = @('10.40.0.0/24', '10.40.1.0/24'),
    [string[]]$AppSubnetCidrs = @('10.40.10.0/24', '10.40.11.0/24'),
    [string[]]$DbSubnetCidrs = @('10.40.20.0/24', '10.40.21.0/24'),
    [int]$BackendPort = 8080,
    [string]$BucketName = 'routing-data',
    [string]$CodeBuildProjectName = 'osm-postgis-import',
    [string]$CodeBuildRoleName = 'codebuild-routing-role',
    [string]$CodeBuildRolePolicyName = 'codebuild-routing-inline-policy',
    [string]$DbInstanceIdentifier = 'rivo-routing-db',
    [string]$DbName = 'routing',
    [string]$DbUser = 'routing_app',
    [Parameter(Mandatory = $true)]
    [string]$DbPassword,
    [string]$DbInstanceClass = 'db.t4g.large',
    [int]$DbAllocatedStorage = 200,
    [string]$DbEngineVersion = '16.3',
    [switch]$ConfigureGitHubSecrets,
    [string]$GitHubRepo,
    [string]$GitHubAwsAccessKeyId,
    [string]$GitHubAwsSecretAccessKey
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$trustPolicyPath = Join-Path $scriptDir 'codebuild-trust-policy.json'
$logsDir = Join-Path $scriptDir 'logs'
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $logsDir "provision-$runId.log"
$script:RollbackActions = New-Object System.Collections.ArrayList

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
New-Item -ItemType File -Force -Path $logPath | Out-Null

function Write-Log([string]$Message, [string]$Level = 'INFO') {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logPath -Value $line -Encoding UTF8

    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN' { 'Yellow' }
        'STEP' { 'Cyan' }
        'SUCCESS' { 'Green' }
        'DEBUG' { 'DarkGray' }
        default { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color
}

function Write-Step([string]$Message) {
    Write-Log $Message 'STEP'
}

function Format-CommandForLog([string]$FilePath, [string[]]$Args) {
    $segments = @($FilePath)
    foreach ($arg in $Args) {
        if ($arg -match '\s') {
            $segments += ('"{0}"' -f ($arg -replace '"', '\"'))
        } else {
            $segments += $arg
        }
    }
    return ($segments -join ' ')
}

function Invoke-ExternalCommand {
    param(
        [string]$FilePath,
        [string[]]$Args,
        [switch]$AllowFailure,
        [string]$LogLabel
    )

    if ($LogLabel) {
        Write-Log $LogLabel 'DEBUG'
    } else {
        Write-Log ("Running: {0}" -f (Format-CommandForLog -FilePath $FilePath -Args $Args)) 'DEBUG'
    }

    $output = & $FilePath @Args 2>&1
    $exitCode = $LASTEXITCODE
    $text = (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()

    if ($text) {
        foreach ($line in ($text -split "`r?`n")) {
            if ($line) {
                Write-Log $line 'DEBUG'
            }
        }
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed with exit code ${exitCode}: $(Format-CommandForLog -FilePath $FilePath -Args $Args)`n$text"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $text
    }
}

function Invoke-AwsText {
    param(
        [string[]]$Args,
        [switch]$AllowFailure,
        [string]$LogLabel
    )

    $result = Invoke-ExternalCommand -FilePath 'aws' -Args $Args -AllowFailure:$AllowFailure -LogLabel $LogLabel
    return $result.Output
}

function Get-TextValue([string]$Text) {
    if (-not $Text) {
        return $null
    }

    $value = $Text.Trim()
    if (-not $value -or $value -eq 'None' -or $value -eq 'null') {
        return $null
    }

    return $value
}

function Register-RollbackAction([string]$Description, [scriptblock]$Action) {
    [void]$script:RollbackActions.Add([pscustomobject]@{
        Description = $Description
        Action = $Action
    })
}

function Invoke-Rollback {
    if ($script:RollbackActions.Count -eq 0) {
        Write-Log 'Rollback skipped: no new resources were created or changed in this execution.' 'WARN'
        return
    }

    Write-Step 'Failure detected. Starting rollback of resources created or changed in this execution'

    for ($index = $script:RollbackActions.Count - 1; $index -ge 0; $index--) {
        $entry = $script:RollbackActions[$index]
        try {
            Write-Log ("Rollback: {0}" -f $entry.Description) 'WARN'
            & $entry.Action
            Write-Log ("Rollback OK: {0}" -f $entry.Description) 'SUCCESS'
        } catch {
            Write-Log ("Rollback failed for '{0}': {1}" -f $entry.Description, $_.Exception.Message) 'ERROR'
        }
    }
}

function New-TaggedResourceName([string]$Suffix) {
    return "$ProjectName-$Suffix"
}

function ConvertTo-TagSpec([string]$ResourceType, [hashtable]$Tags) {
    $tagEntries = $Tags.GetEnumerator() | ForEach-Object { "{Key=$($_.Key),Value=$($_.Value)}" }
    return "ResourceType=$ResourceType,Tags=[" + ($tagEntries -join ',') + ']'
}

function Get-TaggedEc2Resource([string]$Type, [string]$Name, [string]$Query) {
    $value = Invoke-AwsText -Args @('ec2', "describe-$Type", '--region', $AwsRegion, '--filters', "Name=tag:Name,Values=$Name", '--query', $Query, '--output', 'text') -AllowFailure -LogLabel "Checking existing EC2 resource $Name ($Type)"
    return (Get-TextValue $value)
}

function Set-Vpc {
    $name = New-TaggedResourceName 'vpc'
    $existing = Get-TaggedEc2Resource -Type 'vpcs' -Name $name -Query 'Vpcs[0].VpcId'
    if ($existing) {
        Write-Log "Reusing VPC $existing."
        return $existing
    }

    $tagSpec = ConvertTo-TagSpec -ResourceType 'vpc' -Tags @{ Name = $name; Project = $ProjectName }
    $vpcId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-vpc', '--cidr-block', $VpcCidr, '--region', $AwsRegion, '--tag-specifications', $tagSpec, '--query', 'Vpc.VpcId', '--output', 'text') -LogLabel "Creating VPC $name")
    $createdVpcId = $vpcId
    Register-RollbackAction -Description "Delete VPC $createdVpcId" -Action {
        Invoke-AwsText -Args @('ec2', 'delete-vpc', '--vpc-id', $createdVpcId, '--region', $AwsRegion) -LogLabel "Deleting VPC $createdVpcId during rollback" | Out-Null
    }

    Invoke-AwsText -Args @('ec2', 'modify-vpc-attribute', '--vpc-id', $createdVpcId, '--enable-dns-support', '{"Value":true}', '--region', $AwsRegion) -LogLabel "Enabling DNS support for $createdVpcId" | Out-Null
    Invoke-AwsText -Args @('ec2', 'modify-vpc-attribute', '--vpc-id', $createdVpcId, '--enable-dns-hostnames', '{"Value":true}', '--region', $AwsRegion) -LogLabel "Enabling DNS hostnames for $createdVpcId" | Out-Null
    return $createdVpcId
}

function Set-InternetGateway([string]$VpcId) {
    $name = New-TaggedResourceName 'igw'
    $existing = Get-TaggedEc2Resource -Type 'internet-gateways' -Name $name -Query 'InternetGateways[0].InternetGatewayId'
    if ($existing) {
        $attachResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'attach-internet-gateway', '--internet-gateway-id', $existing, '--vpc-id', $VpcId, '--region', $AwsRegion) -AllowFailure -LogLabel "Ensuring IGW $existing is attached to $VpcId"
        if ($attachResult.ExitCode -ne 0 -and $attachResult.Output -notmatch 'Resource.AlreadyAssociated') {
            throw "Unable to attach existing internet gateway $existing to $VpcId. $($attachResult.Output)"
        }
        Write-Log "Reusing internet gateway $existing."
        return $existing
    }

    $tagSpec = ConvertTo-TagSpec -ResourceType 'internet-gateway' -Tags @{ Name = $name; Project = $ProjectName }
    $igwId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-internet-gateway', '--region', $AwsRegion, '--tag-specifications', $tagSpec, '--query', 'InternetGateway.InternetGatewayId', '--output', 'text') -LogLabel "Creating internet gateway $name")
    $createdIgwId = $igwId
    Register-RollbackAction -Description "Detach and delete internet gateway $createdIgwId" -Action {
        $detachResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'detach-internet-gateway', '--internet-gateway-id', $createdIgwId, '--vpc-id', $VpcId, '--region', $AwsRegion) -AllowFailure -LogLabel "Detaching internet gateway $createdIgwId during rollback"
        if ($detachResult.ExitCode -ne 0 -and $detachResult.Output -notmatch 'Gateway.NotAttached') {
            throw $detachResult.Output
        }
        Invoke-AwsText -Args @('ec2', 'delete-internet-gateway', '--internet-gateway-id', $createdIgwId, '--region', $AwsRegion) -LogLabel "Deleting internet gateway $createdIgwId during rollback" | Out-Null
    }

    Invoke-AwsText -Args @('ec2', 'attach-internet-gateway', '--internet-gateway-id', $createdIgwId, '--vpc-id', $VpcId, '--region', $AwsRegion) -LogLabel "Attaching internet gateway $createdIgwId to $VpcId" | Out-Null
    return $createdIgwId
}

function Set-Subnet([string]$VpcId, [string]$NameSuffix, [string]$Cidr, [string]$Az, [bool]$MapPublicIpOnLaunch) {
    $name = New-TaggedResourceName $NameSuffix
    $existing = Get-TaggedEc2Resource -Type 'subnets' -Name $name -Query 'Subnets[0].SubnetId'
    if ($existing) {
        Write-Log "Reusing subnet $existing ($name)."
        return $existing
    }

    $tagSpec = ConvertTo-TagSpec -ResourceType 'subnet' -Tags @{ Name = $name; Project = $ProjectName; Tier = $NameSuffix }
    $subnetId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-subnet', '--vpc-id', $VpcId, '--cidr-block', $Cidr, '--availability-zone', $Az, '--region', $AwsRegion, '--tag-specifications', $tagSpec, '--query', 'Subnet.SubnetId', '--output', 'text') -LogLabel "Creating subnet $name")
    $createdSubnetId = $subnetId
    Register-RollbackAction -Description "Delete subnet $createdSubnetId" -Action {
        Invoke-AwsText -Args @('ec2', 'delete-subnet', '--subnet-id', $createdSubnetId, '--region', $AwsRegion) -LogLabel "Deleting subnet $createdSubnetId during rollback" | Out-Null
    }

    if ($MapPublicIpOnLaunch) {
        Invoke-AwsText -Args @('ec2', 'modify-subnet-attribute', '--subnet-id', $createdSubnetId, '--map-public-ip-on-launch', '--region', $AwsRegion) -LogLabel "Enabling public IP mapping for subnet $createdSubnetId" | Out-Null
    }

    return $createdSubnetId
}

function Set-RouteTable([string]$VpcId, [string]$NameSuffix) {
    $name = New-TaggedResourceName $NameSuffix
    $existing = Get-TaggedEc2Resource -Type 'route-tables' -Name $name -Query 'RouteTables[0].RouteTableId'
    if ($existing) {
        Write-Log "Reusing route table $existing ($name)."
        return $existing
    }

    $tagSpec = ConvertTo-TagSpec -ResourceType 'route-table' -Tags @{ Name = $name; Project = $ProjectName }
    $routeTableId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-route-table', '--vpc-id', $VpcId, '--region', $AwsRegion, '--tag-specifications', $tagSpec, '--query', 'RouteTable.RouteTableId', '--output', 'text') -LogLabel "Creating route table $name")
    $createdRouteTableId = $routeTableId
    Register-RollbackAction -Description "Delete route table $createdRouteTableId" -Action {
        Invoke-AwsText -Args @('ec2', 'delete-route-table', '--route-table-id', $createdRouteTableId, '--region', $AwsRegion) -LogLabel "Deleting route table $createdRouteTableId during rollback" | Out-Null
    }
    return $createdRouteTableId
}
function Set-Route([string]$RouteTableId, [string]$Cidr, [string]$TargetFlag, [string]$TargetId) {
    $routeStateQuery = "RouteTables[0].Routes[?DestinationCidrBlock=='$Cidr'].State | [0]"
    $existingState = Get-TextValue (Invoke-AwsText -Args @('ec2', 'describe-route-tables', '--route-table-ids', $RouteTableId, '--region', $AwsRegion, '--query', $routeStateQuery, '--output', 'text') -AllowFailure -LogLabel "Checking route $Cidr on route table $RouteTableId")
    if ($existingState) {
        Write-Log "Route $Cidr already exists on route table $RouteTableId."
        return
    }

    $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'create-route', '--route-table-id', $RouteTableId, '--destination-cidr-block', $Cidr, $TargetFlag, $TargetId, '--region', $AwsRegion) -AllowFailure -LogLabel "Creating route $Cidr on route table $RouteTableId"
    if ($result.ExitCode -ne 0) {
        if ($result.Output -match 'RouteAlreadyExists') {
            Write-Log "Route $Cidr already exists on route table $RouteTableId."
            return
        }
        throw "Unable to create route $Cidr on route table $RouteTableId. $($result.Output)"
    }

    $rollbackRouteTableId = $RouteTableId
    $rollbackCidr = $Cidr
    Register-RollbackAction -Description "Delete route $rollbackCidr from route table $rollbackRouteTableId" -Action {
        Invoke-AwsText -Args @('ec2', 'delete-route', '--route-table-id', $rollbackRouteTableId, '--destination-cidr-block', $rollbackCidr, '--region', $AwsRegion) -LogLabel "Deleting route $rollbackCidr from route table $rollbackRouteTableId during rollback" | Out-Null
    }
}

function Set-RouteAssociation([string]$RouteTableId, [string]$SubnetId) {
    $associationQuery = "RouteTables[0].Associations[?SubnetId=='$SubnetId'].RouteTableAssociationId | [0]"
    $associated = Get-TextValue (Invoke-AwsText -Args @('ec2', 'describe-route-tables', '--route-table-ids', $RouteTableId, '--region', $AwsRegion, '--query', $associationQuery, '--output', 'text') -AllowFailure -LogLabel "Checking route table association for subnet $SubnetId")
    if ($associated) {
        Write-Log "Subnet $SubnetId is already associated with route table $RouteTableId."
        return
    }

    $associationId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'associate-route-table', '--route-table-id', $RouteTableId, '--subnet-id', $SubnetId, '--region', $AwsRegion, '--query', 'AssociationId', '--output', 'text') -LogLabel "Associating subnet $SubnetId to route table $RouteTableId")
    $rollbackAssociationId = $associationId
    Register-RollbackAction -Description "Disassociate route table association $rollbackAssociationId" -Action {
        Invoke-AwsText -Args @('ec2', 'disassociate-route-table', '--association-id', $rollbackAssociationId, '--region', $AwsRegion) -LogLabel "Disassociating route table association $rollbackAssociationId during rollback" | Out-Null
    }
}

function Set-ElasticIp {
    $allocationId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'describe-addresses', '--region', $AwsRegion, '--filters', "Name=tag:Name,Values=$(New-TaggedResourceName 'nat-eip')", '--query', 'Addresses[0].AllocationId', '--output', 'text') -AllowFailure -LogLabel 'Checking existing NAT EIP')
    if ($allocationId) {
        Write-Log "Reusing elastic IP allocation $allocationId."
        return $allocationId
    }

    $allocationId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'allocate-address', '--domain', 'vpc', '--region', $AwsRegion, '--query', 'AllocationId', '--output', 'text') -LogLabel 'Allocating NAT elastic IP')
    $createdAllocationId = $allocationId
    Register-RollbackAction -Description "Release elastic IP allocation $createdAllocationId" -Action {
        Invoke-AwsText -Args @('ec2', 'release-address', '--allocation-id', $createdAllocationId, '--region', $AwsRegion) -LogLabel "Releasing elastic IP allocation $createdAllocationId during rollback" | Out-Null
    }

    Invoke-AwsText -Args @('ec2', 'create-tags', '--resources', $createdAllocationId, '--region', $AwsRegion, '--tags', "Key=Name,Value=$(New-TaggedResourceName 'nat-eip')", "Key=Project,Value=$ProjectName") -LogLabel "Tagging elastic IP allocation $createdAllocationId" | Out-Null
    return $createdAllocationId
}

function Set-NatGateway([string]$SubnetId, [string]$AllocationId) {
    $name = New-TaggedResourceName 'nat'
    $natId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'describe-nat-gateways', '--region', $AwsRegion, '--filter', "Name=tag:Name,Values=$name", '--query', 'NatGateways[?State!=`deleted`][0].NatGatewayId', '--output', 'text') -AllowFailure -LogLabel "Checking existing NAT gateway $name")
    if ($natId) {
        Write-Log "Reusing NAT gateway $natId."
        return $natId
    }

    $tagSpec = ConvertTo-TagSpec -ResourceType 'natgateway' -Tags @{ Name = $name; Project = $ProjectName }
    $natId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-nat-gateway', '--subnet-id', $SubnetId, '--allocation-id', $AllocationId, '--region', $AwsRegion, '--tag-specifications', $tagSpec, '--query', 'NatGateway.NatGatewayId', '--output', 'text') -LogLabel "Creating NAT gateway $name")
    $createdNatId = $natId
    Register-RollbackAction -Description "Delete NAT gateway $createdNatId" -Action {
        $deleteResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'delete-nat-gateway', '--nat-gateway-id', $createdNatId, '--region', $AwsRegion) -AllowFailure -LogLabel "Deleting NAT gateway $createdNatId during rollback"
        if ($deleteResult.ExitCode -ne 0 -and $deleteResult.Output -notmatch 'NatGatewayNotFound') {
            throw $deleteResult.Output
        }
        $waitResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'wait', 'nat-gateway-deleted', '--nat-gateway-ids', $createdNatId, '--region', $AwsRegion) -AllowFailure -LogLabel "Waiting for NAT gateway $createdNatId deletion during rollback"
        if ($waitResult.ExitCode -ne 0) {
            Write-Log "NAT gateway $createdNatId deletion wait returned a non-zero status. Review AWS console if needed." 'WARN'
        }
    }

    Invoke-AwsText -Args @('ec2', 'wait', 'nat-gateway-available', '--nat-gateway-ids', $createdNatId, '--region', $AwsRegion) -LogLabel "Waiting for NAT gateway $createdNatId to become available" | Out-Null
    return $createdNatId
}

function Set-SecurityGroup([string]$VpcId, [string]$GroupNameSuffix, [string]$Description) {
    $groupName = New-TaggedResourceName $GroupNameSuffix
    $groupId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'describe-security-groups', '--region', $AwsRegion, '--filters', "Name=vpc-id,Values=$VpcId", "Name=group-name,Values=$groupName", '--query', 'SecurityGroups[0].GroupId', '--output', 'text') -AllowFailure -LogLabel "Checking existing security group $groupName")
    if ($groupId) {
        Write-Log "Reusing security group $groupId ($groupName)."
        return $groupId
    }

    $groupId = Get-TextValue (Invoke-AwsText -Args @('ec2', 'create-security-group', '--group-name', $groupName, '--description', $Description, '--vpc-id', $VpcId, '--region', $AwsRegion, '--query', 'GroupId', '--output', 'text') -LogLabel "Creating security group $groupName")
    $createdGroupId = $groupId
    Register-RollbackAction -Description "Delete security group $createdGroupId" -Action {
        Invoke-AwsText -Args @('ec2', 'delete-security-group', '--group-id', $createdGroupId, '--region', $AwsRegion) -LogLabel "Deleting security group $createdGroupId during rollback" | Out-Null
    }

    Invoke-AwsText -Args @('ec2', 'create-tags', '--resources', $createdGroupId, '--region', $AwsRegion, '--tags', "Key=Name,Value=$groupName", "Key=Project,Value=$ProjectName") -LogLabel "Tagging security group $createdGroupId" | Out-Null
    return $createdGroupId
}

function Set-SgIngressRule([string]$GroupId, [string]$Protocol, [int]$Port, [string]$SourceGroupId, [string]$CidrIp) {
    if ($SourceGroupId) {
        $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'authorize-security-group-ingress', '--group-id', $GroupId, '--protocol', $Protocol, '--port', "$Port", '--source-group', $SourceGroupId, '--region', $AwsRegion) -AllowFailure -LogLabel "Ensuring ingress tcp/$Port from security group $SourceGroupId to $GroupId"
        if ($result.ExitCode -ne 0) {
            if ($result.Output -match 'InvalidPermission\.Duplicate') {
                Write-Log "Ingress tcp/$Port from $SourceGroupId to $GroupId already exists."
                return
            }
            throw "Unable to authorize ingress tcp/$Port from $SourceGroupId to $GroupId. $($result.Output)"
        }

        $rollbackGroupId = $GroupId
        $rollbackSourceGroupId = $SourceGroupId
        Register-RollbackAction -Description "Revoke ingress tcp/$Port from $rollbackSourceGroupId to $rollbackGroupId" -Action {
            Invoke-AwsText -Args @('ec2', 'revoke-security-group-ingress', '--group-id', $rollbackGroupId, '--protocol', $Protocol, '--port', "$Port", '--source-group', $rollbackSourceGroupId, '--region', $AwsRegion) -LogLabel "Revoking ingress tcp/$Port from $rollbackSourceGroupId to $rollbackGroupId during rollback" | Out-Null
        }
        return
    }

    if ($CidrIp) {
        $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'authorize-security-group-ingress', '--group-id', $GroupId, '--protocol', $Protocol, '--port', "$Port", '--cidr', $CidrIp, '--region', $AwsRegion) -AllowFailure -LogLabel "Ensuring ingress tcp/$Port from CIDR $CidrIp to $GroupId"
        if ($result.ExitCode -ne 0) {
            if ($result.Output -match 'InvalidPermission\.Duplicate') {
                Write-Log "Ingress tcp/$Port from $CidrIp to $GroupId already exists."
                return
            }
            throw "Unable to authorize ingress tcp/$Port from $CidrIp to $GroupId. $($result.Output)"
        }

        $rollbackGroupId = $GroupId
        $rollbackCidrIp = $CidrIp
        Register-RollbackAction -Description "Revoke ingress tcp/$Port from $rollbackCidrIp to $rollbackGroupId" -Action {
            Invoke-AwsText -Args @('ec2', 'revoke-security-group-ingress', '--group-id', $rollbackGroupId, '--protocol', $Protocol, '--port', "$Port", '--cidr', $rollbackCidrIp, '--region', $AwsRegion) -LogLabel "Revoking ingress tcp/$Port from $rollbackCidrIp to $rollbackGroupId during rollback" | Out-Null
        }
    }
}

function Set-SgEgressRule([string]$GroupId, [string]$Protocol, [int]$FromPort, [int]$ToPort, [string]$DestinationGroupId, [string]$CidrIp) {
    if ($DestinationGroupId) {
        $permission = "IpProtocol=$Protocol,FromPort=$FromPort,ToPort=$ToPort,UserIdGroupPairs=[{GroupId=$DestinationGroupId}]"
        $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'authorize-security-group-egress', '--group-id', $GroupId, '--ip-permissions', $permission, '--region', $AwsRegion) -AllowFailure -LogLabel "Ensuring egress $Protocol/$FromPort-$ToPort from $GroupId to security group $DestinationGroupId"
        if ($result.ExitCode -ne 0) {
            if ($result.Output -match 'InvalidPermission\.Duplicate') {
                Write-Log "Egress $Protocol/$FromPort-$ToPort from $GroupId to $DestinationGroupId already exists."
                return
            }
            throw "Unable to authorize egress $Protocol/$FromPort-$ToPort from $GroupId to $DestinationGroupId. $($result.Output)"
        }

        $rollbackGroupId = $GroupId
        $rollbackPermission = $permission
        Register-RollbackAction -Description "Revoke egress $Protocol/$FromPort-$ToPort from $rollbackGroupId to $DestinationGroupId" -Action {
            Invoke-AwsText -Args @('ec2', 'revoke-security-group-egress', '--group-id', $rollbackGroupId, '--ip-permissions', $rollbackPermission, '--region', $AwsRegion) -LogLabel "Revoking egress $Protocol/$FromPort-$ToPort from $rollbackGroupId during rollback" | Out-Null
        }
        return
    }

    if ($CidrIp) {
        $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ec2', 'authorize-security-group-egress', '--group-id', $GroupId, '--protocol', $Protocol, '--port', "$FromPort", '--cidr', $CidrIp, '--region', $AwsRegion) -AllowFailure -LogLabel "Ensuring egress $Protocol/$FromPort from $GroupId to CIDR $CidrIp"
        if ($result.ExitCode -ne 0) {
            if ($result.Output -match 'InvalidPermission\.Duplicate') {
                Write-Log "Egress $Protocol/$FromPort from $GroupId to $CidrIp already exists."
                return
            }
            throw "Unable to authorize egress $Protocol/$FromPort from $GroupId to $CidrIp. $($result.Output)"
        }

        $rollbackGroupId = $GroupId
        $rollbackCidrIp = $CidrIp
        Register-RollbackAction -Description "Revoke egress $Protocol/$FromPort from $rollbackGroupId to $rollbackCidrIp" -Action {
            Invoke-AwsText -Args @('ec2', 'revoke-security-group-egress', '--group-id', $rollbackGroupId, '--protocol', $Protocol, '--port', "$FromPort", '--cidr', $rollbackCidrIp, '--region', $AwsRegion) -LogLabel "Revoking egress $Protocol/$FromPort from $rollbackGroupId to $rollbackCidrIp during rollback" | Out-Null
        }
    }
}

function Set-DbSubnetGroup([string[]]$SubnetIds) {
    $name = New-TaggedResourceName 'rds-subnet-group'
    $existing = Get-TextValue (Invoke-AwsText -Args @('rds', 'describe-db-subnet-groups', '--db-subnet-group-name', $name, '--region', $AwsRegion, '--query', 'DBSubnetGroups[0].DBSubnetGroupName', '--output', 'text') -AllowFailure -LogLabel "Checking existing DB subnet group $name")
    if ($existing) {
        Write-Log "Reusing DB subnet group $existing."
        return $name
    }

    $createArgs = @('rds', 'create-db-subnet-group', '--db-subnet-group-name', $name, '--db-subnet-group-description', "$ProjectName RDS subnet group", '--subnet-ids') + $SubnetIds + @('--tags', "Key=Name,Value=$name", "Key=Project,Value=$ProjectName", '--region', $AwsRegion)
    Invoke-AwsText -Args $createArgs -LogLabel "Creating DB subnet group $name" | Out-Null
    $createdSubnetGroupName = $name
    Register-RollbackAction -Description "Delete DB subnet group $createdSubnetGroupName" -Action {
        Invoke-AwsText -Args @('rds', 'delete-db-subnet-group', '--db-subnet-group-name', $createdSubnetGroupName, '--region', $AwsRegion) -LogLabel "Deleting DB subnet group $createdSubnetGroupName during rollback" | Out-Null
    }
    return $name
}
function Set-RdsInstance([string]$DbSubnetGroupName, [string]$RdsSecurityGroupId) {
    $status = Get-TextValue (Invoke-AwsText -Args @('rds', 'describe-db-instances', '--db-instance-identifier', $DbInstanceIdentifier, '--region', $AwsRegion, '--query', 'DBInstances[0].DBInstanceStatus', '--output', 'text') -AllowFailure -LogLabel "Checking existing RDS instance $DbInstanceIdentifier")
    if ($status) {
        Write-Log "RDS instance $DbInstanceIdentifier already exists with status $status."
        if ($status -ne 'available') {
            Invoke-AwsText -Args @('rds', 'wait', 'db-instance-available', '--db-instance-identifier', $DbInstanceIdentifier, '--region', $AwsRegion) -LogLabel "Waiting for existing RDS instance $DbInstanceIdentifier" | Out-Null
        }
        return
    }

    Invoke-AwsText -Args @(
        'rds', 'create-db-instance',
        '--region', $AwsRegion,
        '--db-instance-identifier', $DbInstanceIdentifier,
        '--db-instance-class', $DbInstanceClass,
        '--engine', 'postgres',
        '--engine-version', $DbEngineVersion,
        '--allocated-storage', "$DbAllocatedStorage",
        '--storage-type', 'gp3',
        '--master-username', $DbUser,
        '--master-user-password', $DbPassword,
        '--db-name', $DbName,
        '--port', '5432',
        '--vpc-security-group-ids', $RdsSecurityGroupId,
        '--db-subnet-group-name', $DbSubnetGroupName,
        '--no-publicly-accessible',
        '--backup-retention-period', '7',
        '--storage-encrypted',
        '--deletion-protection',
        '--tags', "Key=Name,Value=$DbInstanceIdentifier", "Key=Project,Value=$ProjectName"
    ) -LogLabel "Creating RDS instance $DbInstanceIdentifier" | Out-Null

    $rollbackDbIdentifier = $DbInstanceIdentifier
    Register-RollbackAction -Description "Delete RDS instance $rollbackDbIdentifier" -Action {
        $modifyResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('rds', 'modify-db-instance', '--db-instance-identifier', $rollbackDbIdentifier, '--no-deletion-protection', '--apply-immediately', '--region', $AwsRegion) -AllowFailure -LogLabel "Disabling deletion protection for $rollbackDbIdentifier during rollback"
        if ($modifyResult.ExitCode -eq 0) {
            $waitAvailable = Invoke-ExternalCommand -FilePath 'aws' -Args @('rds', 'wait', 'db-instance-available', '--db-instance-identifier', $rollbackDbIdentifier, '--region', $AwsRegion) -AllowFailure -LogLabel "Waiting for $rollbackDbIdentifier before deletion during rollback"
            if ($waitAvailable.ExitCode -ne 0) {
                Write-Log "RDS instance $rollbackDbIdentifier did not reach available state before delete. Continuing rollback." 'WARN'
            }
        } elseif ($modifyResult.Output -notmatch 'DBInstanceNotFound') {
            Write-Log "Could not disable deletion protection for $rollbackDbIdentifier. Continuing delete attempt." 'WARN'
        }

        $deleteResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('rds', 'delete-db-instance', '--db-instance-identifier', $rollbackDbIdentifier, '--skip-final-snapshot', '--region', $AwsRegion) -AllowFailure -LogLabel "Deleting RDS instance $rollbackDbIdentifier during rollback"
        if ($deleteResult.ExitCode -ne 0 -and $deleteResult.Output -notmatch 'DBInstanceNotFound') {
            throw $deleteResult.Output
        }

        $waitDeleted = Invoke-ExternalCommand -FilePath 'aws' -Args @('rds', 'wait', 'db-instance-deleted', '--db-instance-identifier', $rollbackDbIdentifier, '--region', $AwsRegion) -AllowFailure -LogLabel "Waiting for RDS instance $rollbackDbIdentifier deletion during rollback"
        if ($waitDeleted.ExitCode -ne 0) {
            Write-Log "RDS instance $rollbackDbIdentifier deletion wait returned a non-zero status. Review AWS console if needed." 'WARN'
        }
    }

    Invoke-AwsText -Args @('rds', 'wait', 'db-instance-available', '--db-instance-identifier', $DbInstanceIdentifier, '--region', $AwsRegion) -LogLabel "Waiting for RDS instance $DbInstanceIdentifier to become available" | Out-Null
}

function Get-RdsEndpoint {
    return (Get-TextValue (Invoke-AwsText -Args @('rds', 'describe-db-instances', '--db-instance-identifier', $DbInstanceIdentifier, '--region', $AwsRegion, '--query', 'DBInstances[0].Endpoint.Address', '--output', 'text') -LogLabel "Reading RDS endpoint for $DbInstanceIdentifier"))
}

function Set-Bucket {
    $headResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('s3api', 'head-bucket', '--bucket', $BucketName, '--region', $AwsRegion) -AllowFailure -LogLabel "Checking existing bucket $BucketName"
    if ($headResult.ExitCode -eq 0) {
        Write-Log "Bucket $BucketName already exists."
        return
    }
    if ($headResult.Output -and $headResult.Output -notmatch '404' -and $headResult.Output -notmatch 'Not Found') {
        throw "Unable to verify bucket $BucketName. $($headResult.Output)"
    }

    if ($AwsRegion -eq 'us-east-1') {
        Invoke-AwsText -Args @('s3', 'mb', "s3://$BucketName", '--region', $AwsRegion) -LogLabel "Creating bucket $BucketName" | Out-Null
    } else {
        Invoke-AwsText -Args @('s3api', 'create-bucket', '--bucket', $BucketName, '--region', $AwsRegion, '--create-bucket-configuration', "LocationConstraint=$AwsRegion") -LogLabel "Creating bucket $BucketName" | Out-Null
    }

    $rollbackBucketName = $BucketName
    Register-RollbackAction -Description "Delete bucket $rollbackBucketName" -Action {
        Invoke-AwsText -Args @('s3', 'rb', "s3://$rollbackBucketName", '--force') -LogLabel "Deleting bucket $rollbackBucketName during rollback" | Out-Null
    }
    Write-Log "Bucket $BucketName created."
}

function Get-ParameterSnapshot([string]$Name) {
    $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('ssm', 'get-parameter', '--name', $Name, '--with-decryption', '--region', $AwsRegion, '--output', 'json') -AllowFailure -LogLabel "Checking current Parameter Store value for $Name"
    if ($result.ExitCode -ne 0) {
        return @{ Exists = $false }
    }

    $payload = $result.Output | ConvertFrom-Json
    return @{
        Exists = $true
        Value = $payload.Parameter.Value
        Type = $payload.Parameter.Type
    }
}

function Set-ParameterValue([string]$Name, [string]$Value, [string]$Type) {
    $snapshot = Get-ParameterSnapshot -Name $Name
    Invoke-AwsText -Args @('ssm', 'put-parameter', '--name', $Name, '--value', $Value, '--type', $Type, '--overwrite', '--region', $AwsRegion) -LogLabel "Writing Parameter Store value for $Name" | Out-Null

    if ($snapshot.Exists) {
        $previousValue = $snapshot.Value
        $previousType = $snapshot.Type
        $parameterName = $Name
        Register-RollbackAction -Description "Restore parameter $parameterName" -Action {
            Invoke-AwsText -Args @('ssm', 'put-parameter', '--name', $parameterName, '--value', $previousValue, '--type', $previousType, '--overwrite', '--region', $AwsRegion) -LogLabel "Restoring Parameter Store value for $parameterName during rollback" | Out-Null
        }
        return
    }

    $parameterName = $Name
    Register-RollbackAction -Description "Delete parameter $parameterName" -Action {
        Invoke-AwsText -Args @('ssm', 'delete-parameter', '--name', $parameterName, '--region', $AwsRegion) -LogLabel "Deleting Parameter Store entry $parameterName during rollback" | Out-Null
    }
}

function Get-InlineRolePolicySnapshot {
    $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('iam', 'get-role-policy', '--role-name', $CodeBuildRoleName, '--policy-name', $CodeBuildRolePolicyName, '--output', 'json') -AllowFailure -LogLabel "Checking current inline policy $CodeBuildRolePolicyName on role $CodeBuildRoleName"
    if ($result.ExitCode -ne 0) {
        return @{ Exists = $false }
    }

    $payload = $result.Output | ConvertFrom-Json
    return @{
        Exists = $true
        PolicyDocumentJson = ($payload.PolicyDocument | ConvertTo-Json -Depth 25 -Compress)
    }
}

function Set-CodeBuildRole {
    $roleResult = Invoke-ExternalCommand -FilePath 'aws' -Args @('iam', 'get-role', '--role-name', $CodeBuildRoleName, '--output', 'json') -AllowFailure -LogLabel "Checking existing IAM role $CodeBuildRoleName"
    $roleCreated = $false
    if ($roleResult.ExitCode -ne 0) {
        Invoke-AwsText -Args @('iam', 'create-role', '--role-name', $CodeBuildRoleName, '--assume-role-policy-document', "file://$trustPolicyPath") -LogLabel "Creating IAM role $CodeBuildRoleName" | Out-Null
        $roleCreated = $true
        $rollbackRoleName = $CodeBuildRoleName
        $rollbackPolicyName = $CodeBuildRolePolicyName
        Register-RollbackAction -Description "Delete IAM role $rollbackRoleName" -Action {
            $policyDelete = Invoke-ExternalCommand -FilePath 'aws' -Args @('iam', 'delete-role-policy', '--role-name', $rollbackRoleName, '--policy-name', $rollbackPolicyName) -AllowFailure -LogLabel "Deleting inline policy $rollbackPolicyName from role $rollbackRoleName during rollback"
            if ($policyDelete.ExitCode -ne 0 -and $policyDelete.Output -notmatch 'NoSuchEntity') {
                throw $policyDelete.Output
            }
            Invoke-AwsText -Args @('iam', 'delete-role', '--role-name', $rollbackRoleName) -LogLabel "Deleting IAM role $rollbackRoleName during rollback" | Out-Null
        }
        Write-Log "Role $CodeBuildRoleName created."
    } else {
        Write-Log "Role $CodeBuildRoleName already exists."
    }

    $previousPolicy = Get-InlineRolePolicySnapshot
    $policyDocument = @{
        Version = '2012-10-17'
        Statement = @(
            @{
                Sid = 'AllowRoutingBucketAccess'
                Effect = 'Allow'
                Action = @('s3:GetObject', 's3:PutObject', 's3:DeleteObject', 's3:ListBucket')
                Resource = @("arn:aws:s3:::$BucketName", "arn:aws:s3:::$BucketName/*")
            },
            @{
                Sid = 'AllowRoutingParameterStoreRead'
                Effect = 'Allow'
                Action = @('ssm:GetParameter', 'ssm:GetParameters', 'ssm:GetParametersByPath')
                Resource = 'arn:aws:ssm:*:*:parameter/routing/*'
            },
            @{
                Sid = 'AllowKmsDecryptForParameters'
                Effect = 'Allow'
                Action = @('kms:Decrypt')
                Resource = '*'
            },
            @{
                Sid = 'AllowVpcNetworkInterfaces'
                Effect = 'Allow'
                Action = @('ec2:CreateNetworkInterface', 'ec2:DescribeNetworkInterfaces', 'ec2:DeleteNetworkInterface', 'ec2:DescribeSubnets', 'ec2:DescribeSecurityGroups', 'ec2:DescribeDhcpOptions', 'ec2:DescribeVpcs')
                Resource = '*'
            },
            @{
                Sid = 'AllowLogs'
                Effect = 'Allow'
                Action = @('logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents')
                Resource = '*'
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-AwsText -Args @('iam', 'put-role-policy', '--role-name', $CodeBuildRoleName, '--policy-name', $CodeBuildRolePolicyName, '--policy-document', $policyDocument) -LogLabel "Applying inline policy $CodeBuildRolePolicyName to role $CodeBuildRoleName" | Out-Null

    if ($previousPolicy.Exists) {
        $restorePolicyDocument = $previousPolicy.PolicyDocumentJson
        $restoreRoleName = $CodeBuildRoleName
        $restorePolicyName = $CodeBuildRolePolicyName
        Register-RollbackAction -Description "Restore inline policy $restorePolicyName on role $restoreRoleName" -Action {
            Invoke-AwsText -Args @('iam', 'put-role-policy', '--role-name', $restoreRoleName, '--policy-name', $restorePolicyName, '--policy-document', $restorePolicyDocument) -LogLabel "Restoring inline policy $restorePolicyName on role $restoreRoleName during rollback" | Out-Null
        }
    } elseif (-not $roleCreated) {
        $restoreRoleName = $CodeBuildRoleName
        $restorePolicyName = $CodeBuildRolePolicyName
        Register-RollbackAction -Description "Delete inline policy $restorePolicyName from role $restoreRoleName" -Action {
            Invoke-AwsText -Args @('iam', 'delete-role-policy', '--role-name', $restoreRoleName, '--policy-name', $restorePolicyName) -LogLabel "Deleting inline policy $restorePolicyName from role $restoreRoleName during rollback" | Out-Null
        }
    }

    Write-Log "Inline policy $CodeBuildRolePolicyName applied to role $CodeBuildRoleName."
}
function Get-CodeBuildProjectSnapshot {
    $result = Invoke-ExternalCommand -FilePath 'aws' -Args @('codebuild', 'batch-get-projects', '--names', $CodeBuildProjectName, '--region', $AwsRegion, '--output', 'json') -AllowFailure -LogLabel "Checking existing CodeBuild project $CodeBuildProjectName"
    if ($result.ExitCode -ne 0) {
        return @{ Exists = $false }
    }

    $payload = $result.Output | ConvertFrom-Json
    if (-not $payload.projects -or $payload.projects.Count -eq 0) {
        return @{ Exists = $false }
    }

    $project = $payload.projects[0]
    return @{
        Exists = $true
        SourceJson = ($project.source | ConvertTo-Json -Depth 30 -Compress)
        ArtifactsJson = ($project.artifacts | ConvertTo-Json -Depth 30 -Compress)
        EnvironmentJson = ($project.environment | ConvertTo-Json -Depth 30 -Compress)
        ServiceRole = $project.serviceRole
        TimeoutInMinutes = [int]$project.timeoutInMinutes
        VpcConfigJson = if ($project.vpcConfig) { $project.vpcConfig | ConvertTo-Json -Depth 30 -Compress } else { $null }
    }
}

function Set-CodeBuildProject([string]$VpcId, [string[]]$SubnetIds, [string]$CodeBuildSecurityGroupId) {
    $accountId = (Get-TextValue (Invoke-AwsText -Args @('sts', 'get-caller-identity', '--query', 'Account', '--output', 'text') -LogLabel 'Resolving AWS account id for CodeBuild service role'))
    $serviceRoleArn = "arn:aws:iam::$accountId:role/$CodeBuildRoleName"

    $sourceJson = @{ type = 'NO_SOURCE'; buildspec = "version: 0.2`nphases:`n  build:`n    commands:`n      - echo see buildspec override" } | ConvertTo-Json -Compress
    $artifactsJson = @{ type = 'NO_ARTIFACTS' } | ConvertTo-Json -Compress
    $environmentJson = @{
        type = 'LINUX_CONTAINER'
        image = 'aws/codebuild/amazonlinux2-x86_64-standard:5.0'
        computeType = 'BUILD_GENERAL1_LARGE'
        privilegedMode = $false
    } | ConvertTo-Json -Compress
    $vpcConfigJson = @{
        vpcId = $VpcId
        subnets = $SubnetIds
        securityGroupIds = @($CodeBuildSecurityGroupId)
    } | ConvertTo-Json -Compress

    $existingProject = Get-CodeBuildProjectSnapshot
    $baseArgs = @(
        '--name', $CodeBuildProjectName,
        '--source', $sourceJson,
        '--artifacts', $artifactsJson,
        '--environment', $environmentJson,
        '--service-role', $serviceRoleArn,
        '--vpc-config', $vpcConfigJson,
        '--timeout-in-minutes', '180',
        '--region', $AwsRegion
    )

    if ($existingProject.Exists) {
        Invoke-AwsText -Args (@('codebuild', 'update-project') + $baseArgs) -LogLabel "Updating CodeBuild project $CodeBuildProjectName" | Out-Null
        $restoreProjectName = $CodeBuildProjectName
        $restoreArgs = @(
            'codebuild', 'update-project',
            '--name', $restoreProjectName,
            '--source', $existingProject.SourceJson,
            '--artifacts', $existingProject.ArtifactsJson,
            '--environment', $existingProject.EnvironmentJson,
            '--service-role', $existingProject.ServiceRole,
            '--timeout-in-minutes', "$($existingProject.TimeoutInMinutes)",
            '--region', $AwsRegion
        )
        if ($existingProject.VpcConfigJson) {
            $restoreArgs += @('--vpc-config', $existingProject.VpcConfigJson)
        }
        Register-RollbackAction -Description "Restore CodeBuild project $restoreProjectName" -Action {
            Invoke-AwsText -Args $restoreArgs -LogLabel "Restoring CodeBuild project $restoreProjectName during rollback" | Out-Null
        }
        Write-Log "CodeBuild project $CodeBuildProjectName updated."
        return
    }

    Invoke-AwsText -Args (@('codebuild', 'create-project') + $baseArgs) -LogLabel "Creating CodeBuild project $CodeBuildProjectName" | Out-Null
    $createdProjectName = $CodeBuildProjectName
    Register-RollbackAction -Description "Delete CodeBuild project $createdProjectName" -Action {
        Invoke-AwsText -Args @('codebuild', 'delete-project', '--name', $createdProjectName, '--region', $AwsRegion) -LogLabel "Deleting CodeBuild project $createdProjectName during rollback" | Out-Null
    }
    Write-Log "CodeBuild project $CodeBuildProjectName created."
}

function Validate-Infrastructure([string]$CodeBuildSecurityGroupId, [string]$RdsSecurityGroupId, [string]$DbHost) {
    $failures = New-Object System.Collections.ArrayList

    function Test-Step([string]$Label, [scriptblock]$Action, [System.Collections.ArrayList]$Failures) {
        try {
            & $Action | Out-Null
            Write-Log "[OK] $Label" 'SUCCESS'
        } catch {
            [void]$Failures.Add("$Label -> $($_.Exception.Message)")
            Write-Log "[FAIL] $Label -> $($_.Exception.Message)" 'ERROR'
        }
    }

    Test-Step -Label 'AWS identity' -Failures $failures -Action {
        Invoke-AwsText -Args @('sts', 'get-caller-identity', '--output', 'json') -LogLabel 'Validating AWS identity' | Out-Null
    }
    Test-Step -Label 'S3 bucket exists' -Failures $failures -Action {
        Invoke-AwsText -Args @('s3api', 'head-bucket', '--bucket', $BucketName, '--region', $AwsRegion) -LogLabel "Validating bucket $BucketName" | Out-Null
    }
    foreach ($paramName in @('/routing/rds/host', '/routing/rds/dbname', '/routing/rds/user', '/routing/rds/password')) {
        Test-Step -Label "Parameter Store $paramName" -Failures $failures -Action {
            Invoke-AwsText -Args @('ssm', 'get-parameter', '--name', $paramName, '--region', $AwsRegion, '--with-decryption') -LogLabel "Validating parameter $paramName" | Out-Null
        }
    }
    Test-Step -Label "IAM role $CodeBuildRoleName" -Failures $failures -Action {
        Invoke-AwsText -Args @('iam', 'get-role', '--role-name', $CodeBuildRoleName) -LogLabel "Validating IAM role $CodeBuildRoleName" | Out-Null
    }
    Test-Step -Label "CodeBuild project $CodeBuildProjectName" -Failures $failures -Action {
        $payload = Invoke-AwsText -Args @('codebuild', 'batch-get-projects', '--names', $CodeBuildProjectName, '--region', $AwsRegion, '--output', 'json') -LogLabel "Validating CodeBuild project $CodeBuildProjectName"
        $projectPayload = $payload | ConvertFrom-Json
        if (-not $projectPayload.projects -or $projectPayload.projects.Count -eq 0) {
            throw 'Project not found.'
        }
    }
    Test-Step -Label 'RDS endpoint available' -Failures $failures -Action {
        if (-not $DbHost) { throw 'RDS endpoint is empty.' }
    }
    Test-Step -Label 'RDS security group resolved' -Failures $failures -Action {
        if (-not $RdsSecurityGroupId) { throw 'RDS security group id is empty.' }
    }
    Test-Step -Label 'CodeBuild security group resolved' -Failures $failures -Action {
        if (-not $CodeBuildSecurityGroupId) { throw 'CodeBuild security group id is empty.' }
    }

    if ($failures.Count -gt 0) {
        throw ("Infrastructure validation failed:`n- " + ($failures -join "`n- "))
    }
}

function Configure-GitHubSecretsIfRequested {
    if (-not $ConfigureGitHubSecrets) {
        return
    }
    if (-not $GitHubRepo) {
        throw 'GitHubRepo is required when ConfigureGitHubSecrets is used.'
    }
    if (-not $GitHubAwsAccessKeyId) {
        throw 'GitHubAwsAccessKeyId is required when ConfigureGitHubSecrets is used.'
    }
    if (-not $GitHubAwsSecretAccessKey) {
        throw 'GitHubAwsSecretAccessKey is required when ConfigureGitHubSecrets is used.'
    }

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) not found. Install gh or rerun without ConfigureGitHubSecrets.'
    }

    Write-Step 'Configuring GitHub Secrets and Variables'
    Invoke-ExternalCommand -FilePath 'gh' -Args @('secret', 'set', 'AWS_ACCESS_KEY_ID', '--repo', $GitHubRepo, '--body', $GitHubAwsAccessKeyId) -LogLabel 'Setting GitHub secret AWS_ACCESS_KEY_ID' | Out-Null
    Invoke-ExternalCommand -FilePath 'gh' -Args @('secret', 'set', 'AWS_SECRET_ACCESS_KEY', '--repo', $GitHubRepo, '--body', $GitHubAwsSecretAccessKey) -LogLabel 'Setting GitHub secret AWS_SECRET_ACCESS_KEY' | Out-Null
    Invoke-ExternalCommand -FilePath 'gh' -Args @('variable', 'set', 'AWS_REGION', '--repo', $GitHubRepo, '--body', $AwsRegion) -LogLabel 'Setting GitHub variable AWS_REGION' | Out-Null
    Write-Log 'GitHub secrets and variable configured.' 'SUCCESS'
}

Write-Log "Provisioning log started at $logPath"

try {
    Write-Step 'Checking AWS identity'
    Invoke-AwsText -Args @('sts', 'get-caller-identity', '--region', $AwsRegion) -LogLabel 'Checking AWS caller identity' | Out-Null

    Write-Step 'Creating or reusing network base'
    $vpcId = Set-Vpc
    $igwId = Set-InternetGateway -VpcId $vpcId
    $publicSubnetA = Set-Subnet -VpcId $vpcId -NameSuffix 'public-a' -Cidr $PublicSubnetCidrs[0] -Az $AvailabilityZones[0] -MapPublicIpOnLaunch $true
    $publicSubnetB = Set-Subnet -VpcId $vpcId -NameSuffix 'public-b' -Cidr $PublicSubnetCidrs[1] -Az $AvailabilityZones[1] -MapPublicIpOnLaunch $true
    $appSubnetA = Set-Subnet -VpcId $vpcId -NameSuffix 'app-a' -Cidr $AppSubnetCidrs[0] -Az $AvailabilityZones[0] -MapPublicIpOnLaunch $false
    $appSubnetB = Set-Subnet -VpcId $vpcId -NameSuffix 'app-b' -Cidr $AppSubnetCidrs[1] -Az $AvailabilityZones[1] -MapPublicIpOnLaunch $false
    $dbSubnetA = Set-Subnet -VpcId $vpcId -NameSuffix 'db-a' -Cidr $DbSubnetCidrs[0] -Az $AvailabilityZones[0] -MapPublicIpOnLaunch $false
    $dbSubnetB = Set-Subnet -VpcId $vpcId -NameSuffix 'db-b' -Cidr $DbSubnetCidrs[1] -Az $AvailabilityZones[1] -MapPublicIpOnLaunch $false
    $publicRt = Set-RouteTable -VpcId $vpcId -NameSuffix 'rt-public'
    $appRt = Set-RouteTable -VpcId $vpcId -NameSuffix 'rt-app'
    $dbRt = Set-RouteTable -VpcId $vpcId -NameSuffix 'rt-db'
    $allocationId = Set-ElasticIp
    $natId = Set-NatGateway -SubnetId $publicSubnetA -AllocationId $allocationId
    Set-Route -RouteTableId $publicRt -Cidr '0.0.0.0/0' -TargetFlag '--gateway-id' -TargetId $igwId
    Set-Route -RouteTableId $appRt -Cidr '0.0.0.0/0' -TargetFlag '--nat-gateway-id' -TargetId $natId
    Set-RouteAssociation -RouteTableId $publicRt -SubnetId $publicSubnetA
    Set-RouteAssociation -RouteTableId $publicRt -SubnetId $publicSubnetB
    Set-RouteAssociation -RouteTableId $appRt -SubnetId $appSubnetA
    Set-RouteAssociation -RouteTableId $appRt -SubnetId $appSubnetB
    Set-RouteAssociation -RouteTableId $dbRt -SubnetId $dbSubnetA
    Set-RouteAssociation -RouteTableId $dbRt -SubnetId $dbSubnetB
    $rdsSg = Set-SecurityGroup -VpcId $vpcId -GroupNameSuffix 'rds-sg' -Description 'RDS access for rivo app and CodeBuild'
    $codeBuildSg = Set-SecurityGroup -VpcId $vpcId -GroupNameSuffix 'codebuild-sg' -Description 'CodeBuild access for rivo imports'
    $appSg = Set-SecurityGroup -VpcId $vpcId -GroupNameSuffix 'app-sg' -Description 'App access for rivo backend'
    $albSg = Set-SecurityGroup -VpcId $vpcId -GroupNameSuffix 'alb-sg' -Description 'ALB access for rivo'
    Set-SgIngressRule -GroupId $rdsSg -Protocol 'tcp' -Port 5432 -SourceGroupId $codeBuildSg -CidrIp $null
    Set-SgIngressRule -GroupId $rdsSg -Protocol 'tcp' -Port 5432 -SourceGroupId $appSg -CidrIp $null
    Set-SgIngressRule -GroupId $appSg -Protocol 'tcp' -Port $BackendPort -SourceGroupId $albSg -CidrIp $null
    Set-SgIngressRule -GroupId $albSg -Protocol 'tcp' -Port 80 -SourceGroupId $null -CidrIp '0.0.0.0/0'
    Set-SgIngressRule -GroupId $albSg -Protocol 'tcp' -Port 443 -SourceGroupId $null -CidrIp '0.0.0.0/0'
    Set-SgEgressRule -GroupId $codeBuildSg -Protocol 'tcp' -FromPort 5432 -ToPort 5432 -DestinationGroupId $rdsSg -CidrIp $null
    Set-SgEgressRule -GroupId $appSg -Protocol 'tcp' -FromPort 5432 -ToPort 5432 -DestinationGroupId $rdsSg -CidrIp $null
    Set-SgEgressRule -GroupId $albSg -Protocol 'tcp' -FromPort $BackendPort -ToPort $BackendPort -DestinationGroupId $appSg -CidrIp $null
    $dbSubnetGroup = Set-DbSubnetGroup -SubnetIds @($dbSubnetA, $dbSubnetB)

    Write-Step 'Creating or reusing RDS instance'
    Set-RdsInstance -DbSubnetGroupName $dbSubnetGroup -RdsSecurityGroupId $rdsSg
    $dbHost = Get-RdsEndpoint

    Write-Step 'Creating or reusing bucket, Parameter Store, CodeBuild role and CodeBuild project'
    Set-Bucket
    Set-ParameterValue -Name '/routing/rds/host' -Value $dbHost -Type 'SecureString'
    Set-ParameterValue -Name '/routing/rds/dbname' -Value $DbName -Type 'String'
    Set-ParameterValue -Name '/routing/rds/user' -Value $DbUser -Type 'String'
    Set-ParameterValue -Name '/routing/rds/password' -Value $DbPassword -Type 'SecureString'
    Set-CodeBuildRole
    Set-CodeBuildProject -VpcId $vpcId -SubnetIds @($appSubnetA, $appSubnetB) -CodeBuildSecurityGroupId $codeBuildSg

    Write-Step 'Validating infrastructure'
    Validate-Infrastructure -CodeBuildSecurityGroupId $codeBuildSg -RdsSecurityGroupId $rdsSg -DbHost $dbHost

    Write-Step 'Provisioning summary'
    Write-Log "VPC:                    $vpcId"
    Write-Log "IGW:                    $igwId"
    Write-Log "Public subnets:         $publicSubnetA, $publicSubnetB"
    Write-Log "App subnets:            $appSubnetA, $appSubnetB"
    Write-Log "DB subnets:             $dbSubnetA, $dbSubnetB"
    Write-Log "Route table public:     $publicRt"
    Write-Log "Route table app:        $appRt"
    Write-Log "Route table db:         $dbRt"
    Write-Log "NAT gateway:            $natId"
    Write-Log "RDS security group:     $rdsSg"
    Write-Log "CodeBuild security grp: $codeBuildSg"
    Write-Log "App security group:     $appSg"
    Write-Log "ALB security group:     $albSg"
    Write-Log "RDS subnet group:       $dbSubnetGroup"
    Write-Log "RDS instance:           $DbInstanceIdentifier"
    Write-Log "RDS endpoint:           $dbHost"
    Write-Log "S3 bucket:              $BucketName"
    Write-Log "CodeBuild project:      $CodeBuildProjectName"
    Write-Log "Log file:               $logPath"

    Write-Log 'Next steps:' 'WARN'
    Write-Log "1. If you did not use -ConfigureGitHubSecrets, set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in GitHub and AWS_REGION=$AwsRegion as a variable."
    Write-Log "2. Run workflow 'rivo-graphhopper-build'."
    Write-Log "3. Run workflow 'rivo-osm-postgis-full-import'."
    Write-Log "4. Deploy the backend with GRAPHHOPPER_LOCAL=false and DB_HOST=$dbHost."
} catch {
    Write-Log ("Provisioning failed: {0}" -f $_.Exception.Message) 'ERROR'
    Invoke-Rollback
    Write-Log ("Provisioning aborted. Review log file: {0}" -f $logPath) 'ERROR'
    throw
}

try {
    Configure-GitHubSecretsIfRequested
} catch {
    Write-Log ("GitHub configuration failed after AWS provisioning succeeded: {0}" -f $_.Exception.Message) 'ERROR'
    Write-Log ("AWS resources were kept. Review log file: {0}" -f $logPath) 'WARN'
    throw
}

Write-Log 'Provisioning completed successfully.' 'SUCCESS'



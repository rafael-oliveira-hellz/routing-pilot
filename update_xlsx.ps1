$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
function New-Cell([string]$col, [int]$row, [string]$value) {
    if ([string]::IsNullOrEmpty($value)) { return '' }
    $escaped = [System.Security.SecurityElement]::Escape($value)
    return ('<c r="{0}{1}" t="inlineStr"><is><t>{2}</t></is></c>' -f $col, $row, $escaped)
}
function New-Row([int]$row, [string[]]$values) {
    $cols = @('A','B','C','D','E','F','G','H','I','J')
    $cells = for ($i = 0; $i -lt $values.Length; $i++) { New-Cell $cols[$i] $row $values[$i] }
    return ('<row r="{0}">{1}</row>' -f $row, ($cells -join ''))
}
function Update-Sheet([string]$path, [string]$dimension, [string[]]$rows) {
    $content = Get-Content $path -Raw
    $replacement = ('<dimension ref="{0}"/>' -f $dimension)
    $content = [regex]::Replace($content, '<dimension ref="[^"]+"/>', $replacement, 1)
    $insert = $rows -join ''
    $content = $content.Replace('</sheetData>', $insert + '</sheetData>')
    Set-Content $path $content -Encoding Ascii
}
$tmp = 'E:\014-routing\_xlsx_tmp'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null
$zipCopy = 'E:\014-routing\_model_tmp.zip'
Copy-Item 'E:\014-routing\DDD_Route_Architecture_Full_Model.xlsx' $zipCopy -Force
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipCopy, $tmp)
Remove-Item $zipCopy -Force
$sheet13Rows = @(
    (New-Row 43 @('Auth','AppUser','app_user','id','UUID','YES','','','PK','Identity aggregate root')),
    (New-Row 44 @('Auth','AppUser','app_user','email','VARCHAR(255)','','','','IDX_email (unique)','Unique login identifier')),
    (New-Row 45 @('Auth','AppUser','app_user','password_hash','VARCHAR(255)','','','','','BCrypt password hash')),
    (New-Row 46 @('Auth','AppUser','app_user','name','VARCHAR(255)','','','','','Display name')),
    (New-Row 47 @('Auth','AppUser','app_user','vehicle_id','VARCHAR(120)','','','','','JWT claim for tracking payload authorization')),
    (New-Row 48 @('Auth','AppUser','app_user','role','user_role_enum','','','','IDX_role','USER or ADMIN')),
    (New-Row 49 @('Auth','AppUser','app_user','remember_me_token','VARCHAR(512)','','','','IDX_remember_me','Hashed remember-me token')),
    (New-Row 50 @('Auth','AppUser','app_user','remember_me_expires_at','TIMESTAMP WITH TIME ZONE','','','','','Remember-me expiration')),
    (New-Row 51 @('Auth','AppUser','app_user','active','BOOLEAN','','','','','Soft delete / account disable flag')),
    (New-Row 52 @('Auth','AppUser','app_user','created_at','TIMESTAMP WITH TIME ZONE','','','','','Audit timestamp')),
    (New-Row 53 @('Auth','AppUser','app_user','updated_at','TIMESTAMP WITH TIME ZONE','','','','','Audit timestamp')),
    (New-Row 54 @('Auth','AppUser','refresh_token','id','UUID','YES','','','PK','Opaque refresh token record')),
    (New-Row 55 @('Auth','AppUser','refresh_token','user_id','UUID','','YES','app_user(id)','IDX_refresh_token_user','Session owner')),
    (New-Row 56 @('Auth','AppUser','refresh_token','token_hash','VARCHAR(255)','','','','','Hashed opaque refresh token')),
    (New-Row 57 @('Auth','AppUser','refresh_token','session_id','UUID','','','','IDX_refresh_token_session','Groups tokens by device/session')),
    (New-Row 58 @('Auth','AppUser','refresh_token','access_jti','VARCHAR(64)','','','','IDX_refresh_token_access_jti','Access token jti for immediate blocklist')),
    (New-Row 59 @('Auth','AppUser','refresh_token','access_expires_at','TIMESTAMP WITH TIME ZONE','','','','','TTL source for revoked access tokens')),
    (New-Row 60 @('Auth','AppUser','refresh_token','expires_at','TIMESTAMP WITH TIME ZONE','','','','IDX_refresh_token_expires','Refresh token expiration')),
    (New-Row 61 @('Auth','AppUser','refresh_token','revoked','BOOLEAN','','','','','Session revocation flag')),
    (New-Row 62 @('Auth','AppUser','refresh_token','created_at','TIMESTAMP WITH TIME ZONE','','','','','Audit timestamp')),
    (New-Row 63 @('Auth','AppUser','password_reset_token','id','UUID','YES','','','PK','One-time password reset token')),
    (New-Row 64 @('Auth','AppUser','password_reset_token','user_id','UUID','','YES','app_user(id)','IDX_password_reset_token_user','Token owner')),
    (New-Row 65 @('Auth','AppUser','password_reset_token','token_hash','VARCHAR(255)','','','','','Hashed reset token')),
    (New-Row 66 @('Auth','AppUser','password_reset_token','expires_at','TIMESTAMP WITH TIME ZONE','','','','IDX_password_reset_token_expires','Reset token expiration')),
    (New-Row 67 @('Auth','AppUser','password_reset_token','used_at','TIMESTAMP WITH TIME ZONE','','','','','Marks token consumption')),
    (New-Row 68 @('Auth','AppUser','password_reset_token','created_at','TIMESTAMP WITH TIME ZONE','','','','','Audit timestamp')),
    (New-Row 69 @('OptimizationEngine','RouteOptimization','route_segment','traffic_level','VARCHAR(20)','','','','','Derived from active incidents for map rendering'))
)
Update-Sheet (Join-Path $tmp 'xl\worksheets\sheet13.xml') 'A1:J69' $sheet13Rows
$sheet14Rows = @(
    (New-Row 11 @('Auth','AppUser','app_user','Users and roles','id (PK)','No','Stores login identity, role and remember-me state')),
    (New-Row 12 @('Auth','AppUser','refresh_token','Session store','id (PK), user_id (FK), session_id','No','Opaque refresh tokens with jti metadata for blocklist')),
    (New-Row 13 @('Auth','AppUser','password_reset_token','Password recovery','id (PK), user_id (FK)','No','One-time reset tokens with TTL and used_at'))
)
Update-Sheet (Join-Path $tmp 'xl\worksheets\sheet14.xml') 'A1:G13' $sheet14Rows
$sheet15Rows = @(
    (New-Row 13 @('refresh_token','user_id','app_user','id','N:1','fk_refresh_token_user','CASCADE','Refresh sessions belong to a user')),
    (New-Row 14 @('password_reset_token','user_id','app_user','id','N:1','fk_password_reset_token_user','CASCADE','Reset tokens belong to a user'))
)
Update-Sheet (Join-Path $tmp 'xl\worksheets\sheet15.xml') 'A1:H14' $sheet15Rows
$sheet17Rows = @(
    (New-Row 17 @('UserRole','USER, ADMIN','user_role_enum','app_user.role','Authorization role for public users and administrators'))
)
Update-Sheet (Join-Path $tmp 'xl\worksheets\sheet17.xml') 'A1:E17' $sheet17Rows
$sheet21Rows = @(
    (New-Row 17 @('user_role_enum','USER, ADMIN','app_user','V006 / V009'))
)
Update-Sheet (Join-Path $tmp 'xl\worksheets\sheet21.xml') 'A1:D17' $sheet21Rows
$outZip = 'E:\014-routing\_model_new.zip'
if (Test-Path $outZip) { Remove-Item $outZip -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $outZip)
Move-Item $outZip 'E:\014-routing\DDD_Route_Architecture_Full_Model.xlsx' -Force
Remove-Item $tmp -Recurse -Force

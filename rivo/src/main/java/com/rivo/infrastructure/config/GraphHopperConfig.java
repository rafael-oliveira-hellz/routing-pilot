package com.rivo.infrastructure.config;

import com.graphhopper.GraphHopper;
import com.graphhopper.config.CHProfile;
import com.graphhopper.config.Profile;
import jakarta.annotation.PreDestroy;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;

@Slf4j
@Configuration
public class GraphHopperConfig {

    @Value("${routing.graphhopper.local:true}")
    private boolean isLocal;

    @Value("${routing.graphhopper.osm-file:src/main/resources/osm/south-america-latest.osm.pbf}")
    private String osmFile;

    @Value("${routing.graphhopper.graph-location:data/graph-cache}")
    private String graphLocation;

    @Value("${routing.graphhopper.s3.bucket:routing-data}")
    private String s3Bucket;

    @Value("${routing.graphhopper.s3.prefix:graphhopper/brazil-latest}")
    private String s3Prefix;

    private GraphHopper hopper;

    @Bean
    public GraphHopper graphHopper(S3Client s3Client) {
        hopper = new GraphHopper();
        hopper.setProfiles(new Profile("car").setVehicle("car").setWeighting("fastest"));
        hopper.getCHPreparationHandler().setCHProfiles(new CHProfile("car"));
        hopper.setGraphHopperLocation(resolvePath(graphLocation).toString());

        if (isLocal) {
            initLocal();
        } else {
            initFromS3(s3Client);
        }

        return hopper;
    }

    private void initLocal() {
        Path pbfPath = resolveExistingPath(osmFile);
        Path graphPath = resolvePath(graphLocation);

        if (Files.exists(graphPath.resolve("properties"))) {
            log.info("[GraphHopper] LOCAL Loading pre-built graph from {}", graphPath);
            hopper.setAllowWrites(false);
            hopper.load(graphPath.toString());
            return;
        }

        log.info("[GraphHopper] LOCAL Building graph from {} (first run, may take several minutes)", pbfPath);
        hopper.setOSMFile(pbfPath.toString());
        hopper.importOrLoad();
        log.info("[GraphHopper] LOCAL Graph built and cached at {}", graphPath);
    }

    private void initFromS3(S3Client s3Client) {
        Path graphPath = resolvePath(graphLocation);

        if (Files.exists(graphPath.resolve("properties"))) {
            log.info("[GraphHopper] AWS Loading cached graph from {}", graphPath);
            hopper.setAllowWrites(false);
            hopper.load(graphPath.toString());
            return;
        }

        log.info("[GraphHopper] AWS Downloading pre-built graph from s3://{}/{}/", s3Bucket, s3Prefix);
        downloadGraphFromS3(s3Client, graphPath);
        log.info("[GraphHopper] AWS Download complete, loading graph");
        hopper.setAllowWrites(false);
        hopper.load(graphPath.toString());
    }

    private Path resolveExistingPath(String configuredPath) {
        List<Path> checkedPaths = candidatePaths(configuredPath);
        for (Path candidate : checkedPaths) {
            if (Files.exists(candidate)) {
                return candidate.normalize().toAbsolutePath();
            }
        }

        throw new IllegalStateException(
                "OSM file not found for configured path '" + configuredPath + "'. Checked: " + checkedPaths);
    }

    private Path resolvePath(String configuredPath) {
        Path configured = Paths.get(configuredPath);
        if (configured.isAbsolute()) {
            return configured.normalize();
        }
        return Paths.get(System.getProperty("user.dir")).resolve(configured).normalize().toAbsolutePath();
    }

    private List<Path> candidatePaths(String configuredPath) {
        Path configured = Paths.get(configuredPath);
        if (configured.isAbsolute()) {
            return List.of(configured.normalize().toAbsolutePath());
        }

        Path userDir = Paths.get(System.getProperty("user.dir")).normalize().toAbsolutePath();
        Set<Path> candidates = new LinkedHashSet<>();
        candidates.add(configured.normalize().toAbsolutePath());
        candidates.add(userDir.resolve(configured).normalize().toAbsolutePath());
        candidates.add(userDir.resolve("rivo").resolve(configured).normalize().toAbsolutePath());

        Path current = userDir;
        for (int i = 0; i < 4 && current != null; i++) {
            candidates.add(current.resolve(configured).normalize().toAbsolutePath());
            current = current.getParent();
        }

        return new ArrayList<>(candidates);
    }

    private void downloadGraphFromS3(S3Client s3, Path targetDir) {
        try {
            Files.createDirectories(targetDir);

            var listReq = ListObjectsV2Request.builder()
                    .bucket(s3Bucket)
                    .prefix(s3Prefix + "/")
                    .build();

            var listing = s3.listObjectsV2(listReq);

            for (var obj : listing.contents()) {
                String key = obj.key();
                String relativePath = key.substring(s3Prefix.length() + 1);
                if (relativePath.isEmpty()) {
                    continue;
                }

                Path localFile = targetDir.resolve(relativePath);
                Files.createDirectories(localFile.getParent());

                log.debug("[GraphHopper] Downloading s3://{}/{} -> {}", s3Bucket, key, localFile);
                s3.getObject(
                        GetObjectRequest.builder().bucket(s3Bucket).key(key).build(),
                        localFile);
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to download GraphHopper graph from S3", e);
        }
    }

    @PreDestroy
    public void shutdown() {
        if (hopper != null) {
            hopper.close();
            log.info("[GraphHopper] Shut down");
        }
    }
}
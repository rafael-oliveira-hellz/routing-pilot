package com.rivo.infrastructure.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.domain.enums.UserRole;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class JwtTokenService {

    private final AuthProperties authProperties;
    private final ObjectMapper objectMapper;
    private final PrivateKey privateKey;
    private final PublicKey publicKey;

    public JwtTokenService(AuthProperties authProperties, ObjectMapper objectMapper) {
        this.authProperties = authProperties;
        this.objectMapper = objectMapper;
        KeyPair keyPair = initializeKeyPair(authProperties);
        this.privateKey = keyPair.getPrivate();
        this.publicKey = keyPair.getPublic();
    }

    public AccessTokenIssue issueAccessToken(UserJpaEntity user, UUID sessionId) {
        try {
            Instant issuedAt = Instant.now();
            Instant expiresAt = issuedAt.plusSeconds(authProperties.getAccessTokenTtlSeconds());
            String jti = UUID.randomUUID().toString();

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("sub", user.getId().toString());
            payload.put("email", user.getEmail());
            if (user.getVehicleId() != null && !user.getVehicleId().isBlank()) {
                payload.put("vehicle_id", user.getVehicleId());
            }
            payload.put("role", user.getRole().name());
            payload.put("jti", jti);
            payload.put("sid", sessionId.toString());
            payload.put("iss", authProperties.getIssuer());
            payload.put("iat", issuedAt.getEpochSecond());
            payload.put("exp", expiresAt.getEpochSecond());

            String token = encode(payload);
            return new AccessTokenIssue(token, jti, expiresAt);
        } catch (GeneralSecurityException | JsonProcessingException e) {
            throw new UnauthorizedException("Failed to issue access token", e);
        }
    }

    public TokenClaims parseAndValidate(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new UnauthorizedException("Invalid bearer token format");
            }

            String signedContent = parts[0] + "." + parts[1];
            byte[] signatureBytes = Base64.getUrlDecoder().decode(parts[2]);
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initVerify(publicKey);
            signature.update(signedContent.getBytes(StandardCharsets.UTF_8));
            if (!signature.verify(signatureBytes)) {
                throw new UnauthorizedException("Bearer token signature is invalid");
            }

            byte[] payloadBytes = Base64.getUrlDecoder().decode(parts[1]);
            Map<String, Object> payload = objectMapper.readValue(payloadBytes, new TypeReference<>() {});

            long exp = numberClaim(payload, "exp");
            Instant expiresAt = Instant.ofEpochSecond(exp);
            if (expiresAt.isBefore(Instant.now())) {
                throw new UnauthorizedException("Bearer token expired");
            }

            String issuer = stringClaim(payload, "iss");
            if (authProperties.getIssuer() != null && !authProperties.getIssuer().isBlank()
                    && !authProperties.getIssuer().equals(issuer)) {
                throw new UnauthorizedException("Bearer token issuer is invalid");
            }

            return new TokenClaims(
                    UUID.fromString(stringClaim(payload, "sub")),
                    stringClaim(payload, "email"),
                    (String) payload.get("vehicle_id"),
                    UserRole.valueOf(stringClaim(payload, "role")),
                    stringClaim(payload, "jti"),
                    UUID.fromString(stringClaim(payload, "sid")),
                    expiresAt);
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw new UnauthorizedException("Bearer token could not be validated", e);
        }
    }

    private String encode(Map<String, Object> payload) throws GeneralSecurityException, JsonProcessingException {
        Map<String, Object> header = Map.of("alg", "RS256", "typ", "JWT");
        String encodedHeader = base64Url(objectMapper.writeValueAsBytes(header));
        String encodedPayload = base64Url(objectMapper.writeValueAsBytes(payload));
        String signedContent = encodedHeader + "." + encodedPayload;

        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(privateKey);
        signature.update(signedContent.getBytes(StandardCharsets.UTF_8));
        byte[] signed = signature.sign();
        return signedContent + "." + base64Url(signed);
    }

    private String stringClaim(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value == null) {
            throw new UnauthorizedException("Missing bearer token claim: " + key);
        }
        return String.valueOf(value);
    }

    private long numberClaim(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value instanceof Number number) {
            return number.longValue();
        }
        return Long.parseLong(String.valueOf(value));
    }

    private String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private KeyPair initializeKeyPair(AuthProperties authProperties) {
        try {
            String publicPem = normalizePem(authProperties.getJwtPublicKeyPem());
            String privatePem = normalizePem(authProperties.getJwtPrivateKeyPem());
            if (!publicPem.isBlank() && !privatePem.isBlank()) {
                KeyFactory keyFactory = KeyFactory.getInstance("RSA");
                byte[] publicBytes = Base64.getDecoder().decode(stripPem(publicPem));
                byte[] privateBytes = Base64.getDecoder().decode(stripPem(privatePem));
                PublicKey publicKey = keyFactory.generatePublic(new X509EncodedKeySpec(publicBytes));
                PrivateKey privateKey = keyFactory.generatePrivate(new PKCS8EncodedKeySpec(privateBytes));
                return new KeyPair(publicKey, privateKey);
            }

            if (!authProperties.isAllowEphemeralKeys()) {
                throw new IllegalStateException(
                        "JWT RSA keys are required. Configure routing.auth.jwt-public-key-pem and "
                                + "routing.auth.jwt-private-key-pem or explicitly enable "
                                + "routing.auth.allow-ephemeral-keys for local/dev use.");
            }

            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            log.warn("JWT RSA keys not configured. Generating ephemeral keys because allow-ephemeral-keys=true.");
            return generator.generateKeyPair();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize JWT RSA key pair", e);
        }
    }

    private String normalizePem(String pem) {
        if (pem == null) {
            return "";
        }
        return pem.replace("\\n", "\n").trim();
    }

    private String stripPem(String pem) {
        return pem
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s+", "");
    }

    public record AccessTokenIssue(String token, String jti, Instant expiresAt) {
    }

    public record TokenClaims(
            UUID userId,
            String email,
            String vehicleId,
            UserRole role,
            String jti,
            UUID sessionId,
            Instant expiresAt
    ) {
    }
}
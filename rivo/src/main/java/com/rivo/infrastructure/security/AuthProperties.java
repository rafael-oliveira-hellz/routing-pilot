package com.rivo.infrastructure.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "routing.auth")
public class AuthProperties {

    private long accessTokenTtlSeconds = 900;
    private long refreshTokenTtlSeconds = 2_592_000;
    private long rememberMeTtlSeconds = 2_592_000;
    private long passwordResetTtlSeconds = 3_600;
    private String issuer = "rivo";
    private String jwtPublicKeyPem;
    private String jwtPrivateKeyPem;
    private boolean allowEphemeralKeys;
    private BootstrapAdmin bootstrapAdmin = new BootstrapAdmin();

    public long getAccessTokenTtlSeconds() {
        return accessTokenTtlSeconds;
    }

    public void setAccessTokenTtlSeconds(long accessTokenTtlSeconds) {
        this.accessTokenTtlSeconds = accessTokenTtlSeconds;
    }

    public long getRefreshTokenTtlSeconds() {
        return refreshTokenTtlSeconds;
    }

    public void setRefreshTokenTtlSeconds(long refreshTokenTtlSeconds) {
        this.refreshTokenTtlSeconds = refreshTokenTtlSeconds;
    }

    public long getRememberMeTtlSeconds() {
        return rememberMeTtlSeconds;
    }

    public void setRememberMeTtlSeconds(long rememberMeTtlSeconds) {
        this.rememberMeTtlSeconds = rememberMeTtlSeconds;
    }

    public long getPasswordResetTtlSeconds() {
        return passwordResetTtlSeconds;
    }

    public void setPasswordResetTtlSeconds(long passwordResetTtlSeconds) {
        this.passwordResetTtlSeconds = passwordResetTtlSeconds;
    }

    public String getIssuer() {
        return issuer;
    }

    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }

    public String getJwtPublicKeyPem() {
        return jwtPublicKeyPem;
    }

    public void setJwtPublicKeyPem(String jwtPublicKeyPem) {
        this.jwtPublicKeyPem = jwtPublicKeyPem;
    }

    public String getJwtPrivateKeyPem() {
        return jwtPrivateKeyPem;
    }

    public void setJwtPrivateKeyPem(String jwtPrivateKeyPem) {
        this.jwtPrivateKeyPem = jwtPrivateKeyPem;
    }

    public boolean isAllowEphemeralKeys() {
        return allowEphemeralKeys;
    }

    public void setAllowEphemeralKeys(boolean allowEphemeralKeys) {
        this.allowEphemeralKeys = allowEphemeralKeys;
    }

    public BootstrapAdmin getBootstrapAdmin() {
        return bootstrapAdmin;
    }

    public void setBootstrapAdmin(BootstrapAdmin bootstrapAdmin) {
        this.bootstrapAdmin = bootstrapAdmin;
    }

    public static class BootstrapAdmin {
        private boolean enabled = true;
        private String email = "admin@rivo.local";
        private String name = "Owner Admin";
        private String password = "Admin123!";
        private String vehicleId;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        public String getVehicleId() {
            return vehicleId;
        }

        public void setVehicleId(String vehicleId) {
            this.vehicleId = vehicleId;
        }
    }
}
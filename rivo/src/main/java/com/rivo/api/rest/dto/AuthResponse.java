package com.rivo.api.rest.dto;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        int expiresIn,
        UserResponse user,
        String rememberMeToken
) {
}


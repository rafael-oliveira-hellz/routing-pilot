package com.rivo.api.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record RememberMeLoginRequest(@NotBlank String rememberMeToken) {
}


package com.rivo.api.rest.dto;

import com.rivo.domain.enums.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateUserRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 128) String password,
        @NotBlank @Size(max = 255) String name,
        @Size(max = 120) String vehicleId,
        UserRole role
) {
}


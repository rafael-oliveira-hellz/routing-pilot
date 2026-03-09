package com.rivo.api.rest.dto;

import com.rivo.domain.enums.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @Email String email,
        @Size(max = 255) String name,
        @Size(max = 120) String vehicleId,
        UserRole role,
        Boolean active
) {
}


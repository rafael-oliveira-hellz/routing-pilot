package com.rivo.functional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.api.rest.AuthController;
import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.api.rest.dto.LoginRequest;
import com.rivo.api.rest.dto.UserResponse;
import com.rivo.application.usecase.ChangePasswordUseCase;
import com.rivo.application.usecase.LoginUseCase;
import com.rivo.application.usecase.LogoutUseCase;
import com.rivo.application.usecase.RefreshTokenUseCase;
import com.rivo.application.usecase.RememberMeLoginUseCase;
import com.rivo.application.usecase.RequestPasswordResetUseCase;
import com.rivo.application.usecase.ResetPasswordUseCase;
import com.rivo.application.usecase.RevokeAllOtherSessionsUseCase;
import com.rivo.domain.enums.UserRole;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class AuthControllerContractTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;
    private LoginUseCase loginUseCase;

    @BeforeEach
    void setUp() {
        loginUseCase = Mockito.mock(LoginUseCase.class);
        AuthController controller = new AuthController(
                loginUseCase,
                Mockito.mock(RefreshTokenUseCase.class),
                Mockito.mock(RememberMeLoginUseCase.class),
                Mockito.mock(LogoutUseCase.class),
                Mockito.mock(RevokeAllOtherSessionsUseCase.class),
                Mockito.mock(RequestPasswordResetUseCase.class),
                Mockito.mock(ResetPasswordUseCase.class),
                Mockito.mock(ChangePasswordUseCase.class));
        objectMapper = new ObjectMapper();
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setMessageConverters(new MappingJackson2HttpMessageConverter(objectMapper))
                .build();
    }

    @Test
    void loginReturnsContractExpectedByClient() throws Exception {
        UserResponse user = new UserResponse(
                UUID.fromString("11111111-1111-1111-1111-111111111111"),
                "user@example.com",
                "Pilot User",
                "VEH-01",
                UserRole.USER,
                true,
                null,
                null);
        AuthResponse response = new AuthResponse("access-token", "refresh-token", 900, user, "remember-token");
        when(loginUseCase.login(any(LoginRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(new LoginRequest("user@example.com", "Admin123!", true))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("access-token"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-token"))
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andExpect(jsonPath("$.rememberMeToken").value("remember-token"))
                .andExpect(jsonPath("$.user.id").value("11111111-1111-1111-1111-111111111111"))
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andExpect(jsonPath("$.user.vehicleId").value("VEH-01"));
    }
}
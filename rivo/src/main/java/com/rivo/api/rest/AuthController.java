package com.rivo.api.rest;

import com.rivo.api.rest.dto.*;
import com.rivo.application.usecase.*;
import com.rivo.infrastructure.security.AuthenticatedUser;
import jakarta.validation.Valid;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final LoginUseCase loginUseCase;
    private final RefreshTokenUseCase refreshTokenUseCase;
    private final RememberMeLoginUseCase rememberMeLoginUseCase;
    private final LogoutUseCase logoutUseCase;
    private final RevokeAllOtherSessionsUseCase revokeAllOtherSessionsUseCase;
    private final RequestPasswordResetUseCase requestPasswordResetUseCase;
    private final ResetPasswordUseCase resetPasswordUseCase;
    private final ChangePasswordUseCase changePasswordUseCase;

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return loginUseCase.login(request);
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return refreshTokenUseCase.refresh(request.refreshToken());
    }

    @PostMapping("/remember-me")
    public AuthResponse rememberMe(@Valid @RequestBody RememberMeLoginRequest request) {
        return rememberMeLoginUseCase.login(request.rememberMeToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        logoutUseCase.logout(currentUser);
    }

    @PostMapping("/revoke-all-other-sessions")
    public AuthResponse revokeAllOtherSessions(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        return revokeAllOtherSessionsUseCase.revoke(currentUser);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        requestPasswordResetUseCase.request(request);
        return ResponseEntity.ok(Map.of("status", "RESET_REQUEST_ACCEPTED"));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        resetPasswordUseCase.reset(request.token(), request.newPassword());
        return ResponseEntity.ok(Map.of("status", "PASSWORD_RESET"));
    }

    @PostMapping("/change-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal AuthenticatedUser currentUser,
                               @Valid @RequestBody ChangePasswordRequest request) {
        changePasswordUseCase.change(currentUser, request.currentPassword(), request.newPassword());
    }
}




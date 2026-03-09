package com.rivo.api.rest;

import com.rivo.api.rest.dto.CreateUserRequest;
import com.rivo.api.rest.dto.UpdateUserRequest;
import com.rivo.api.rest.dto.UserResponse;
import com.rivo.application.usecase.CreateUserUseCase;
import com.rivo.application.usecase.DeleteUserUseCase;
import com.rivo.application.usecase.GetUserUseCase;
import com.rivo.application.usecase.UpdateUserUseCase;
import com.rivo.infrastructure.security.AuthenticatedUser;
import com.rivo.infrastructure.security.SecurityUtils;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final CreateUserUseCase createUserUseCase;
    private final GetUserUseCase getUserUseCase;
    private final UpdateUserUseCase updateUserUseCase;
    private final DeleteUserUseCase deleteUserUseCase;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        Optional<AuthenticatedUser> actor = SecurityUtils.currentUser();
        return createUserUseCase.create(request, actor);
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        return getUserUseCase.getById(currentUser.userId());
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<UserResponse> listAll() {
        return getUserUseCase.listAll();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id.toString() == authentication.name")
    public UserResponse getById(@PathVariable UUID id) {
        return getUserUseCase.getById(id);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id.toString() == authentication.name")
    public UserResponse update(@PathVariable UUID id,
                               @AuthenticationPrincipal AuthenticatedUser currentUser,
                               @Valid @RequestBody UpdateUserRequest request) {
        return updateUserUseCase.update(id, request, currentUser);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser currentUser) {
        deleteUserUseCase.delete(id, currentUser);
    }
}


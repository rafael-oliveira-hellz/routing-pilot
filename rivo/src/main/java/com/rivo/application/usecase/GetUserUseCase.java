package com.rivo.application.usecase;

import com.rivo.api.rest.dto.UserResponse;
import com.rivo.domain.exception.ResourceNotFoundException;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GetUserUseCase {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserResponse getById(UUID userId) {
        return userRepository.findById(userId)
                .map(UserResponse::fromEntity)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
    }

    @Transactional(readOnly = true)
    public List<UserResponse> listAll() {
        return userRepository.findAllByOrderByCreatedAtAsc().stream()
                .map(UserResponse::fromEntity)
                .toList();
    }
}


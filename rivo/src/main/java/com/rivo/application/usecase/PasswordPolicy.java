package com.rivo.application.usecase;

import com.rivo.domain.exception.DomainException;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class PasswordPolicy {

    public void validate(String password) {
        List<String> violations = new ArrayList<>();
        if (password == null || password.length() < 8) {
            violations.add("Password must contain at least 8 characters");
        }
        if (password == null || password.length() > 128) {
            violations.add("Password must contain at most 128 characters");
        }
        if (password == null || password.chars().noneMatch(Character::isUpperCase)) {
            violations.add("Password must contain an uppercase letter");
        }
        if (password == null || password.chars().noneMatch(Character::isLowerCase)) {
            violations.add("Password must contain a lowercase letter");
        }
        if (password == null || password.chars().noneMatch(Character::isDigit)) {
            violations.add("Password must contain a digit");
        }
        if (password == null || password.chars().allMatch(Character::isLetterOrDigit)) {
            violations.add("Password must contain a special character");
        }
        if (!violations.isEmpty()) {
            throw new DomainException("Password does not meet security policy", violations);
        }
    }
}


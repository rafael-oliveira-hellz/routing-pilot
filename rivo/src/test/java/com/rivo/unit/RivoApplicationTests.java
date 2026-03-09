package com.rivo.unit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.rivo.application.usecase.PasswordPolicy;
import com.rivo.domain.exception.DomainException;
import org.junit.jupiter.api.Test;

class RivoApplicationTests {

    private final PasswordPolicy passwordPolicy = new PasswordPolicy();

    @Test
    void acceptsStrongPassword() {
        assertDoesNotThrow(() -> passwordPolicy.validate("Admin123!"));
    }

    @Test
    void rejectsWeakPassword() {
        assertThrows(DomainException.class, () -> passwordPolicy.validate("weak"));
    }
}

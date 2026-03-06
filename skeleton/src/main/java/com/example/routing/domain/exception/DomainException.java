package com.example.routing.domain.exception;

import java.util.Collections;
import java.util.List;

public class DomainException extends RuntimeException {

    private final List<String> violations;

    public DomainException(String message) {
        super(message);
        this.violations = Collections.emptyList();
    }

    public DomainException(String message, Throwable cause) {
        super(message, cause);
        this.violations = Collections.emptyList();
    }

    public DomainException(String message, List<String> violations) {
        super(message);
        this.violations = violations != null ? violations : Collections.emptyList();
    }

    public List<String> getViolations() { return violations; }

    public boolean hasMultipleViolations() { return violations.size() > 1; }
}

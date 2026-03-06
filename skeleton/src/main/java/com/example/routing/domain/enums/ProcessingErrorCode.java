package com.example.routing.domain.enums;

public enum ProcessingErrorCode {
    DESERIALIZATION_FAILED,
    VALIDATION_FAILED,
    STATE_LOAD_FAILED,
    STATE_SAVE_FAILED,
    POLICY_EXCEPTION,
    PUBLISH_FAILED,
    TIMEOUT,
    UNKNOWN
}

package com.rivo.functional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.rivo.api.rest.GlobalExceptionHandler;
import com.rivo.api.rest.TraceIdFilter;
import com.rivo.domain.exception.DomainException;
import com.rivo.domain.exception.RateLimitExceededException;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

class GlobalExceptionHandlerContractTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new ThrowingController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .addFilters(new TraceIdFilter())
                .build();
    }

    @Test
    void rateLimitResponseContainsRetryAfterAndTraceId() throws Exception {
        mockMvc.perform(get("/rate-limit").header("X-Trace-Id", "trace-123"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "45"))
                .andExpect(header().string("X-Trace-Id", "trace-123"))
                .andExpect(jsonPath("$.errorCode").value("RATE_LIMIT_EXCEEDED"))
                .andExpect(jsonPath("$.traceId").value("trace-123"))
                .andExpect(jsonPath("$.path").value("/rate-limit"));
    }

    @Test
    void domainValidationResponseContainsFieldErrors() throws Exception {
        mockMvc.perform(get("/domain").header("X-Trace-Id", "trace-domain"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errorCode").value("DOMAIN_VALIDATION"))
                .andExpect(jsonPath("$.traceId").value("trace-domain"))
                .andExpect(jsonPath("$.errors[0].message").value("email already exists"));
    }

    @RestController
    static class ThrowingController {

        @GetMapping("/rate-limit")
        String rateLimit() {
            throw new RateLimitExceededException("Too many requests", 45);
        }

        @GetMapping("/domain")
        String domain() {
            throw new DomainException("Validation failed", List.of("email already exists"));
        }
    }
}
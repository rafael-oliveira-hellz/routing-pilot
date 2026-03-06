package com.example.routing.domain.exception;

public class CacheException extends RoutingException {

    public CacheException(String message) {
        super("CACHE_ERROR", message);
    }

    public CacheException(String message, Throwable cause) {
        super("CACHE_ERROR", message, cause);
    }
}

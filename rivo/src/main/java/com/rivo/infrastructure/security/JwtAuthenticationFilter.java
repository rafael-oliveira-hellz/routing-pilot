package com.rivo.infrastructure.security;

import com.rivo.domain.exception.UnauthorizedException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenService jwtTokenService;
    private final TokenBlocklistService tokenBlocklistService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization != null && authorization.startsWith("Bearer ")) {
            String token = authorization.substring(7);
            try {
                JwtTokenService.TokenClaims claims = jwtTokenService.parseAndValidate(token);
                if (tokenBlocklistService.isRevoked(claims.jti())) {
                    throw new UnauthorizedException("Bearer token was revoked");
                }

                AuthenticatedUser principal = new AuthenticatedUser(
                        claims.userId(),
                        claims.email(),
                        claims.vehicleId(),
                        claims.role(),
                        claims.jti(),
                        claims.sessionId(),
                        claims.expiresAt());

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        principal,
                        token,
                        List.of(new SimpleGrantedAuthority("ROLE_" + claims.role().name())));
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (UnauthorizedException ex) {
                SecurityContextHolder.clearContext();
                request.setAttribute("auth.error", ex.getMessage());
            }
        }

        filterChain.doFilter(request, response);
    }
}


package com.rifky.empay.auth.dto;

public record TokenResponse(
        String accessToken,
        String refreshToken
) {}

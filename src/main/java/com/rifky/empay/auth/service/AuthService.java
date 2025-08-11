package com.rifky.empay.auth.service;

import com.rifky.empay.auth.dto.LoginRequest;
import com.rifky.empay.auth.dto.TokenResponse;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    public TokenResponse login(LoginRequest req) {
        // TODO: authenticate user, generate JWT
        return new TokenResponse("ACCESS.TOKEN.HERE", "REFRESH.TOKEN.HERE");
    }
}

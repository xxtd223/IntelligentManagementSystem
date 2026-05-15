package org.example.attendance.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.LoginRequest;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.service.AuthService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ApiResponse<?> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ApiResponse<?> me(@AuthenticationPrincipal Long employeeId) {
        return ApiResponse.ok(authService.getCurrentEmployee(employeeId));
    }
}

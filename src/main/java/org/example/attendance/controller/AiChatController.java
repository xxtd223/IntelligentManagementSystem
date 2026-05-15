package org.example.attendance.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.AiChatRequest;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.service.ai.QwenChatService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/ai")
@RequiredArgsConstructor
public class AiChatController {

    private final QwenChatService qwenChatService;

    @PostMapping("/chat")
    public ApiResponse<?> chat(@AuthenticationPrincipal Long employeeId,
                               @Valid @RequestBody AiChatRequest request) {
        String sessionKey = request.getSessionKey() != null
                ? request.getSessionKey()
                : "emp-" + employeeId + "-" + UUID.randomUUID().toString().substring(0, 8);

        Map<String, Object> result = qwenChatService.chat(
                employeeId,
                sessionKey,
                request.getMessage(),
                request.getLatitude(),
                request.getLongitude()
        );

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("sessionKey", sessionKey);
        data.put("reply", result.get("reply"));
        data.put("actionTaken", result.get("actionTaken"));

        return ApiResponse.ok(data);
    }

    @DeleteMapping("/chat/session")
    public ApiResponse<?> clearSession(@AuthenticationPrincipal Long employeeId) {
        qwenChatService.clearSession(employeeId);
        return ApiResponse.ok();
    }
}

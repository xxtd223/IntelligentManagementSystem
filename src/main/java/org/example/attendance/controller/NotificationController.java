package org.example.attendance.controller;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.service.NotificationService;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ApiResponse<?> list(@AuthenticationPrincipal Long employeeId,
                               @RequestParam(defaultValue = "0") int page,
                               @RequestParam(defaultValue = "20") int size) {
        var notifications = notificationService.getNotifications(employeeId,
                PageRequest.of(page, size, Sort.by("createdAt").descending()));
        return ApiResponse.ok(notifications.map(notificationService::getNotificationDto));
    }

    @GetMapping("/unread-count")
    public ApiResponse<?> unreadCount(@AuthenticationPrincipal Long employeeId) {
        return ApiResponse.ok(Map.of("count", notificationService.getUnreadCount(employeeId)));
    }

    @PatchMapping("/{id}/read")
    public ApiResponse<?> markRead(@PathVariable Long id,
                                   @AuthenticationPrincipal Long employeeId) {
        notificationService.markRead(id, employeeId);
        return ApiResponse.ok();
    }

    @PatchMapping("/read-all")
    public ApiResponse<?> markAllRead(@AuthenticationPrincipal Long employeeId) {
        notificationService.markAllRead(employeeId);
        return ApiResponse.ok();
    }
}

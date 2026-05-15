package org.example.attendance.controller;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.service.WorkCalendarService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/work-calendar")
@RequiredArgsConstructor
public class WorkCalendarController {

    private final WorkCalendarService workCalendarService;

    @GetMapping
    public ApiResponse<?> get(@AuthenticationPrincipal Long currentUserId,
                               @RequestParam(required = false) Long employeeId,
                               @RequestParam int year,
                               @RequestParam int month) {
        Long targetId = employeeId != null ? employeeId : currentUserId;
        return ApiResponse.ok(workCalendarService.getCalendar(targetId, year, month));
    }

    @PostMapping("/batch")
    public ApiResponse<?> batchUpdate(@AuthenticationPrincipal Long adminId,
                                      @RequestBody Map<String, Object> body) {
        Long employeeId = Long.parseLong(body.get("employeeId").toString());
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> entries = (List<Map<String, Object>>) body.get("entries");
        workCalendarService.batchUpdate(adminId, employeeId, entries);
        return ApiResponse.ok();
    }
}

package org.example.attendance.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.CheckInRequest;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.entity.AttendanceRecord;
import org.example.attendance.service.AttendanceService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/attendance")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/check-in")
    public ApiResponse<?> checkIn(@AuthenticationPrincipal Long employeeId,
                                  @Valid @RequestBody CheckInRequest request) {
        return ApiResponse.ok(attendanceService.checkIn(employeeId, request, AttendanceRecord.Source.APP));
    }

    @GetMapping("/today")
    public ApiResponse<?> today(@AuthenticationPrincipal Long employeeId) {
        return ApiResponse.ok(attendanceService.getTodayRecords(employeeId));
    }

    @GetMapping("/records")
    public ApiResponse<?> records(@AuthenticationPrincipal Long currentUserId,
                                  @RequestParam(required = false) Long employeeId,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        Long targetId = employeeId != null ? employeeId : currentUserId;
        return ApiResponse.ok(attendanceService.getRecords(targetId, startDate, endDate));
    }

    @GetMapping("/calendar")
    public ApiResponse<?> calendar(@AuthenticationPrincipal Long currentUserId,
                                   @RequestParam(required = false) Long employeeId,
                                   @RequestParam int year,
                                   @RequestParam int month) {
        Long targetId = employeeId != null ? employeeId : currentUserId;
        return ApiResponse.ok(attendanceService.getMonthlyCalendar(targetId, year, month));
    }

    @GetMapping("/summary")
    public ApiResponse<?> summary(@AuthenticationPrincipal Long currentUserId,
                                  @RequestParam(required = false) Long employeeId,
                                  @RequestParam int year,
                                  @RequestParam int month) {
        Long targetId = employeeId != null ? employeeId : currentUserId;
        return ApiResponse.ok(attendanceService.getMonthlySummary(targetId, year, month));
    }

    @GetMapping("/admin/daily-summary")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<?> dailySummary(@RequestParam(required = false)
                                       @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate targetDate = date != null ? date : LocalDate.now();
        return ApiResponse.ok(attendanceService.getRecords(null, targetDate, targetDate));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<?> manualEdit(@PathVariable Long id,
                                     @RequestBody java.util.Map<String, Object> body) {
        attendanceService.manualEdit(id, body);
        return ApiResponse.ok();
    }

    @PostMapping("/admin/manual")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<?> manualCreate(@RequestBody java.util.Map<String, Object> body) {
        return ApiResponse.ok(attendanceService.manualCreate(body));
    }
}

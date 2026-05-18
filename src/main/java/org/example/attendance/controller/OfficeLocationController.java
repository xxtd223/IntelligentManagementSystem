package org.example.attendance.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.dto.response.OfficeLocationDto;
import org.example.attendance.entity.AttendanceRule;
import org.example.attendance.entity.OfficeLocation;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.AttendanceRuleRepository;
import org.example.attendance.repository.OfficeLocationRepository;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/office-locations")
@RequiredArgsConstructor
public class OfficeLocationController {

    private final OfficeLocationRepository locationRepository;
    private final AttendanceRuleRepository ruleRepository;

    @GetMapping
    public ApiResponse<?> list() {
        List<OfficeLocation> locations = locationRepository.findAll();
        List<OfficeLocationDto> dtos = locations.stream().map(loc -> {
            AttendanceRule rule = ruleRepository
                    .findFirstByOfficeLocationIdAndIsActiveTrue(loc.getId()).orElse(null);
            return OfficeLocationDto.from(loc, rule);
        }).toList();
        return ApiResponse.ok(dtos);
    }

    @GetMapping("/{id}")
    public ApiResponse<?> get(@PathVariable Long id) {
        OfficeLocation loc = locationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
        AttendanceRule rule = ruleRepository
                .findFirstByOfficeLocationIdAndIsActiveTrue(id).orElse(null);
        return ApiResponse.ok(OfficeLocationDto.from(loc, rule));
    }

    @PostMapping
    public ApiResponse<?> create(@Valid @RequestBody LocationRequest request) {
        OfficeLocation loc = OfficeLocation.builder()
                .name(request.getName())
                .address(request.getAddress())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .allowedRadius(request.getAllowedRadius() != null ? request.getAllowedRadius() : 200)
                .isActive(true)
                .build();
        loc = locationRepository.save(loc);

        if (request.getWorkStartTime() != null && request.getWorkEndTime() != null) {
            AttendanceRule rule = AttendanceRule.builder()
                    .officeLocation(loc)
                    .name(loc.getName() + "标准班制")
                    .workStartTime(LocalTime.parse(request.getWorkStartTime()))
                    .workEndTime(LocalTime.parse(request.getWorkEndTime()))
                    .lateThresholdMinutes(request.getLateThresholdMinutes() != null
                            ? request.getLateThresholdMinutes() : 5)
                    .earlyLeaveThresholdMinutes(request.getEarlyLeaveThresholdMinutes() != null
                            ? request.getEarlyLeaveThresholdMinutes() : 5)
                    .checkInEarliest(LocalTime.of(7, 0))
                    .checkOutLatest(LocalTime.of(22, 0))
                    .isActive(true)
                    .build();
            ruleRepository.save(rule);
        }

        AttendanceRule savedRule = ruleRepository
                .findFirstByOfficeLocationIdAndIsActiveTrue(loc.getId()).orElse(null);
        return ApiResponse.ok(OfficeLocationDto.from(loc, savedRule));
    }

    @PutMapping("/{id}")
    public ApiResponse<?> update(@PathVariable Long id, @Valid @RequestBody LocationRequest request) {
        OfficeLocation loc = locationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
        loc.setName(request.getName());
        loc.setAddress(request.getAddress());
        loc.setLatitude(request.getLatitude());
        loc.setLongitude(request.getLongitude());
        if (request.getAllowedRadius() != null) {
            loc.setAllowedRadius(request.getAllowedRadius());
        }
        final OfficeLocation savedLoc = locationRepository.save(loc);

        if (request.getWorkStartTime() != null && request.getWorkEndTime() != null) {
            AttendanceRule rule = ruleRepository
                    .findFirstByOfficeLocationIdAndIsActiveTrue(id)
                    .orElseGet(() -> AttendanceRule.builder()
                            .officeLocation(savedLoc)
                            .name(savedLoc.getName() + "标准班制")
                            .checkInEarliest(LocalTime.of(7, 0))
                            .checkOutLatest(LocalTime.of(22, 0))
                            .isActive(true)
                            .build());
            rule.setWorkStartTime(LocalTime.parse(request.getWorkStartTime()));
            rule.setWorkEndTime(LocalTime.parse(request.getWorkEndTime()));
            if (request.getLateThresholdMinutes() != null)
                rule.setLateThresholdMinutes(request.getLateThresholdMinutes());
            if (request.getEarlyLeaveThresholdMinutes() != null)
                rule.setEarlyLeaveThresholdMinutes(request.getEarlyLeaveThresholdMinutes());
            ruleRepository.save(rule);
        }

        AttendanceRule savedRule = ruleRepository
                .findFirstByOfficeLocationIdAndIsActiveTrue(savedLoc.getId()).orElse(null);
        return ApiResponse.ok(OfficeLocationDto.from(savedLoc, savedRule));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<?> delete(@PathVariable Long id) {
        OfficeLocation loc = locationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
        loc.setIsActive(false);
        locationRepository.save(loc);
        return ApiResponse.ok();
    }

    @Data
    static class LocationRequest {
        @NotBlank private String name;
        @NotBlank private String address;
        @NotNull private BigDecimal latitude;
        @NotNull private BigDecimal longitude;
        private Integer allowedRadius;
        private String workStartTime;
        private String workEndTime;
        private Integer lateThresholdMinutes;
        private Integer earlyLeaveThresholdMinutes;
    }
}

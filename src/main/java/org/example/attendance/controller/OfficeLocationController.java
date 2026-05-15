package org.example.attendance.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.entity.OfficeLocation;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.OfficeLocationRepository;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/office-locations")
@RequiredArgsConstructor
public class OfficeLocationController {

    private final OfficeLocationRepository locationRepository;

    @GetMapping
    public ApiResponse<?> list() {
        return ApiResponse.ok(locationRepository.findAll());
    }

    @GetMapping("/{id}")
    public ApiResponse<?> get(@PathVariable Long id) {
        return ApiResponse.ok(locationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在")));
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
        return ApiResponse.ok(locationRepository.save(loc));
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
        return ApiResponse.ok(locationRepository.save(loc));
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
    }
}

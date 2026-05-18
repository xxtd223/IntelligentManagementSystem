package org.example.attendance.dto.response;

import lombok.Builder;
import lombok.Data;
import org.example.attendance.entity.AttendanceRule;
import org.example.attendance.entity.OfficeLocation;

import java.math.BigDecimal;

@Data
@Builder
public class OfficeLocationDto {
    private Long id;
    private String name;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer allowedRadius;
    private Boolean isActive;
    private String workStartTime;
    private String workEndTime;
    private Integer lateThresholdMinutes;
    private Integer earlyLeaveThresholdMinutes;

    public static OfficeLocationDto from(OfficeLocation loc, AttendanceRule rule) {
        return OfficeLocationDto.builder()
                .id(loc.getId())
                .name(loc.getName())
                .address(loc.getAddress())
                .latitude(loc.getLatitude())
                .longitude(loc.getLongitude())
                .allowedRadius(loc.getAllowedRadius())
                .isActive(loc.getIsActive())
                .workStartTime(rule != null ? rule.getWorkStartTime().toString() : null)
                .workEndTime(rule != null ? rule.getWorkEndTime().toString() : null)
                .lateThresholdMinutes(rule != null ? rule.getLateThresholdMinutes() : null)
                .earlyLeaveThresholdMinutes(rule != null ? rule.getEarlyLeaveThresholdMinutes() : null)
                .build();
    }
}

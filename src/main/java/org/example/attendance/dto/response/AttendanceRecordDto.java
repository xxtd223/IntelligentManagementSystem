package org.example.attendance.dto.response;

import lombok.Builder;
import lombok.Data;
import org.example.attendance.entity.AttendanceRecord;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data @Builder
public class AttendanceRecordDto {
    private Long id;
    private Long employeeId;
    private String employeeName;
    private LocalDate checkDate;
    private LocalDateTime checkTime;
    private String checkType;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String officeLocationName;
    private Integer distanceMeters;
    private String status;
    private Boolean isValid;
    private String source;
    private String note;

    public static AttendanceRecordDto from(AttendanceRecord r) {
        return AttendanceRecordDto.builder()
                .id(r.getId())
                .employeeId(r.getEmployee().getId())
                .employeeName(r.getEmployee().getName())
                .checkDate(r.getCheckDate())
                .checkTime(r.getCheckTime())
                .checkType(r.getCheckType().name())
                .latitude(r.getLatitude())
                .longitude(r.getLongitude())
                .officeLocationName(r.getOfficeLocation() != null ? r.getOfficeLocation().getName() : null)
                .distanceMeters(r.getDistanceMeters())
                .status(r.getStatus().name())
                .isValid(r.getIsValid())
                .source(r.getSource().name())
                .note(r.getNote())
                .build();
    }
}

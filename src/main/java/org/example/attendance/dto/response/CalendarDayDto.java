package org.example.attendance.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data @Builder
public class CalendarDayDto {
    private LocalDate date;
    private boolean isWorkDay;
    private boolean hasCheckIn;
    private boolean hasCheckOut;
    private boolean isMissing;
    private boolean isLate;
    private boolean isEarlyLeave;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInStatus;
    private String checkOutStatus;
    private String note;
    // 当天自定义工作时间
    private LocalTime customStartTime;
    private LocalTime customEndTime;
    // 当天自定义工作地点
    private Long customOfficeLocationId;
    private String customOfficeLocationName;
}

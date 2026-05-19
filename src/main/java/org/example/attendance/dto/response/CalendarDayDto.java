package org.example.attendance.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data @Builder
public class CalendarDayDto {
    private LocalDate date;
    @JsonProperty("isWorkDay")
    private boolean isWorkDay;
    private boolean hasCheckIn;
    private boolean hasCheckOut;
    @JsonProperty("isMissing")
    private boolean isMissing;
    @JsonProperty("isLate")
    private boolean isLate;
    @JsonProperty("isEarlyLeave")
    private boolean isEarlyLeave;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInStatus;
    private String checkOutStatus;
    private String checkInSource;
    private String checkOutSource;
    private String note;
    // 当天自定义工作时间
    private LocalTime customStartTime;
    private LocalTime customEndTime;
    // 当天自定义工作地点
    private Long customOfficeLocationId;
    private String customOfficeLocationName;
}

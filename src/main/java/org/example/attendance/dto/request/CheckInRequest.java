package org.example.attendance.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.example.attendance.entity.AttendanceRecord;

import java.math.BigDecimal;

@Data
public class CheckInRequest {
    @NotNull(message = "打卡类型不能为空")
    private AttendanceRecord.CheckType checkType;

    private BigDecimal latitude;
    private BigDecimal longitude;
}

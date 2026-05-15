package org.example.attendance.service.ai;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.attendance.dto.request.CheckInRequest;
import org.example.attendance.entity.AttendanceRecord;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.service.AttendanceService;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;

@Component
@Slf4j
@RequiredArgsConstructor
public class AttendanceToolExecutor {

    private final AttendanceService attendanceService;
    private final ObjectMapper objectMapper;

    public record ToolResult(String content, String actionTaken) {}

    public ToolResult execute(Long employeeId, String toolName, String argsJson,
                               BigDecimal latitude, BigDecimal longitude) {
        try {
            Map<String, Object> args = objectMapper.readValue(argsJson, new TypeReference<>() {});
            return switch (toolName) {
                case "do_check_in" -> doCheckIn(employeeId, args, latitude, longitude);
                case "query_today_attendance" -> queryToday(employeeId);
                case "query_monthly_attendance" -> queryMonthly(employeeId, args);
                case "query_attendance_range" -> queryRange(employeeId, args);
                default -> new ToolResult("未知工具：" + toolName, null);
            };
        } catch (BusinessException e) {
            log.warn("Tool {} business error: {}", toolName, e.getMessage());
            return new ToolResult(e.getMessage(), null);
        } catch (Exception e) {
            log.error("Tool {} execution error", toolName, e);
            return new ToolResult("操作执行失败：" + e.getMessage(), null);
        }
    }

    private ToolResult doCheckIn(Long employeeId, Map<String, Object> args,
                                  BigDecimal lat, BigDecimal lng) {
        String typeStr = (String) args.get("check_type");
        AttendanceRecord.CheckType checkType = AttendanceRecord.CheckType.valueOf(typeStr);

        CheckInRequest request = new CheckInRequest();
        request.setCheckType(checkType);
        request.setLatitude(lat);
        request.setLongitude(lng);

        var record = attendanceService.checkIn(employeeId, request, AttendanceRecord.Source.AI_CHAT);

        String typeLabel = checkType == AttendanceRecord.CheckType.CHECK_IN ? "上班" : "下班";
        String statusLabel = switch (record.getStatus()) {
            case "LATE" -> "（迟到）";
            case "EARLY_LEAVE" -> "（早退）";
            default -> "";
        };

        String content = String.format("打卡成功！%s打卡%s，时间：%s",
                typeLabel, statusLabel,
                record.getCheckTime().toLocalTime().toString().substring(0, 5));
        return new ToolResult(content, checkType.name());
    }

    private ToolResult queryToday(Long employeeId) {
        var records = attendanceService.getTodayRecords(employeeId);
        if (records.isEmpty()) {
            return new ToolResult("今日暂无打卡记录", null);
        }
        StringBuilder sb = new StringBuilder("今日打卡记录：\n");
        for (var r : records) {
            String type = "CHECK_IN".equals(r.getCheckType()) ? "上班" : "下班";
            sb.append(String.format("- %s打卡：%s（%s）\n",
                    type,
                    r.getCheckTime().toLocalTime().toString().substring(0, 5),
                    r.getStatus()));
        }
        return new ToolResult(sb.toString().trim(), null);
    }

    private ToolResult queryMonthly(Long employeeId, Map<String, Object> args) {
        int year = ((Number) args.get("year")).intValue();
        int month = ((Number) args.get("month")).intValue();
        var summary = attendanceService.getMonthlySummary(employeeId, year, month);
        String content = String.format(
                "%d年%d月考勤统计：正常出勤%s天，迟到%s次，早退%s次，缺卡%s次",
                year, month,
                summary.get("normalCount"),
                summary.get("lateCount"),
                summary.get("earlyLeaveCount"),
                summary.get("missingCount")
        );
        return new ToolResult(content, null);
    }

    private ToolResult queryRange(Long employeeId, Map<String, Object> args) {
        LocalDate startDate = LocalDate.parse((String) args.get("start_date"));
        LocalDate endDate = LocalDate.parse((String) args.get("end_date"));
        var records = attendanceService.getRecords(employeeId, startDate, endDate);
        if (records.isEmpty()) {
            return new ToolResult(String.format("%s 至 %s 无打卡记录", startDate, endDate), null);
        }
        return new ToolResult(String.format("%s 至 %s 共 %d 条打卡记录",
                startDate, endDate, records.size()), null);
    }
}

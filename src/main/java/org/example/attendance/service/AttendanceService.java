package org.example.attendance.service;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.CheckInRequest;
import org.example.attendance.dto.response.AttendanceRecordDto;
import org.example.attendance.dto.response.CalendarDayDto;
import org.example.attendance.entity.*;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.*;
import org.example.attendance.util.GeoUtil;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttendanceService {

    private final AttendanceRecordRepository recordRepository;
    private final WorkCalendarRepository workCalendarRepository;
    private final AttendanceRuleRepository ruleRepository;
    private final EmployeeRepository employeeRepository;
    private final NotificationService notificationService;

    @Transactional
    public AttendanceRecordDto checkIn(Long employeeId, CheckInRequest request,
                                       AttendanceRecord.Source source) {
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new BusinessException(ErrorCode.EMPLOYEE_NOT_FOUND));

        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        // 检查工作日历，同时获取当天自定义地点
        Optional<WorkCalendar> calendarOpt = workCalendarRepository.findByEmployeeIdAndWorkDate(employeeId, today);
        if (calendarOpt.isPresent() && !calendarOpt.get().getIsWorkDay()) {
            throw new BusinessException(ErrorCode.NOT_WORK_DAY);
        }

        // 优先使用当天日历中自定义的工作地点，否则使用员工默认地点
        OfficeLocation location = calendarOpt
                .map(WorkCalendar::getCustomOfficeLocation)
                .filter(l -> l != null)
                .orElse(employee.getOfficeLocation());
        if (location == null) {
            throw new BusinessException(ErrorCode.NO_OFFICE_LOCATION);
        }

        // 校验地理位置
        int distance = 0;
        AttendanceRecord.RecordStatus status = AttendanceRecord.RecordStatus.NORMAL;

        if (request.getLatitude() != null && request.getLongitude() != null) {
            distance = GeoUtil.haversineDistance(
                    request.getLatitude(), request.getLongitude(),
                    location.getLatitude(), location.getLongitude()
            );
            if (distance > location.getAllowedRadius()) {
                AttendanceRecord invalidRecord = buildRecord(employee, today, now, request,
                        location, distance, AttendanceRecord.RecordStatus.OUTSIDE_RANGE, false, source);
                recordRepository.save(invalidRecord);
                notificationService.sendCheckInFail(employee, "当前位置不在允许打卡范围内，距办公室 " + distance + " 米");
                throw new BusinessException(ErrorCode.OUTSIDE_RANGE,
                        "当前位置不在允许打卡范围内，距办公室 " + distance + " 米");
            }
        }

        // 获取考勤规则
        AttendanceRule rule = ruleRepository
                .findFirstByOfficeLocationIdAndIsActiveTrue(location.getId())
                .orElse(null);

        LocalTime startTime = null;
        LocalTime endTime = null;
        if (calendarOpt.isPresent()) {
            startTime = calendarOpt.get().getCustomStartTime();
            endTime = calendarOpt.get().getCustomEndTime();
        }
        if (rule != null) {
            if (startTime == null) startTime = rule.getWorkStartTime();
            if (endTime == null) endTime = rule.getWorkEndTime();
        }

        // 重复打卡检查
        Optional<AttendanceRecord> existing = recordRepository.findByEmployeeIdAndCheckDateAndCheckType(
                employeeId, today, request.getCheckType());
        if (existing.isPresent() && existing.get().getIsValid()) {
            if (request.getCheckType() == AttendanceRecord.CheckType.CHECK_IN) {
                throw new BusinessException(ErrorCode.ALREADY_CHECKED_IN);
            } else {
                throw new BusinessException(ErrorCode.ALREADY_CHECKED_OUT);
            }
        }

        // 下班打卡需要先上班打卡
        if (request.getCheckType() == AttendanceRecord.CheckType.CHECK_OUT) {
            boolean hasCheckIn = recordRepository.findByEmployeeIdAndCheckDateAndCheckType(
                    employeeId, today, AttendanceRecord.CheckType.CHECK_IN)
                    .map(AttendanceRecord::getIsValid).orElse(false);
            if (!hasCheckIn) {
                throw new BusinessException(ErrorCode.CHECK_IN_REQUIRED);
            }
        }

        // 判断状态（迟到/早退）
        if (rule != null && startTime != null && endTime != null) {
            LocalTime nowTime = now.toLocalTime();
            int lateTolerance = rule.getLateThresholdMinutes();
            int earlyTolerance = rule.getEarlyLeaveThresholdMinutes();

            if (request.getCheckType() == AttendanceRecord.CheckType.CHECK_IN) {
                LocalTime lateDeadline = startTime.plusMinutes(lateTolerance);
                if (nowTime.isAfter(lateDeadline)) {
                    status = AttendanceRecord.RecordStatus.LATE;
                }
            } else {
                LocalTime earlyDeadline = endTime.minusMinutes(earlyTolerance);
                if (nowTime.isBefore(earlyDeadline)) {
                    status = AttendanceRecord.RecordStatus.EARLY_LEAVE;
                }
            }
        }

        AttendanceRecord record = buildRecord(employee, today, now, request,
                location, distance, status, true, source);
        recordRepository.save(record);

        notificationService.sendCheckInSuccess(employee, request.getCheckType(), status, now);
        return AttendanceRecordDto.from(record);
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordDto> getTodayRecords(Long employeeId) {
        return recordRepository.findByEmployeeIdAndCheckDate(employeeId, LocalDate.now())
                .stream().map(AttendanceRecordDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordDto> getRecords(Long employeeId, LocalDate startDate, LocalDate endDate) {
        if (employeeId != null) {
            return recordRepository.findByEmployeeIdAndCheckDateBetweenOrderByCheckDateAscCheckTimeAsc(
                    employeeId, startDate, endDate).stream().map(AttendanceRecordDto::from).toList();
        }
        return recordRepository.findByCheckDateBetween(startDate, endDate)
                .stream().map(AttendanceRecordDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<CalendarDayDto> getMonthlyCalendar(Long employeeId, int year, int month) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();

        List<AttendanceRecord> records = recordRepository
                .findByEmployeeIdAndCheckDateBetweenOrderByCheckDateAscCheckTimeAsc(
                        employeeId, startDate, endDate);

        List<WorkCalendar> calendars = workCalendarRepository
                .findByEmployeeIdAndWorkDateBetween(employeeId, startDate, endDate);

        Map<LocalDate, List<AttendanceRecord>> recordsByDate = records.stream()
                .collect(Collectors.groupingBy(AttendanceRecord::getCheckDate));
        Map<LocalDate, WorkCalendar> calendarByDate = calendars.stream()
                .collect(Collectors.toMap(WorkCalendar::getWorkDate, c -> c));

        List<CalendarDayDto> result = new ArrayList<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            // 默认周一到周五为工作日，周六日为非工作日；可被 WorkCalendar 覆盖
            boolean isWorkDay = date.getDayOfWeek().getValue() <= 5;
            String note = null;
            WorkCalendar wc = calendarByDate.get(date);
            if (wc != null) {
                isWorkDay = wc.getIsWorkDay();
                note = wc.getNote();
            }

            List<AttendanceRecord> dayRecords = recordsByDate.getOrDefault(date, List.of());
            AttendanceRecord checkIn = dayRecords.stream()
                    .filter(r -> r.getCheckType() == AttendanceRecord.CheckType.CHECK_IN && r.getIsValid())
                    .findFirst().orElse(null);
            AttendanceRecord checkOut = dayRecords.stream()
                    .filter(r -> r.getCheckType() == AttendanceRecord.CheckType.CHECK_OUT && r.getIsValid())
                    .findFirst().orElse(null);

            boolean isMissing = isWorkDay && !date.isAfter(LocalDate.now().minusDays(1))
                    && (checkIn == null || checkOut == null);

            result.add(CalendarDayDto.builder()
                    .date(date)
                    .isWorkDay(isWorkDay)
                    .hasCheckIn(checkIn != null)
                    .hasCheckOut(checkOut != null)
                    .isMissing(isMissing)
                    .isLate(checkIn != null && checkIn.getStatus() == AttendanceRecord.RecordStatus.LATE)
                    .isEarlyLeave(checkOut != null && checkOut.getStatus() == AttendanceRecord.RecordStatus.EARLY_LEAVE)
                    .checkInTime(checkIn != null ? checkIn.getCheckTime() : null)
                    .checkOutTime(checkOut != null ? checkOut.getCheckTime() : null)
                    .checkInStatus(checkIn != null ? checkIn.getStatus().name() : null)
                    .checkOutStatus(checkOut != null ? checkOut.getStatus().name() : null)
                    .checkInSource(checkIn != null ? checkIn.getSource().name() : null)
                    .checkOutSource(checkOut != null ? checkOut.getSource().name() : null)
                    .note(note)
                    .customStartTime(wc != null ? wc.getCustomStartTime() : null)
                    .customEndTime(wc != null ? wc.getCustomEndTime() : null)
                    .customOfficeLocationId(wc != null && wc.getCustomOfficeLocation() != null
                            ? wc.getCustomOfficeLocation().getId() : null)
                    .customOfficeLocationName(wc != null && wc.getCustomOfficeLocation() != null
                            ? wc.getCustomOfficeLocation().getName() : null)
                    .build());
        }
        return result;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getMonthlySummary(Long employeeId, int year, int month) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();

        long lateCount = recordRepository.countByEmployeeAndDateRangeAndStatus(
                employeeId, startDate, endDate, AttendanceRecord.RecordStatus.LATE);
        long earlyLeaveCount = recordRepository.countByEmployeeAndDateRangeAndStatus(
                employeeId, startDate, endDate, AttendanceRecord.RecordStatus.EARLY_LEAVE);

        List<CalendarDayDto> calendar = getMonthlyCalendar(employeeId, year, month);
        long missingCount = calendar.stream().filter(CalendarDayDto::isMissing).count();
        long normalCount = calendar.stream()
                .filter(d -> d.isWorkDay() && d.isHasCheckIn() && d.isHasCheckOut()
                        && !d.isLate() && !d.isEarlyLeave()).count();

        return Map.of(
                "year", year, "month", month,
                "normalCount", normalCount,
                "lateCount", lateCount,
                "earlyLeaveCount", earlyLeaveCount,
                "missingCount", missingCount
        );
    }

    @Transactional
    public void manualEdit(Long recordId, Map<String, Object> body) {
        AttendanceRecord record = recordRepository.findById(recordId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "考勤记录不存在"));
        if (body.containsKey("checkTime")) {
            LocalDateTime newTime = LocalDateTime.parse((String) body.get("checkTime"));
            record.setCheckTime(newTime);
            record.setCheckDate(newTime.toLocalDate());
        }
        if (body.containsKey("status")) {
            record.setStatus(AttendanceRecord.RecordStatus.valueOf((String) body.get("status")));
        }
        if (body.containsKey("isValid")) {
            record.setIsValid((Boolean) body.get("isValid"));
        }
        if (body.containsKey("note")) {
            record.setNote((String) body.get("note"));
        }
        recordRepository.save(record);
    }

    @Transactional
    public AttendanceRecordDto manualCreate(Map<String, Object> body) {
        Long employeeId = Long.parseLong(body.get("employeeId").toString());
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new BusinessException(ErrorCode.EMPLOYEE_NOT_FOUND));
        LocalDateTime checkTime = LocalDateTime.parse((String) body.get("checkTime"));
        AttendanceRecord.CheckType checkType = AttendanceRecord.CheckType.valueOf(
                (String) body.get("checkType"));
        String statusStr = (String) body.getOrDefault("status", "NORMAL");
        String note = (String) body.getOrDefault("note", "管理员手动录入");

        AttendanceRecord record = AttendanceRecord.builder()
                .employee(employee)
                .checkDate(checkTime.toLocalDate())
                .checkTime(checkTime)
                .checkType(checkType)
                .status(AttendanceRecord.RecordStatus.valueOf(statusStr))
                .isValid(true)
                .source(AttendanceRecord.Source.MANUAL)
                .note(note)
                .build();
        return AttendanceRecordDto.from(recordRepository.save(record));
    }

    private AttendanceRecord buildRecord(Employee employee, LocalDate date, LocalDateTime time,
                                          CheckInRequest request, OfficeLocation location,
                                          int distance, AttendanceRecord.RecordStatus status,
                                          boolean isValid, AttendanceRecord.Source source) {
        return AttendanceRecord.builder()
                .employee(employee)
                .checkDate(date)
                .checkTime(time)
                .checkType(request.getCheckType())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .officeLocation(location)
                .distanceMeters(distance)
                .status(status)
                .isValid(isValid)
                .source(source)
                .build();
    }
}

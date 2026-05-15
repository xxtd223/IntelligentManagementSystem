package org.example.attendance.service;

import lombok.RequiredArgsConstructor;
import org.example.attendance.entity.Employee;
import org.example.attendance.entity.OfficeLocation;
import org.example.attendance.entity.WorkCalendar;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.EmployeeRepository;
import org.example.attendance.repository.OfficeLocationRepository;
import org.example.attendance.repository.WorkCalendarRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class WorkCalendarService {

    private final WorkCalendarRepository workCalendarRepository;
    private final EmployeeRepository employeeRepository;
    private final OfficeLocationRepository officeLocationRepository;

    @Transactional(readOnly = true)
    public List<WorkCalendar> getCalendar(Long employeeId, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());
        return workCalendarRepository.findByEmployeeIdAndWorkDateBetween(employeeId, start, end);
    }

    @Transactional
    public void batchUpdate(Long adminId, Long employeeId, List<Map<String, Object>> entries) {
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new BusinessException(ErrorCode.EMPLOYEE_NOT_FOUND));

        for (Map<String, Object> entry : entries) {
            LocalDate date = LocalDate.parse((String) entry.get("date"));
            boolean isWorkDay = (Boolean) entry.getOrDefault("isWorkDay", true);
            String note = (String) entry.get("note");
            String startStr = (String) entry.get("customStartTime");
            String endStr = (String) entry.get("customEndTime");

            WorkCalendar wc = workCalendarRepository.findByEmployeeIdAndWorkDate(employeeId, date)
                    .orElse(WorkCalendar.builder().employee(employee).workDate(date).build());

            wc.setIsWorkDay(isWorkDay);
            wc.setNote(note);
            wc.setCustomStartTime(startStr != null && !startStr.isBlank() ? LocalTime.parse(startStr) : null);
            wc.setCustomEndTime(endStr != null && !endStr.isBlank() ? LocalTime.parse(endStr) : null);
            wc.setCreatedBy(adminId);

            Object locationIdObj = entry.get("customOfficeLocationId");
            if (locationIdObj != null) {
                Long locationId = Long.parseLong(locationIdObj.toString());
                OfficeLocation loc = officeLocationRepository.findById(locationId)
                        .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
                wc.setCustomOfficeLocation(loc);
            } else {
                wc.setCustomOfficeLocation(null);
            }

            workCalendarRepository.save(wc);
        }
    }
}

package org.example.attendance.repository;

import org.example.attendance.entity.WorkCalendar;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WorkCalendarRepository extends JpaRepository<WorkCalendar, Long> {

    Optional<WorkCalendar> findByEmployeeIdAndWorkDate(Long employeeId, LocalDate workDate);

    List<WorkCalendar> findByEmployeeIdAndWorkDateBetween(Long employeeId,
                                                           LocalDate startDate,
                                                           LocalDate endDate);
}

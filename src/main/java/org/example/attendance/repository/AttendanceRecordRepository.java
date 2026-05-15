package org.example.attendance.repository;

import org.example.attendance.entity.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Long> {

    List<AttendanceRecord> findByEmployeeIdAndCheckDate(Long employeeId, LocalDate checkDate);

    Optional<AttendanceRecord> findByEmployeeIdAndCheckDateAndCheckType(
            Long employeeId, LocalDate checkDate, AttendanceRecord.CheckType checkType);

    List<AttendanceRecord> findByEmployeeIdAndCheckDateBetweenOrderByCheckDateAscCheckTimeAsc(
            Long employeeId, LocalDate startDate, LocalDate endDate);

    @Query("SELECT ar FROM AttendanceRecord ar WHERE ar.checkDate BETWEEN :startDate AND :endDate " +
           "ORDER BY ar.checkDate ASC, ar.checkTime ASC")
    List<AttendanceRecord> findByCheckDateBetween(@Param("startDate") LocalDate startDate,
                                                   @Param("endDate") LocalDate endDate);

    @Query("SELECT COUNT(ar) FROM AttendanceRecord ar WHERE ar.employee.id = :empId " +
           "AND ar.checkDate BETWEEN :startDate AND :endDate AND ar.status = :status")
    long countByEmployeeAndDateRangeAndStatus(@Param("empId") Long employeeId,
                                               @Param("startDate") LocalDate startDate,
                                               @Param("endDate") LocalDate endDate,
                                               @Param("status") AttendanceRecord.RecordStatus status);
}

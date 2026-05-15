package org.example.attendance.repository;

import org.example.attendance.entity.AttendanceRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AttendanceRuleRepository extends JpaRepository<AttendanceRule, Long> {
    List<AttendanceRule> findByOfficeLocationIdAndIsActiveTrue(Long officeLocationId);
    Optional<AttendanceRule> findFirstByOfficeLocationIdAndIsActiveTrue(Long officeLocationId);
}

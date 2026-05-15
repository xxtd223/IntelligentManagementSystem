package org.example.attendance.repository;

import org.example.attendance.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Page<Notification> findByEmployeeIdOrderByCreatedAtDesc(Long employeeId, Pageable pageable);

    long countByEmployeeIdAndIsReadFalse(Long employeeId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true WHERE n.employee.id = :empId")
    void markAllReadByEmployee(@Param("empId") Long employeeId);
}

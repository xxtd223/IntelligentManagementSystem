package org.example.attendance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "attendance_rule")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AttendanceRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "office_location_id", nullable = false)
    private OfficeLocation officeLocation;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "work_start_time", nullable = false)
    private LocalTime workStartTime;

    @Column(name = "work_end_time", nullable = false)
    private LocalTime workEndTime;

    @Column(name = "late_threshold_minutes", nullable = false)
    private Integer lateThresholdMinutes = 0;

    @Column(name = "early_leave_threshold_minutes", nullable = false)
    private Integer earlyLeaveThresholdMinutes = 0;

    @Column(name = "check_in_earliest")
    private LocalTime checkInEarliest;

    @Column(name = "check_out_latest")
    private LocalTime checkOutLatest;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

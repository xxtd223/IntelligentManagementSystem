package org.example.attendance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance_record")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AttendanceRecord {

    public enum CheckType { CHECK_IN, CHECK_OUT }
    public enum RecordStatus { NORMAL, LATE, EARLY_LEAVE, INVALID, OUTSIDE_RANGE }
    public enum Source { APP, AI_CHAT, MANUAL }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @Column(name = "check_date", nullable = false)
    private LocalDate checkDate;

    @Column(name = "check_time", nullable = false)
    private LocalDateTime checkTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "check_type", nullable = false)
    private CheckType checkType;

    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "office_location_id")
    private OfficeLocation officeLocation;

    @Column(name = "distance_meters")
    private Integer distanceMeters;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RecordStatus status = RecordStatus.NORMAL;

    @Column(name = "is_valid", nullable = false)
    private Boolean isValid = true;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Source source = Source.APP;

    @Column(length = 500)
    private String note;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}

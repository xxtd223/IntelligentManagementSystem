package org.example.attendance.service;

import lombok.RequiredArgsConstructor;
import org.example.attendance.entity.AttendanceRecord;
import org.example.attendance.entity.Employee;
import org.example.attendance.entity.Notification;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.NotificationRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

    public void sendCheckInSuccess(Employee employee, AttendanceRecord.CheckType type,
                                   AttendanceRecord.RecordStatus status, LocalDateTime time) {
        String typeLabel = type == AttendanceRecord.CheckType.CHECK_IN ? "上班" : "下班";
        String statusLabel = switch (status) {
            case LATE -> "（迟到）";
            case EARLY_LEAVE -> "（早退）";
            default -> "";
        };
        save(employee,
                typeLabel + "打卡成功" + statusLabel,
                "打卡时间：" + time.format(TIME_FMT),
                Notification.NotificationType.CHECK_IN_SUCCESS);
    }

    public void sendCheckInFail(Employee employee, String reason) {
        save(employee, "打卡失败", reason, Notification.NotificationType.CHECK_IN_FAIL);
    }

    public Page<Notification> getNotifications(Long employeeId, Pageable pageable) {
        return notificationRepository.findByEmployeeIdOrderByCreatedAtDesc(employeeId, pageable);
    }

    public long getUnreadCount(Long employeeId) {
        return notificationRepository.countByEmployeeIdAndIsReadFalse(employeeId);
    }

    @Transactional
    public void markRead(Long notificationId, Long employeeId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "通知不存在"));
        if (!notification.getEmployee().getId().equals(employeeId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllRead(Long employeeId) {
        notificationRepository.markAllReadByEmployee(employeeId);
    }

    private void save(Employee employee, String title, String content,
                      Notification.NotificationType type) {
        notificationRepository.save(Notification.builder()
                .employee(employee)
                .title(title)
                .content(content)
                .type(type)
                .isRead(false)
                .build());
    }

    public Map<String, Object> getNotificationDto(Notification n) {
        return Map.of(
                "id", n.getId(),
                "title", n.getTitle(),
                "content", n.getContent() != null ? n.getContent() : "",
                "type", n.getType().name(),
                "isRead", n.getIsRead(),
                "createdAt", n.getCreatedAt()
        );
    }
}

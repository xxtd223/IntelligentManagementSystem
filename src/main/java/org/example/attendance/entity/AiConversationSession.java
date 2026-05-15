package org.example.attendance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_conversation_session")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AiConversationSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @Column(name = "session_key", nullable = false, unique = true, length = 64)
    private String sessionKey;

    @Column(name = "messages_json", columnDefinition = "MEDIUMTEXT")
    private String messagesJson;

    @Column(name = "last_active_at")
    private LocalDateTime lastActiveAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}

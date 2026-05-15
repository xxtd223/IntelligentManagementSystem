package org.example.attendance.repository;

import org.example.attendance.entity.AiConversationSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AiConversationSessionRepository extends JpaRepository<AiConversationSession, Long> {
    Optional<AiConversationSession> findBySessionKey(String sessionKey);
    Optional<AiConversationSession> findByEmployeeId(Long employeeId);
}

package org.example.attendance.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class AiChatRequest {
    @NotBlank(message = "消息不能为空")
    private String message;

    private String sessionKey;
    private BigDecimal latitude;
    private BigDecimal longitude;
}

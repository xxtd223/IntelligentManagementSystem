package org.example.attendance.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "员工编号不能为空")
    private String employeeNo;

    @NotBlank(message = "密码不能为空")
    private String password;
}

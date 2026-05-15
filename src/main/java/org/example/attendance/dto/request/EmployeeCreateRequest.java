package org.example.attendance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.example.attendance.entity.Employee;

@Data
public class EmployeeCreateRequest {
    @NotBlank(message = "员工编号不能为空")
    private String employeeNo;

    @NotBlank(message = "姓名不能为空")
    private String name;

    private String phone;
    private String email;

    @NotBlank(message = "初始密码不能为空")
    private String password;

    @NotNull(message = "角色不能为空")
    private Employee.Role role;

    private Long departmentId;
    private Long officeLocationId;
}

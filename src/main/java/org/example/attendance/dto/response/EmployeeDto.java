package org.example.attendance.dto.response;

import lombok.Builder;
import lombok.Data;
import org.example.attendance.entity.Employee;

import java.time.LocalDateTime;

@Data @Builder
public class EmployeeDto {
    private Long id;
    private String employeeNo;
    private String name;
    private String phone;
    private String email;
    private String role;
    private String status;
    private String departmentName;
    private Long departmentId;
    private String officeLocationName;
    private Long officeLocationId;
    private String avatarUrl;
    private LocalDateTime createdAt;

    public static EmployeeDto from(Employee e) {
        return EmployeeDto.builder()
                .id(e.getId())
                .employeeNo(e.getEmployeeNo())
                .name(e.getName())
                .phone(e.getPhone())
                .email(e.getEmail())
                .role(e.getRole().name())
                .status(e.getStatus().name())
                .departmentId(e.getDepartment() != null ? e.getDepartment().getId() : null)
                .departmentName(e.getDepartment() != null ? e.getDepartment().getName() : null)
                .officeLocationId(e.getOfficeLocation() != null ? e.getOfficeLocation().getId() : null)
                .officeLocationName(e.getOfficeLocation() != null ? e.getOfficeLocation().getName() : null)
                .avatarUrl(e.getAvatarUrl())
                .createdAt(e.getCreatedAt())
                .build();
    }
}

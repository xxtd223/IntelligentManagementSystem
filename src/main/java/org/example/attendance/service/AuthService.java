package org.example.attendance.service;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.LoginRequest;
import org.example.attendance.dto.response.EmployeeDto;
import org.example.attendance.entity.Employee;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.EmployeeRepository;
import org.example.attendance.util.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final EmployeeRepository employeeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Transactional(readOnly = true)
    public Map<String, Object> login(LoginRequest request) {
        Employee employee = employeeRepository.findByEmployeeNo(request.getEmployeeNo())
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_CREDENTIALS));

        if (!passwordEncoder.matches(request.getPassword(), employee.getPasswordHash())) {
            throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
        }

        if (employee.getStatus() == Employee.Status.INACTIVE) {
            throw new BusinessException(ErrorCode.ACCOUNT_DISABLED);
        }

        String token = jwtUtil.generateToken(employee.getId(), employee.getEmployeeNo(),
                employee.getRole().name());

        return Map.of(
                "token", token,
                "employee", EmployeeDto.from(employee)
        );
    }

    @Transactional(readOnly = true)
    public EmployeeDto getCurrentEmployee(Long employeeId) {
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new BusinessException(ErrorCode.EMPLOYEE_NOT_FOUND));
        return EmployeeDto.from(employee);
    }
}

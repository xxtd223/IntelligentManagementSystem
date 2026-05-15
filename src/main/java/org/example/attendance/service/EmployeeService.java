package org.example.attendance.service;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.EmployeeCreateRequest;
import org.example.attendance.dto.response.EmployeeDto;
import org.example.attendance.entity.Department;
import org.example.attendance.entity.Employee;
import org.example.attendance.entity.OfficeLocation;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.DepartmentRepository;
import org.example.attendance.repository.EmployeeRepository;
import org.example.attendance.repository.OfficeLocationRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final OfficeLocationRepository officeLocationRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public Page<EmployeeDto> listEmployees(Long deptId, Employee.Status status,
                                           String keyword, Pageable pageable) {
        return employeeRepository.searchEmployees(deptId, status, keyword, pageable)
                .map(EmployeeDto::from);
    }

    @Transactional(readOnly = true)
    public EmployeeDto getEmployee(Long id) {
        return EmployeeDto.from(findById(id));
    }

    @Transactional
    public EmployeeDto createEmployee(EmployeeCreateRequest req) {
        if (employeeRepository.existsByEmployeeNo(req.getEmployeeNo())) {
            throw new BusinessException(ErrorCode.EMPLOYEE_NO_EXISTS);
        }
        if (req.getEmail() != null && employeeRepository.existsByEmail(req.getEmail())) {
            throw new BusinessException(ErrorCode.EMAIL_EXISTS);
        }

        Employee employee = Employee.builder()
                .employeeNo(req.getEmployeeNo())
                .name(req.getName())
                .phone(req.getPhone())
                .email(req.getEmail())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .role(req.getRole())
                .status(Employee.Status.ACTIVE)
                .build();

        if (req.getDepartmentId() != null) {
            Department dept = departmentRepository.findById(req.getDepartmentId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "部门不存在"));
            employee.setDepartment(dept);
        }
        if (req.getOfficeLocationId() != null) {
            OfficeLocation loc = officeLocationRepository.findById(req.getOfficeLocationId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
            employee.setOfficeLocation(loc);
        }

        return EmployeeDto.from(employeeRepository.save(employee));
    }

    @Transactional
    public EmployeeDto updateEmployee(Long id, EmployeeCreateRequest req) {
        Employee employee = findById(id);

        if (!employee.getEmployeeNo().equals(req.getEmployeeNo())
                && employeeRepository.existsByEmployeeNo(req.getEmployeeNo())) {
            throw new BusinessException(ErrorCode.EMPLOYEE_NO_EXISTS);
        }

        employee.setEmployeeNo(req.getEmployeeNo());
        employee.setName(req.getName());
        employee.setPhone(req.getPhone());
        employee.setEmail(req.getEmail());
        employee.setRole(req.getRole());

        if (req.getPassword() != null && !req.getPassword().isBlank()) {
            employee.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        }
        if (req.getDepartmentId() != null) {
            Department dept = departmentRepository.findById(req.getDepartmentId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "部门不存在"));
            employee.setDepartment(dept);
        }
        if (req.getOfficeLocationId() != null) {
            OfficeLocation loc = officeLocationRepository.findById(req.getOfficeLocationId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
            employee.setOfficeLocation(loc);
        }

        return EmployeeDto.from(employeeRepository.save(employee));
    }

    @Transactional
    public void updateStatus(Long id, Employee.Status status) {
        Employee employee = findById(id);
        employee.setStatus(status);
        employeeRepository.save(employee);
    }

    @Transactional
    public void assignOfficeLocation(Long id, Long locationId) {
        Employee employee = findById(id);
        OfficeLocation loc = officeLocationRepository.findById(locationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "办公地点不存在"));
        employee.setOfficeLocation(loc);
        employeeRepository.save(employee);
    }

    @Transactional(readOnly = true)
    public Employee findById(Long id) {
        return employeeRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.EMPLOYEE_NOT_FOUND));
    }
}

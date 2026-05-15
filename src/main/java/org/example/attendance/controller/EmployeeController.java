package org.example.attendance.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.request.EmployeeCreateRequest;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.entity.Employee;
import org.example.attendance.service.EmployeeService;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    @GetMapping
    public ApiResponse<?> list(@RequestParam(required = false) Long deptId,
                               @RequestParam(required = false) String status,
                               @RequestParam(required = false) String keyword,
                               @RequestParam(defaultValue = "0") int page,
                               @RequestParam(defaultValue = "20") int size) {
        Employee.Status statusEnum = status != null ? Employee.Status.valueOf(status) : null;
        return ApiResponse.ok(employeeService.listEmployees(deptId, statusEnum, keyword,
                PageRequest.of(page, size, Sort.by("createdAt").descending())));
    }

    @GetMapping("/{id}")
    public ApiResponse<?> get(@PathVariable Long id) {
        return ApiResponse.ok(employeeService.getEmployee(id));
    }

    @PostMapping
    public ApiResponse<?> create(@Valid @RequestBody EmployeeCreateRequest request) {
        return ApiResponse.ok(employeeService.createEmployee(request));
    }

    @PutMapping("/{id}")
    public ApiResponse<?> update(@PathVariable Long id,
                                 @Valid @RequestBody EmployeeCreateRequest request) {
        return ApiResponse.ok(employeeService.updateEmployee(id, request));
    }

    @PatchMapping("/{id}/status")
    public ApiResponse<?> updateStatus(@PathVariable Long id,
                                       @RequestBody Map<String, String> body) {
        employeeService.updateStatus(id, Employee.Status.valueOf(body.get("status")));
        return ApiResponse.ok();
    }

    @PutMapping("/{id}/office-location")
    public ApiResponse<?> assignLocation(@PathVariable Long id,
                                          @RequestBody Map<String, Long> body) {
        employeeService.assignOfficeLocation(id, body.get("officeLocationId"));
        return ApiResponse.ok();
    }
}

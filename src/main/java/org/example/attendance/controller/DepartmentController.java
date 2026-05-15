package org.example.attendance.controller;

import lombok.RequiredArgsConstructor;
import org.example.attendance.dto.response.ApiResponse;
import org.example.attendance.entity.Department;
import org.example.attendance.exception.BusinessException;
import org.example.attendance.exception.ErrorCode;
import org.example.attendance.repository.DepartmentRepository;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/departments")
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentRepository departmentRepository;

    @GetMapping
    public ApiResponse<?> list() {
        return ApiResponse.ok(departmentRepository.findAll());
    }

    @PostMapping
    public ApiResponse<?> create(@RequestBody Map<String, String> body) {
        String name = body.get("name");
        if (departmentRepository.existsByName(name)) {
            throw new BusinessException(ErrorCode.CONFLICT, "部门名称已存在");
        }
        Department dept = Department.builder()
                .name(name)
                .description(body.get("description"))
                .build();
        return ApiResponse.ok(departmentRepository.save(dept));
    }

    @PutMapping("/{id}")
    public ApiResponse<?> update(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Department dept = departmentRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "部门不存在"));
        dept.setName(body.get("name"));
        dept.setDescription(body.get("description"));
        return ApiResponse.ok(departmentRepository.save(dept));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<?> delete(@PathVariable Long id) {
        departmentRepository.deleteById(id);
        return ApiResponse.ok();
    }
}

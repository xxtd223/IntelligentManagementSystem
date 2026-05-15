package org.example.attendance.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.attendance.entity.Department;
import org.example.attendance.entity.Employee;
import org.example.attendance.entity.OfficeLocation;
import org.example.attendance.repository.DepartmentRepository;
import org.example.attendance.repository.EmployeeRepository;
import org.example.attendance.repository.OfficeLocationRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final OfficeLocationRepository officeLocationRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (employeeRepository.count() > 0) {
            return;
        }

        Department hrDept = departmentRepository.findAll().stream()
                .filter(d -> d.getName().equals("人力资源部"))
                .findFirst().orElse(null);
        Department techDept = departmentRepository.findAll().stream()
                .filter(d -> d.getName().equals("技术部"))
                .findFirst().orElse(null);
        OfficeLocation shanghai = officeLocationRepository.findAll().stream()
                .filter(l -> l.getName().equals("上海总部"))
                .findFirst().orElse(null);
        OfficeLocation beijing = officeLocationRepository.findAll().stream()
                .filter(l -> l.getName().equals("北京分部"))
                .findFirst().orElse(null);

        Employee admin = Employee.builder()
                .employeeNo("ADMIN001")
                .name("系统管理员")
                .phone("13800000001")
                .email("admin@company.com")
                .passwordHash(passwordEncoder.encode("Admin@123"))
                .role(Employee.Role.ADMIN)
                .status(Employee.Status.ACTIVE)
                .department(hrDept)
                .officeLocation(shanghai)
                .build();
        employeeRepository.save(admin);

        Employee zhangsan = Employee.builder()
                .employeeNo("EMP20240001")
                .name("张三")
                .phone("13800000002")
                .email("zhangsan@company.com")
                .passwordHash(passwordEncoder.encode("Test@123"))
                .role(Employee.Role.EMPLOYEE)
                .status(Employee.Status.ACTIVE)
                .department(techDept)
                .officeLocation(shanghai)
                .build();
        employeeRepository.save(zhangsan);

        Employee lisi = Employee.builder()
                .employeeNo("EMP20240002")
                .name("李四")
                .phone("13800000003")
                .email("lisi@company.com")
                .passwordHash(passwordEncoder.encode("Test@123"))
                .role(Employee.Role.EMPLOYEE)
                .status(Employee.Status.ACTIVE)
                .department(techDept)
                .officeLocation(beijing)
                .build();
        employeeRepository.save(lisi);

        log.info("初始数据创建完成：管理员 ADMIN001/Admin@123，员工 EMP20240001/Test@123，EMP20240002/Test@123");
    }
}

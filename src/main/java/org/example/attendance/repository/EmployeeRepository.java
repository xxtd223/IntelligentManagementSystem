package org.example.attendance.repository;

import org.example.attendance.entity.Employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    Optional<Employee> findByEmployeeNo(String employeeNo);

    Optional<Employee> findByEmail(String email);

    boolean existsByEmployeeNo(String employeeNo);

    boolean existsByEmail(String email);

    @Query("SELECT e FROM Employee e LEFT JOIN FETCH e.department LEFT JOIN FETCH e.officeLocation " +
           "WHERE (:deptId IS NULL OR e.department.id = :deptId) " +
           "AND (:status IS NULL OR e.status = :status) " +
           "AND (:keyword IS NULL OR e.name LIKE %:keyword% OR e.employeeNo LIKE %:keyword%)")
    Page<Employee> searchEmployees(@Param("deptId") Long deptId,
                                   @Param("status") Employee.Status status,
                                   @Param("keyword") String keyword,
                                   Pageable pageable);
}

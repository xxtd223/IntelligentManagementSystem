package org.example.attendance.repository;

import org.example.attendance.entity.OfficeLocation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OfficeLocationRepository extends JpaRepository<OfficeLocation, Long> {
    List<OfficeLocation> findByIsActiveTrue();
}

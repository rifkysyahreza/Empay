package com.rifky.empay.employee.service;

import com.rifky.empay.employee.domain.Employee;
import com.rifky.empay.employee.domain.EmployeeRepository;
import com.rifky.empay.employee.dto.EmployeeDto;
import com.rifky.empay.employee.dto.UpsertEmployeeRequest;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
public class EmployeeService {
    private final EmployeeRepository repo;
    public EmployeeService(EmployeeRepository repo) { this.repo = repo; }

    public EmployeeDto create(UpsertEmployeeRequest req) {
        // TODO: map req -> entity, save, map back -> dto
        var saved = repo.save(Employee.builder()
                .employeeCode(req.employeeCode())
                .fullName(req.fullName())
                .hireDate(req.hireDate())
                .baseSalary(req.baseSalary())
                .build());
        return new EmployeeDto(saved.getId(), saved.getEmployeeCode(), saved.getFullName(), saved.getHireDate(), saved.getBaseSalary());
    }

    public Optional<EmployeeDto> findById(UUID id) {
        return repo.findById(id).map(e -> new EmployeeDto(e.getId(), e.getEmployeeCode(), e.getFullName(), e.getHireDate(), e.getBaseSalary()));
    }
}

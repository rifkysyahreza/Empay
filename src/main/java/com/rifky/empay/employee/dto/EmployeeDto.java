package com.rifky.empay.employee.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record EmployeeDto(
        UUID id,
        String employeeCode,
        String fullName,
        LocalDate hireDate,
        BigDecimal baseSalary
) {}


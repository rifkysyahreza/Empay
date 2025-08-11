package com.rifky.empay.employee.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record UpsertEmployeeRequest(
        @NotBlank String employeeCode,
        @NotBlank String fullName,
        @NotNull LocalDate hireDate,
        @NotNull @DecimalMin("0.0") BigDecimal baseSalary,
        String departmentId,
        String gradeId
) {}

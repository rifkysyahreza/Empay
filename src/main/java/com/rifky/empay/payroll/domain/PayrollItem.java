package com.rifky.empay.payroll.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "payroll_items", uniqueConstraints = @UniqueConstraint(columnNames = {"payroll_run_id", "employee_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PayrollItem {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "payroll_run_id", nullable = false) private UUID payrollRunId;
    @Column(name = "employee_id", nullable = false) private UUID employeeId;

    @Column(name = "base_salary", nullable = false) private BigDecimal baseSalary;
    @Column(name = "overtime_hours") private BigDecimal overtimeHours;
    @Column(name = "overtime_amount") private BigDecimal overtimeAmount;
    @Column(name = "deductions_amount") private BigDecimal deductionsAmount;
    @Column(name = "bonus_amount") private BigDecimal bonusAmount;
    @Column(name = "gross_pay", nullable = false) private BigDecimal grossPay;
    @Column(name = "tax_amount") private BigDecimal taxAmount;
    @Column(name = "net_pay", nullable = false) private BigDecimal netPay;
}

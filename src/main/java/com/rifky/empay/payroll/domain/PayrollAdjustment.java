package com.rifky.empay.payroll.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "payroll_adjustments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PayrollAdjustment {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "payroll_item_id", nullable = false) private UUID payrollItemId;
    @Enumerated(EnumType.STRING) private AdjustmentType type;
    private String description;
    private BigDecimal amount;
}

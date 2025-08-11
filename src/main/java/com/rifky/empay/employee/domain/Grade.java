package com.rifky.empay.employee.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "grades")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Grade {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(unique = true, nullable = false) private String name;
    @Column(name = "overtime_rate_multiplier") private BigDecimal overtimeRateMultiplier;
}

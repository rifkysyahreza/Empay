package com.rifky.empay.payroll.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "payroll_runs", uniqueConstraints = @UniqueConstraint(columnNames = {"period_year", "period_month"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PayrollRun {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "period_year") private int periodYear;
    @Column(name = "period_month") private int periodMonth;
    @Enumerated(EnumType.STRING) private PayrollStatus status = PayrollStatus.OPEN;
    @Column(name = "processed_at") private OffsetDateTime processedAt;
    @Column(name = "processed_by") private UUID processedBy;
}

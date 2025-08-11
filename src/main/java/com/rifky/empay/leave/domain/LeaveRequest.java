package com.rifky.empay.leave.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "leave_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaveRequest {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "employee_id", nullable = false) private UUID employeeId;
    private LocalDate startDate; private LocalDate endDate;
    @Enumerated(EnumType.STRING) private LeaveType type;
    @Enumerated(EnumType.STRING) private LeaveStatus status;
    private String reason;
    @Column(name = "approver_id") private UUID approverId;
    @Column(name = "approved_at") private OffsetDateTime approvedAt;
    @Column(name = "created_at") private OffsetDateTime createdAt;
}

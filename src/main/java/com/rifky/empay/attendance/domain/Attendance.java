package com.rifky.empay.attendance.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "attendances", uniqueConstraints = @UniqueConstraint(columnNames = {"employee_id","date"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Attendance {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "employee_id", nullable = false) private UUID employeeId;
    private LocalDate date;
    @Column(name = "check_in") private OffsetDateTime checkIn;
    @Column(name = "check_out") private OffsetDateTime checkOut;
    private String status; // PRESENT|LATE|ABSENT|UNSCHEDULED
    private String notes;
}

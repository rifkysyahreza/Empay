package com.rifky.empay.schedule.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "work_schedules", uniqueConstraints = @UniqueConstraint(columnNames = {"employee_id", "day_of_week"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkSchedule {
    @Id
    @GeneratedValue
    private UUID id;
    @Column(name = "employee_id", nullable = false) private UUID employeeId;
    @Column(name = "day_of_week", nullable = false) private int dayOfWeek; // 0-6
    @Column(name = "start_time") private LocalTime startTime;
    @Column(name = "end_time") private LocalTime endTime;
}

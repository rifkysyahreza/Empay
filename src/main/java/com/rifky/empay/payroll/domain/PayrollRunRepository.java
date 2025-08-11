package com.rifky.empay.payroll.domain;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PayrollRunRepository extends JpaRepository<PayrollRun, UUID> {
}

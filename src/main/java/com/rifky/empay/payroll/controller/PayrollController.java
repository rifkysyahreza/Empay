package com.rifky.empay.payroll.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payroll")
public class PayrollController {
    @PostMapping("/runs")
    public ResponseEntity<Void> createRun() { return ResponseEntity.ok().build(); }
}

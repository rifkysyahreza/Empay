package com.rifky.empay.employee.controller;

import com.rifky.empay.employee.dto.EmployeeDto;
import com.rifky.empay.employee.dto.UpsertEmployeeRequest;
import com.rifky.empay.employee.service.EmployeeService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/employees")
public class EmployeeController {
    private final EmployeeService svc;
    public EmployeeController(EmployeeService svc) { this.svc = svc; }

    @PostMapping
    public ResponseEntity<EmployeeDto> create(@RequestBody @Valid UpsertEmployeeRequest req) {
        return ResponseEntity.ok(svc.create(req));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EmployeeDto> get(@PathVariable UUID id) {
        return svc.findById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
}

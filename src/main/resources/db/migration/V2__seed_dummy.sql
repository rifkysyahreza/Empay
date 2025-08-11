-- Flyway Migration: V2__seed_dummy.sql
-- Purpose: Seed realistic, interconnected dummy data for development/testing
-- DB: PostgreSQL 16+
-- Prereq: V1__init.sql (schemas, constraints), pgcrypto extension
-- Notes:
--  - Password hashes below are placeholders. Replace with valid BCrypt if you plan to login via API.
--  - Day-of-week convention in work_schedules: 1..5 = Mon..Fri, 6 = Sat, 0 = Sun (follow your app docs).

-- 0) Idempotency guards ------------------------------------------------------
-- Use ON CONFLICT or EXISTS checks to avoid duplicate seeds when re-run.

-- 1) Users & Roles -----------------------------------------------------------
-- Extra users: 1 HR, 3 Employees
INSERT INTO users (id, username, email, password_hash, enabled)
SELECT gen_random_uuid(), u.username, u.email, '$2a$10$Wqv7hQmjgWbxlG3tr0fRWej0jRk3dU0q4g6.VbMDG6xtT3q9EuX2O', TRUE
FROM (VALUES
          ('hr1',  'hr1@company.local'),
          ('emp1', 'emp1@company.local'),
          ('emp2', 'emp2@company.local'),
          ('emp3', 'emp3@company.local')
     ) AS u(username, email)
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username = u.username);

-- Map roles for users above
-- Ensure roles exist (ADMIN/HR/EMPLOYEE were inserted in V1)
INSERT INTO user_roles(user_id, role_id)
SELECT usr.id, r.id
FROM users usr
         JOIN roles r ON r.name = 'HR'
WHERE usr.username = 'hr1'
ON CONFLICT DO NOTHING;

INSERT INTO user_roles(user_id, role_id)
SELECT usr.id, r.id
FROM users usr
         JOIN roles r ON r.name = 'EMPLOYEE'
WHERE usr.username IN ('emp1','emp2','emp3')
ON CONFLICT DO NOTHING;

-- 2) Departments & Grades ----------------------------------------------------
INSERT INTO departments (id, name)
SELECT gen_random_uuid(), d.name
FROM (VALUES ('Engineering'), ('HR'), ('Sales'), ('Finance')) AS d(name)
WHERE NOT EXISTS (SELECT 1 FROM departments x WHERE x.name = d.name);

INSERT INTO grades (id, name, overtime_rate_multiplier)
SELECT gen_random_uuid(), g.name, g.mult
FROM (VALUES
          ('G1', 1.25),
          ('G2', 1.50),
          ('G3', 2.00)
     ) AS g(name, mult)
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.name = g.name);

-- 3) Employees ---------------------------------------------------------------
-- Create 3 employees, linked to users & departments & grades
INSERT INTO employees (id, user_id, employee_code, full_name, hire_date, base_salary, department_id, grade_id, status, created_at)
SELECT gen_random_uuid(),
       (SELECT id FROM users WHERE username='emp1'),
       'EMP001', 'Yamada Taro', DATE '2024-01-01', 3000000,
       (SELECT id FROM departments WHERE name='Engineering'),
       (SELECT id FROM grades WHERE name='G2'),
       'ACTIVE', now()
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.employee_code = 'EMP001');

INSERT INTO employees (id, user_id, employee_code, full_name, hire_date, base_salary, department_id, grade_id, status, created_at)
SELECT gen_random_uuid(),
       (SELECT id FROM users WHERE username='emp2'),
       'EMP002', 'Suzuki Hanako', DATE '2023-10-15', 4200000,
       (SELECT id FROM departments WHERE name='Sales'),
       (SELECT id FROM grades WHERE name='G1'),
       'ACTIVE', now()
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.employee_code = 'EMP002');

INSERT INTO employees (id, user_id, employee_code, full_name, hire_date, base_salary, department_id, grade_id, status, created_at)
SELECT gen_random_uuid(),
       (SELECT id FROM users WHERE username='emp3'),
       'EMP003', 'Sato Ken', DATE '2022-05-20', 5500000,
       (SELECT id FROM departments WHERE name='Finance'),
       (SELECT id FROM grades WHERE name='G3'),
       'ACTIVE', now()
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.employee_code = 'EMP003');

-- 4) Work Schedules (Mon-Fri regular, Sat optional) -------------------------
-- EMP001: 09:00-17:00 Mon-Fri
INSERT INTO work_schedules (id, employee_id, day_of_week, start_time, end_time)
SELECT gen_random_uuid(), e.id, d.dow, TIME '09:00', TIME '17:00'
FROM employees e
         JOIN (VALUES (1),(2),(3),(4),(5)) AS d(dow) ON TRUE
WHERE e.employee_code = 'EMP001'
ON CONFLICT (employee_id, day_of_week) DO NOTHING;

-- EMP002: 08:30-17:30 Mon-Fri, Sat half day 09:00-13:00
INSERT INTO work_schedules (id, employee_id, day_of_week, start_time, end_time)
SELECT gen_random_uuid(), e.id, d.dow, TIME '08:30', TIME '17:30'
FROM employees e
         JOIN (VALUES (1),(2),(3),(4),(5)) AS d(dow) ON TRUE
WHERE e.employee_code = 'EMP002'
ON CONFLICT (employee_id, day_of_week) DO NOTHING;

INSERT INTO work_schedules (id, employee_id, day_of_week, start_time, end_time)
SELECT gen_random_uuid(), e.id, 6, TIME '09:00', TIME '13:00'
FROM employees e
WHERE e.employee_code = 'EMP002'
ON CONFLICT (employee_id, day_of_week) DO NOTHING;

-- EMP003: Shift 12:00-20:00 Mon-Fri
INSERT INTO work_schedules (id, employee_id, day_of_week, start_time, end_time)
SELECT gen_random_uuid(), e.id, d.dow, TIME '12:00', TIME '20:00'
FROM employees e
         JOIN (VALUES (1),(2),(3),(4),(5)) AS d(dow) ON TRUE
WHERE e.employee_code = 'EMP003'
ON CONFLICT (employee_id, day_of_week) DO NOTHING;

-- 5) Attendance for July 2025 -----------------------------------------------
-- Helper CTE: all days in July 2025 with ISO weekday index
WITH days AS (
    SELECT d::date AS dt,
           EXTRACT(ISODOW FROM d)::int AS isodow
    FROM generate_series(DATE '2025-07-01', DATE '2025-07-31', INTERVAL '1 day') AS d
)
-- EMP001: Mostly on-time, late on Tuesdays, 1 absence (15th). Only Mon-Fri.
INSERT INTO attendances (id, employee_id, date, check_in, check_out, status, notes)
SELECT gen_random_uuid(), e.id, ds.dt,
       CASE
           WHEN ds.dt = DATE '2025-07-15' THEN NULL
           WHEN ds.isodow = 2 THEN ((ds.dt::timestamp + TIME '09:12') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '08:55') AT TIME ZONE 'UTC')
           END,
       CASE
           WHEN ds.dt = DATE '2025-07-15' THEN NULL
           WHEN ds.isodow = 5 THEN ((ds.dt::timestamp + TIME '18:00') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '17:05') AT TIME ZONE 'UTC')
           END,
       CASE
           WHEN ds.dt = DATE '2025-07-15' THEN 'ABSENT'
           WHEN ds.isodow = 2 THEN 'LATE'
           ELSE 'PRESENT'
           END,
       NULL
FROM days ds
         JOIN employees e ON e.employee_code = 'EMP001'
WHERE ds.isodow BETWEEN 1 AND 5
ON CONFLICT DO NOTHING;

-- EMP002: Some late, some overtime, 2 absences (10th, and Sat 26th). Mon-Sat.
WITH days AS (
    SELECT d::date AS dt,
           EXTRACT(ISODOW FROM d)::int AS isodow
    FROM generate_series(DATE '2025-07-01', DATE '2025-07-31', INTERVAL '1 day') AS d
)
INSERT INTO attendances (id, employee_id, date, check_in, check_out, status, notes)
SELECT gen_random_uuid(), e.id, ds.dt,
       CASE
           WHEN ds.dt IN (DATE '2025-07-10', DATE '2025-07-26') THEN NULL
           WHEN ds.isodow = 3 THEN ((ds.dt::timestamp + TIME '08:45') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '08:35') AT TIME ZONE 'UTC')
           END,
       CASE
           WHEN ds.dt IN (DATE '2025-07-10', DATE '2025-07-26') THEN NULL
           WHEN ds.isodow IN (5,6) THEN ((ds.dt::timestamp + TIME '18:15') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '17:40') AT TIME ZONE 'UTC')
           END,
       CASE
           WHEN ds.dt IN (DATE '2025-07-10', DATE '2025-07-26') THEN 'ABSENT'
           WHEN ds.isodow = 3 THEN 'LATE'
           ELSE 'PRESENT'
           END,
       NULL
FROM days ds
         JOIN employees e ON e.employee_code = 'EMP002'
WHERE ds.isodow BETWEEN 1 AND 6
ON CONFLICT DO NOTHING;

-- EMP003: Shift worker 12:00-20:00, late on Thursdays, some overtime on Fridays. Mon-Fri.
WITH days AS (
    SELECT d::date AS dt,
           EXTRACT(ISODOW FROM d)::int AS isodow
    FROM generate_series(DATE '2025-07-01', DATE '2025-07-31', INTERVAL '1 day') AS d
)
INSERT INTO attendances (id, employee_id, date, check_in, check_out, status, notes)
SELECT gen_random_uuid(), e.id, ds.dt,
       CASE
           WHEN ds.isodow = 4 THEN ((ds.dt::timestamp + TIME '12:10') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '11:55') AT TIME ZONE 'UTC')
           END,
       CASE
           WHEN ds.isodow = 5 THEN ((ds.dt::timestamp + TIME '21:00') AT TIME ZONE 'UTC')
           ELSE ((ds.dt::timestamp + TIME '20:05') AT TIME ZONE 'UTC')
           END,
       CASE WHEN ds.isodow = 4 THEN 'LATE' ELSE 'PRESENT' END,
       NULL
FROM days ds
         JOIN employees e ON e.employee_code = 'EMP003'
WHERE ds.isodow BETWEEN 1 AND 5
ON CONFLICT DO NOTHING;

-- 6) Leave Requests ----------------------------------------------------------
-- EMP002: Annual leave 2025-07-22..2025-07-23 (approved by hr1)
INSERT INTO leave_requests (id, employee_id, start_date, end_date, type, reason, status, approver_id, approved_at, created_at)
SELECT gen_random_uuid(), e.id, DATE '2025-07-22', DATE '2025-07-23', 'ANNUAL', 'Family errand', 'APPROVED', u.id, now(), now()
FROM employees e
         JOIN users u ON u.username = 'hr1'
WHERE e.employee_code = 'EMP002'
  AND NOT EXISTS (
    SELECT 1 FROM leave_requests lr WHERE lr.employee_id = e.id AND lr.start_date = DATE '2025-07-22'
);

-- EMP003: Sick leave 2025-07-12 (rejected example -> wrong docs)
INSERT INTO leave_requests (id, employee_id, start_date, end_date, type, reason, status, approver_id, approved_at, created_at)
SELECT gen_random_uuid(), e.id, DATE '2025-07-12', DATE '2025-07-12', 'SICK', 'Flu symptoms', 'REJECTED', u.id, now(), now()
FROM employees e
         JOIN users u ON u.username = 'hr1'
WHERE e.employee_code = 'EMP003'
  AND NOT EXISTS (
    SELECT 1 FROM leave_requests lr WHERE lr.employee_id = e.id AND lr.start_date = DATE '2025-07-12'
);

-- 7) Payroll Run + Items (July 2025) ---------------------------------------
-- Create run (if not exists), mark LOCKED with processed_at
WITH ins AS (
    INSERT INTO payroll_runs (id, period_year, period_month, status, processed_at, processed_by)
        SELECT gen_random_uuid(), 2025, 7, 'OPEN', NULL, NULL
        WHERE NOT EXISTS (SELECT 1 FROM payroll_runs WHERE period_year=2025 AND period_month=7)
        RETURNING id
), run AS (
    SELECT id FROM ins
    UNION ALL
    SELECT id FROM payroll_runs WHERE period_year=2025 AND period_month=7
), ot AS (
    SELECT e.id AS employee_id,
           COALESCE(SUM(GREATEST(EXTRACT(EPOCH FROM (a.check_out - a.check_in))/3600 - 8, 0)), 0) AS overtime_hours
    FROM employees e
             LEFT JOIN attendances a ON a.employee_id = e.id
        AND a.date BETWEEN DATE '2025-07-01' AND DATE '2025-07-31'
        AND a.check_in IS NOT NULL AND a.check_out IS NOT NULL
    GROUP BY e.id
)
INSERT INTO payroll_items (
    id, payroll_run_id, employee_id, base_salary, overtime_hours, overtime_amount,
    deductions_amount, bonus_amount, gross_pay, tax_amount, net_pay
)
SELECT gen_random_uuid(), r.id, e.id,
       e.base_salary,
       ROUND(ot.overtime_hours::numeric, 2) AS overtime_hours,
       ROUND( (ot.overtime_hours * (e.base_salary/173.0) * COALESCE(g.overtime_rate_multiplier,1.0))::numeric, 2) AS overtime_amount,
       (SELECT COUNT(*) * 50000 FROM attendances a WHERE a.employee_id=e.id AND a.status='ABSENT' AND a.date BETWEEN DATE '2025-07-01' AND DATE '2025-07-31') AS deductions_amount,
       CASE WHEN (SELECT COUNT(*) FROM attendances a WHERE a.employee_id=e.id AND a.status='ABSENT' AND a.date BETWEEN DATE '2025-07-01' AND DATE '2025-07-31') = 0
                THEN 100000 ELSE 0 END AS bonus_amount,
       0, 0, 0
FROM run r
         JOIN employees e ON e.status='ACTIVE'
         LEFT JOIN grades g ON g.id = e.grade_id
         LEFT JOIN ot ON ot.employee_id = e.id
WHERE NOT EXISTS (
    SELECT 1 FROM payroll_items pi WHERE pi.payroll_run_id = r.id AND pi.employee_id = e.id
);

-- Update gross/tax/net after inserts (5% simple tax)
WITH r AS (
    SELECT id FROM payroll_runs WHERE period_year=2025 AND period_month=7
)
UPDATE payroll_items pi
SET gross_pay = pi.base_salary + pi.overtime_amount + pi.bonus_amount - pi.deductions_amount,
    tax_amount = ROUND(( (pi.base_salary + pi.overtime_amount + pi.bonus_amount - pi.deductions_amount) * 0.05 )::numeric, 2),
    net_pay  = (pi.base_salary + pi.overtime_amount + pi.bonus_amount - pi.deductions_amount) - ROUND(( (pi.base_salary + pi.overtime_amount + pi.bonus_amount - pi.deductions_amount) * 0.05 )::numeric, 2)
FROM r
WHERE pi.payroll_run_id = r.id;

-- Add sample adjustments: bonus for EMP001, deduction for EMP002
INSERT INTO payroll_adjustments (id, payroll_item_id, type, description, amount)
SELECT gen_random_uuid(), pi.id, 'BONUS', 'Performance bonus', 150000
FROM payroll_items pi
         JOIN employees e ON e.id = pi.employee_id
         JOIN payroll_runs pr ON pr.id = pi.payroll_run_id AND pr.period_year=2025 AND pr.period_month=7
WHERE e.employee_code = 'EMP001'
ON CONFLICT DO NOTHING;

INSERT INTO payroll_adjustments (id, payroll_item_id, type, description, amount)
SELECT gen_random_uuid(), pi.id, 'DEDUCTION', 'Late penalties', 50000
FROM payroll_items pi
         JOIN employees e ON e.id = pi.employee_id
         JOIN payroll_runs pr ON pr.id = pi.payroll_run_id AND pr.period_year=2025 AND pr.period_month=7
WHERE e.employee_code = 'EMP002'
ON CONFLICT DO NOTHING;

-- Lock the payroll run
UPDATE payroll_runs
SET status='LOCKED', processed_at=now(), processed_by = (SELECT id FROM users WHERE username='hr1' LIMIT 1)
WHERE period_year=2025 AND period_month=7;

-- 8) Audit Logs --------------------------------------------------------------
INSERT INTO audit_logs (id, actor_user_id, action, entity, entity_id, created_at, metadata)
SELECT gen_random_uuid(), u.id, 'EMPLOYEE_CREATE', 'Employee', e.id, now(), '{"source":"seed","note":"initial insert"}'::jsonb
FROM employees e
         JOIN users u ON u.username = 'hr1'
ON CONFLICT DO NOTHING;

INSERT INTO audit_logs (id, actor_user_id, action, entity, entity_id, created_at, metadata)
SELECT gen_random_uuid(), u.id, 'PAYROLL_LOCK', 'PayrollRun', pr.id, now(), '{"period":"2025-07","locked":true}'::jsonb
FROM payroll_runs pr
         JOIN users u ON u.username = 'hr1'
WHERE pr.period_year=2025 AND pr.period_month=7
ON CONFLICT DO NOTHING;

-- 9) Sanity checks (optional queries; comment out in production)
-- SELECT * FROM users WHERE username IN ('hr1','emp1','emp2','emp3');
-- SELECT employee_code, full_name FROM employees;
-- SELECT date, status FROM attendances a JOIN employees e ON e.id=a.employee_id WHERE e.employee_code='EMP001' ORDER BY date;
-- SELECT * FROM payroll_items pi JOIN employees e ON e.id=pi.employee_id JOIN payroll_runs pr ON pr.id=pi.payroll_run_id WHERE pr.period_year=2025 AND pr.period_month=7;

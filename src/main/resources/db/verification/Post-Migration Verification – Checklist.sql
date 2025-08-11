-- Post‑Migration Verification – Checklist.sql
-- Run this after Flyway V1 & V2 to confirm data integrity and realism.
-- Safe to run multiple times (read‑only).

-- 0) Context ---------------------------------------------------------------
-- Assumes default schema = public; PostgreSQL 16+.
-- Qualify all columns to avoid ambiguity.

\timing on

-- 1) Basic counts -----------------------------------------------------------
SELECT 'users' AS tbl, COUNT(*) AS n FROM public.users
UNION ALL SELECT 'roles', COUNT(*) FROM public.roles
UNION ALL SELECT 'user_roles', COUNT(*) FROM public.user_roles
UNION ALL SELECT 'departments', COUNT(*) FROM public.departments
UNION ALL SELECT 'grades', COUNT(*) FROM public.grades
UNION ALL SELECT 'employees', COUNT(*) FROM public.employees
UNION ALL SELECT 'work_schedules', COUNT(*) FROM public.work_schedules
UNION ALL SELECT 'attendances', COUNT(*) FROM public.attendances
UNION ALL SELECT 'leave_requests', COUNT(*) FROM public.leave_requests
UNION ALL SELECT 'payroll_runs', COUNT(*) FROM public.payroll_runs
UNION ALL SELECT 'payroll_items', COUNT(*) FROM public.payroll_items
UNION ALL SELECT 'payroll_adjustments', COUNT(*) FROM public.payroll_adjustments
UNION ALL SELECT 'audit_logs', COUNT(*) FROM public.audit_logs
ORDER BY 1;

-- 2) Users & roles mapping --------------------------------------------------
SELECT u.username, u.email, u.enabled,
       STRING_AGG(r.name::text, ', ' ORDER BY r.name) AS roles
FROM public.users u
         LEFT JOIN public.user_roles ur ON ur.user_id = u.id
         LEFT JOIN public.roles r ON r.id = ur.role_id
GROUP BY u.id, u.username, u.email, u.enabled
ORDER BY u.username;

-- 3) Employees join check (dept/grade linked) ------------------------------
SELECT e.employee_code, e.full_name,
       d.name AS department, g.name AS grade,
       e.status AS emp_status, e.base_salary
FROM public.employees e
         LEFT JOIN public.departments d ON d.id = e.department_id
         LEFT JOIN public.grades g ON g.id = e.grade_id
ORDER BY e.employee_code;

-- 4) Work schedule sanity (per employee Mon‑Fri) ---------------------------
SELECT e.employee_code, ws.day_of_week, ws.start_time, ws.end_time
FROM public.work_schedules ws
         JOIN public.employees e ON e.id = ws.employee_id
ORDER BY e.employee_code, ws.day_of_week;

-- 5) Attendance spot check (first 20 rows per employee) --------------------
SELECT e.employee_code, a.date, a.status, a.check_in, a.check_out
FROM public.attendances a
         JOIN public.employees e ON e.id = a.employee_id
ORDER BY e.employee_code, a.date
LIMIT 60;

-- 6) Attendance anomalies (check_out < check_in, null pairs) --------------
SELECT e.employee_code, a.date, a.check_in, a.check_out
FROM public.attendances a
         JOIN public.employees e ON e.id = a.employee_id
WHERE a.check_in IS NOT NULL AND a.check_out IS NOT NULL
  AND a.check_out < a.check_in
ORDER BY e.employee_code, a.date;

SELECT e.employee_code, a.date, a.status
FROM public.attendances a
         JOIN public.employees e ON e.id = a.employee_id
WHERE (a.check_in IS NULL AND a.check_out IS NOT NULL)
   OR (a.check_in IS NOT NULL AND a.check_out IS NULL)
ORDER BY e.employee_code, a.date;

-- 7) Leave requests summary -------------------------------------------------
SELECT e.employee_code, lr.type, lr.status, lr.start_date, lr.end_date, lr.approved_at
FROM public.leave_requests lr
         JOIN public.employees e ON e.id = lr.employee_id
ORDER BY e.employee_code, lr.start_date;

-- 8) Payroll run and items summary -----------------------------------------
SELECT pr.period_year, pr.period_month, pr.status,
       e.employee_code,
       pi.base_salary, pi.overtime_hours, pi.overtime_amount,
       pi.deductions_amount, pi.bonus_amount,
       pi.gross_pay, pi.tax_amount, pi.net_pay
FROM public.payroll_items pi
         JOIN public.payroll_runs pr ON pr.id = pi.payroll_run_id
         JOIN public.employees e ON e.id = pi.employee_id
ORDER BY pr.period_year, pr.period_month, e.employee_code;

-- 9) Payroll totals (sanity: sum of items) ---------------------------------
SELECT pr.period_year, pr.period_month, pr.status,
       SUM(pi.base_salary)       AS total_base,
       SUM(pi.overtime_amount)   AS total_ot_amount,
       SUM(pi.deductions_amount) AS total_deductions,
       SUM(pi.bonus_amount)      AS total_bonus,
       SUM(pi.gross_pay)         AS total_gross,
       SUM(pi.tax_amount)        AS total_tax,
       SUM(pi.net_pay)           AS total_net
FROM public.payroll_items pi
         JOIN public.payroll_runs pr ON pr.id = pi.payroll_run_id
GROUP BY pr.period_year, pr.period_month, pr.status
ORDER BY pr.period_year, pr.period_month;

-- 10) Orphan checks (should return zero rows) ------------------------------
-- Employee without matching user
SELECT e.* FROM public.employees e
                    LEFT JOIN public.users u ON u.id = e.user_id
WHERE e.user_id IS NOT NULL AND u.id IS NULL;

-- Schedule without employee
SELECT ws.* FROM public.work_schedules ws
                     LEFT JOIN public.employees e ON e.id = ws.employee_id
WHERE e.id IS NULL;

-- Payroll item without payroll run
SELECT pi.* FROM public.payroll_items pi
                     LEFT JOIN public.payroll_runs pr ON pr.id = pi.payroll_run_id
WHERE pr.id IS NULL;

-- Attendance without employee
SELECT a.* FROM public.attendances a
                    LEFT JOIN public.employees e ON e.id = a.employee_id
WHERE e.id IS NULL;

-- 11) JSONB check in audit logs -------------------------------------------
SELECT id, action, entity, created_at,
       jsonb_typeof(metadata) AS metadata_type
FROM public.audit_logs
ORDER BY created_at DESC
LIMIT 10;

-- 12) Index presence (optional quick glance) -------------------------------
SELECT schemaname, relname AS index_name
FROM pg_stat_user_indexes
ORDER BY 1,2;

-- 13) Quick API‑oriented samples -------------------------------------------
-- Latest 5 attendance of EMP001
SELECT a.date, a.status, a.check_in, a.check_out
FROM public.attendances a
         JOIN public.employees e ON e.id = a.employee_id
WHERE e.employee_code = 'EMP001'
ORDER BY a.date DESC
LIMIT 5;

-- Payroll slip‑like view for all employees for 2025‑07
SELECT e.employee_code, e.full_name,
       pi.base_salary, pi.overtime_hours, pi.overtime_amount,
       pi.deductions_amount, pi.bonus_amount,
       pi.gross_pay, pi.tax_amount, pi.net_pay
FROM public.payroll_items pi
         JOIN public.employees e ON e.id = pi.employee_id
         JOIN public.payroll_runs pr ON pr.id = pi.payroll_run_id
WHERE pr.period_year = 2025 AND pr.period_month = 7
ORDER BY e.employee_code;

\timing off

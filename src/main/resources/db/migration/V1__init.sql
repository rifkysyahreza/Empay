-- Auth
CREATE TABLE users (
                       id UUID PRIMARY KEY,
                       username VARCHAR(50) NOT NULL UNIQUE,
                       email VARCHAR(255) NOT NULL UNIQUE,
                       password_hash VARCHAR(255) NOT NULL,
                       enabled BOOLEAN DEFAULT TRUE,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                       updated_at TIMESTAMPTZ
);

CREATE TABLE roles (
                       id UUID PRIMARY KEY,
                       name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE user_roles (
                            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                            role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
                            PRIMARY KEY (user_id, role_id)
);

-- Employee core
CREATE TABLE departments (
                             id UUID PRIMARY KEY,
                             name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE grades (
                        id UUID PRIMARY KEY,
                        name VARCHAR(50) NOT NULL UNIQUE,
                        overtime_rate_multiplier NUMERIC(5,2)
);

CREATE TABLE employees (
                           id UUID PRIMARY KEY,
                           user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
                           employee_code VARCHAR(32) NOT NULL UNIQUE,
                           full_name VARCHAR(150) NOT NULL,
                           hire_date DATE NOT NULL,
                           base_salary NUMERIC(14,2) NOT NULL,
                           department_id UUID REFERENCES departments(id),
                           grade_id UUID REFERENCES grades(id),
                           status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
                           created_at TIMESTAMPTZ DEFAULT NOW(),
                           updated_at TIMESTAMPTZ
);

-- Schedule & attendance
CREATE TABLE work_schedules (
                                id UUID PRIMARY KEY,
                                employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
                                day_of_week INT NOT NULL,
                                start_time TIME,
                                end_time TIME,
                                UNIQUE(employee_id, day_of_week)
);

CREATE TABLE attendances (
                             id UUID PRIMARY KEY,
                             employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
                             date DATE NOT NULL,
                             check_in TIMESTAMPTZ,
                             check_out TIMESTAMPTZ,
                             status VARCHAR(20),
                             notes TEXT,
                             UNIQUE(employee_id, date)
);

-- Leave
CREATE TABLE leave_requests (
                                id UUID PRIMARY KEY,
                                employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
                                start_date DATE NOT NULL,
                                end_date DATE NOT NULL,
                                type VARCHAR(20) NOT NULL,
                                status VARCHAR(20) NOT NULL,
                                reason TEXT,
                                approver_id UUID REFERENCES users(id),
                                approved_at TIMESTAMPTZ,
                                created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payroll
CREATE TABLE payroll_runs (
                              id UUID PRIMARY KEY,
                              period_year INT NOT NULL,
                              period_month INT NOT NULL,
                              status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
                              processed_at TIMESTAMPTZ,
                              processed_by UUID REFERENCES users(id),
                              UNIQUE(period_year, period_month)
);

CREATE TABLE payroll_items (
                               id UUID PRIMARY KEY,
                               payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
                               employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
                               base_salary NUMERIC(14,2) NOT NULL,
                               overtime_hours NUMERIC(6,2) DEFAULT 0,
                               overtime_amount NUMERIC(14,2) DEFAULT 0,
                               deductions_amount NUMERIC(14,2) DEFAULT 0,
                               bonus_amount NUMERIC(14,2) DEFAULT 0,
                               gross_pay NUMERIC(14,2) NOT NULL,
                               tax_amount NUMERIC(14,2) DEFAULT 0,
                               net_pay NUMERIC(14,2) NOT NULL,
                               UNIQUE(payroll_run_id, employee_id)
);

CREATE TABLE payroll_adjustments (
                                     id UUID PRIMARY KEY,
                                     payroll_item_id UUID NOT NULL REFERENCES payroll_items(id) ON DELETE CASCADE,
                                     type VARCHAR(20) NOT NULL,
                                     description TEXT,
                                     amount NUMERIC(14,2) NOT NULL
);

-- Audit
CREATE TABLE audit_logs (
                            id UUID PRIMARY KEY,
                            actor_user_id UUID REFERENCES users(id),
                            action VARCHAR(100) NOT NULL,
                            entity VARCHAR(100) NOT NULL,
                            entity_id UUID,
                            created_at TIMESTAMPTZ DEFAULT NOW(),
                            metadata JSONB
);

-- Index rekomendasi
CREATE INDEX idx_attendance_emp_date ON attendances(employee_id, date);
CREATE INDEX idx_payroll_items_run_emp ON payroll_items(payroll_run_id, employee_id);
CREATE INDEX idx_leave_emp_dates ON leave_requests(employee_id, start_date, end_date);
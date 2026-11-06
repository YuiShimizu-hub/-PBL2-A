-- 新規データベース用。MySQL 8.0以降 / InnoDB / utf8mb4。
-- 既存DBに無確認で適用しないでください。
-- 実行例: mysql -u DB_USER -p pbl_workshare < db/migrations/001_schema.sql
CREATE TABLE
    IF NOT EXISTS departments (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS employees (
        employee_id CHAR(8) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        department_id INT UNSIGNED NOT NULL,
        email VARCHAR(255) NULL UNIQUE,
        extension_number VARCHAR(20) NULL,
        phone VARCHAR(30) NULL,
        password_hash VARCHAR(255) NOT NULL,
        role ENUM ('employee', 'admin') NOT NULL DEFAULT 'employee',
        is_active TINYINT (1) NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_employee_department (department_id),
        CONSTRAINT fk_employee_department FOREIGN KEY (department_id) REFERENCES departments (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS floors (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        layout_version INT UNSIGNED NOT NULL DEFAULT 1,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS seats (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        floor_id INT UNSIGNED NOT NULL,
        label VARCHAR(30) NOT NULL,
        x SMALLINT UNSIGNED NOT NULL DEFAULT 5,
        y SMALLINT UNSIGNED NOT NULL DEFAULT 5,
        width SMALLINT UNSIGNED NOT NULL DEFAULT 12,
        height SMALLINT UNSIGNED NOT NULL DEFAULT 12,
        is_active TINYINT (1) NOT NULL DEFAULT 1,
        -- 削除済み座席の番号を再利用できるように、利用可能な座席だけ重複禁止
        active_label VARCHAR(30) GENERATED ALWAYS AS (
            CASE
                WHEN is_active = 1 THEN label
                ELSE NULL
            END
        ) STORED,
        UNIQUE KEY uq_active_seat_label (floor_id, active_label),
        INDEX idx_seats_floor (floor_id, is_active),
        CONSTRAINT fk_seats_floor FOREIGN KEY (floor_id) REFERENCES floors (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS fixtures (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        floor_id INT UNSIGNED NOT NULL,
        kind ENUM ('desk', 'meeting', 'other') NOT NULL DEFAULT 'other',
        label VARCHAR(40) NOT NULL,
        x SMALLINT UNSIGNED NOT NULL DEFAULT 5,
        y SMALLINT UNSIGNED NOT NULL DEFAULT 5,
        width SMALLINT UNSIGNED NOT NULL DEFAULT 20,
        height SMALLINT UNSIGNED NOT NULL DEFAULT 12,
        INDEX idx_fixture_floor (floor_id),
        CONSTRAINT fk_fixtures_floor FOREIGN KEY (floor_id) REFERENCES floors (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS work_statuses (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        employee_id CHAR(8) NOT NULL,
        work_date DATE NOT NULL,
        work_mode ENUM ('off', 'office', 'remote') NOT NULL DEFAULT 'off',
        activity ENUM (
            'present',
            'break',
            'meeting',
            'outside',
            'business_trip'
        ) NULL,
        contact ENUM ('available', 'unavailable', 'urgent_only') NOT NULL DEFAULT 'unavailable',
        seat_id INT UNSIGNED NULL,
        clock_in_at DATETIME NULL,
        clock_out_at DATETIME NULL,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_work_employee_day (employee_id, work_date),
        -- NULLは複数許容。実際に使用中の座席は1日1人だけ。
        UNIQUE KEY uq_work_seat_day (work_date, seat_id),
        INDEX idx_work_day_mode (work_date, work_mode),
        CONSTRAINT fk_work_employee FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
        CONSTRAINT fk_work_seat FOREIGN KEY (seat_id) REFERENCES seats (id) ON DELETE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS favorites (
        owner_id CHAR(8) NOT NULL,
        target_id CHAR(8) NOT NULL,
        PRIMARY KEY (owner_id, target_id),
        CONSTRAINT fk_favorites_owner FOREIGN KEY (owner_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
        CONSTRAINT fk_favorites_target FOREIGN KEY (target_id) REFERENCES employees (employee_id) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE
    IF NOT EXISTS audit_logs (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        actor_id CHAR(8) NULL,
        action VARCHAR(80) NOT NULL,
        detail VARCHAR(250) NOT NULL DEFAULT '',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_audit_created (created_at),
        CONSTRAINT fk_audit_actor FOREIGN KEY (actor_id) REFERENCES employees (employee_id) ON DELETE SET NULL
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

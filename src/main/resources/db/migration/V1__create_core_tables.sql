-- 部门表
CREATE TABLE department (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL UNIQUE COMMENT '部门名称',
    description VARCHAR(500) COMMENT '部门描述',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门';

-- 办公地点表
CREATE TABLE office_location (
    id             BIGINT PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(100) NOT NULL COMMENT '地点名称',
    address        VARCHAR(500) NOT NULL COMMENT '详细地址',
    latitude       DECIMAL(10,7) NOT NULL COMMENT '纬度',
    longitude      DECIMAL(10,7) NOT NULL COMMENT '经度',
    allowed_radius INT NOT NULL DEFAULT 200 COMMENT '允许打卡半径(米)',
    is_active      TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='办公地点';

-- 员工表
CREATE TABLE employee (
    id                 BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_no        VARCHAR(32) NOT NULL UNIQUE COMMENT '员工编号',
    name               VARCHAR(100) NOT NULL COMMENT '姓名',
    phone              VARCHAR(20) COMMENT '联系电话',
    email              VARCHAR(200) UNIQUE COMMENT '邮箱',
    password_hash      VARCHAR(255) NOT NULL COMMENT '密码哈希',
    role               ENUM('EMPLOYEE','ADMIN') NOT NULL DEFAULT 'EMPLOYEE' COMMENT '角色',
    status             ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE' COMMENT '状态',
    department_id      BIGINT COMMENT '部门ID',
    office_location_id BIGINT COMMENT '办公地点ID',
    avatar_url         VARCHAR(500) COMMENT '头像URL',
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE SET NULL,
    CONSTRAINT fk_emp_location FOREIGN KEY (office_location_id) REFERENCES office_location(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工';

-- 考勤规则表
CREATE TABLE attendance_rule (
    id                            BIGINT PRIMARY KEY AUTO_INCREMENT,
    office_location_id            BIGINT NOT NULL COMMENT '适用办公地点',
    name                          VARCHAR(100) NOT NULL COMMENT '规则名称',
    work_start_time               TIME NOT NULL COMMENT '上班时间',
    work_end_time                 TIME NOT NULL COMMENT '下班时间',
    late_threshold_minutes        INT NOT NULL DEFAULT 0 COMMENT '迟到宽限分钟',
    early_leave_threshold_minutes INT NOT NULL DEFAULT 0 COMMENT '早退宽限分钟',
    check_in_earliest             TIME COMMENT '最早可打卡时间',
    check_out_latest              TIME COMMENT '最晚可打卡时间',
    is_active                     TINYINT(1) NOT NULL DEFAULT 1,
    created_at                    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at                    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rule_location FOREIGN KEY (office_location_id) REFERENCES office_location(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考勤规则';

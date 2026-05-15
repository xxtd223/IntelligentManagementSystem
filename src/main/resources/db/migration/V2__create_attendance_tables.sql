-- 工作日历表（管理员可调整每个员工的工作日/时间）
CREATE TABLE work_calendar (
    id                BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_id       BIGINT NOT NULL COMMENT '员工ID',
    work_date         DATE NOT NULL COMMENT '日期',
    is_work_day       TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否工作日',
    custom_start_time TIME COMMENT '自定义上班时间(为空则用规则默认)',
    custom_end_time   TIME COMMENT '自定义下班时间(为空则用规则默认)',
    note              VARCHAR(500) COMMENT '备注(如:出差/节假日)',
    created_by        BIGINT COMMENT '操作管理员ID',
    created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_emp_date (employee_id, work_date),
    CONSTRAINT fk_wc_employee FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作日历';

-- 打卡记录表
CREATE TABLE attendance_record (
    id                 BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_id        BIGINT NOT NULL COMMENT '员工ID',
    check_date         DATE NOT NULL COMMENT '打卡日期(逻辑工作日)',
    check_time         DATETIME NOT NULL COMMENT '打卡时间戳',
    check_type         ENUM('CHECK_IN','CHECK_OUT') NOT NULL COMMENT '上班/下班',
    latitude           DECIMAL(10,7) COMMENT '打卡纬度',
    longitude          DECIMAL(10,7) COMMENT '打卡经度',
    office_location_id BIGINT COMMENT '关联办公地点',
    distance_meters    INT COMMENT '距办公地点距离(米)',
    status             ENUM('NORMAL','LATE','EARLY_LEAVE','INVALID','OUTSIDE_RANGE') NOT NULL DEFAULT 'NORMAL' COMMENT '打卡状态',
    is_valid           TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否有效',
    source             ENUM('APP','AI_CHAT') NOT NULL DEFAULT 'APP' COMMENT '打卡来源',
    note               VARCHAR(500) COMMENT '备注',
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ar_employee FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE,
    CONSTRAINT fk_ar_location FOREIGN KEY (office_location_id) REFERENCES office_location(id) ON DELETE SET NULL,
    INDEX idx_emp_date (employee_id, check_date),
    INDEX idx_check_date (check_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打卡记录';

-- 消息通知表
CREATE TABLE notification (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT NOT NULL COMMENT '员工ID',
    title       VARCHAR(200) NOT NULL COMMENT '标题',
    content     TEXT COMMENT '内容',
    type        ENUM('CHECK_IN_SUCCESS','CHECK_IN_FAIL','REMINDER','SYSTEM') NOT NULL COMMENT '类型',
    is_read     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否已读',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_emp FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE,
    INDEX idx_notif_emp_read (employee_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息通知';

-- AI对话会话表
CREATE TABLE ai_conversation_session (
    id            BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_id   BIGINT NOT NULL COMMENT '员工ID',
    session_key   VARCHAR(64) NOT NULL UNIQUE COMMENT '会话唯一标识',
    messages_json MEDIUMTEXT COMMENT '消息历史JSON数组',
    last_active_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_acs_emp FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE,
    INDEX idx_acs_emp (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话会话';

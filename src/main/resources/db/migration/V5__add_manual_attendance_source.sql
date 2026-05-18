-- 扩展打卡来源枚举，支持管理员手动录入
ALTER TABLE attendance_record
    MODIFY COLUMN source ENUM('APP','AI_CHAT','MANUAL') NOT NULL DEFAULT 'APP' COMMENT '打卡来源';

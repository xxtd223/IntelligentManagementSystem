-- 初始部门
INSERT INTO department (name, description) VALUES
('技术部', '负责产品研发和技术架构'),
('人力资源部', '负责招聘、考勤与员工管理'),
('市场部', '负责市场推广与客户关系');

-- 初始办公地点（示例坐标：上海陆家嘴）
INSERT INTO office_location (name, address, latitude, longitude, allowed_radius) VALUES
('长春总部', '吉林省长春市南关区天骄大厦', 43.8507, 125.3323, 500),
('北京分部', '北京市朝阳区建国路88号', 39.9042, 116.4074, 300);

-- 考勤规则
INSERT INTO attendance_rule (office_location_id, name, work_start_time, work_end_time,
                             late_threshold_minutes, early_leave_threshold_minutes,
                             check_in_earliest, check_out_latest) VALUES
(1, '上海标准班制', '09:00:00', '18:00:00', 5, 5, '07:00:00', '22:00:00'),
(2, '北京标准班制', '09:00:00', '18:00:00', 5, 5, '07:00:00', '22:00:00');

-- 员工账号由 DataInitializer 在应用启动时创建（使用 PasswordEncoder 生成正确哈希）

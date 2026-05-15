package org.example.attendance.exception;

import lombok.Getter;

@Getter
public enum ErrorCode {
    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "未授权，请先登录"),
    FORBIDDEN(403, "权限不足"),
    NOT_FOUND(404, "资源不存在"),
    CONFLICT(409, "数据冲突"),
    INTERNAL_ERROR(500, "服务器内部错误"),

    // Auth
    INVALID_CREDENTIALS(1001, "账号或密码错误"),
    ACCOUNT_DISABLED(1002, "账号已停用"),
    TOKEN_INVALID(1003, "Token无效或已过期"),

    // Attendance
    OUTSIDE_RANGE(2001, "当前位置不在允许打卡范围内"),
    ALREADY_CHECKED_IN(2002, "今日已完成上班打卡"),
    ALREADY_CHECKED_OUT(2003, "今日已完成下班打卡"),
    NOT_WORK_DAY(2004, "今日为非工作日"),
    NO_ATTENDANCE_RULE(2005, "未找到适用的考勤规则"),
    NO_OFFICE_LOCATION(2006, "员工未绑定办公地点"),
    CHECK_IN_REQUIRED(2007, "请先完成上班打卡"),

    // Employee
    EMPLOYEE_NOT_FOUND(3001, "员工不存在"),
    EMPLOYEE_NO_EXISTS(3002, "员工编号已存在"),
    EMAIL_EXISTS(3003, "邮箱已被使用");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}

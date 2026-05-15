package org.example.attendance.service.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.attendance.entity.AiConversationSession;
import org.example.attendance.entity.Employee;
import org.example.attendance.repository.AiConversationSessionRepository;
import org.example.attendance.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@Slf4j
@RequiredArgsConstructor
public class QwenChatService {

    private final AiConversationSessionRepository sessionRepository;
    private final EmployeeRepository employeeRepository;
    private final AttendanceToolExecutor toolExecutor;
    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${qwen.model:qwen-max}")
    private String model;

    @Value("${qwen.max-history-turns:20}")
    private int maxHistoryTurns;

    @Value("${qwen.api-key:}")
    private String apiKey;

    private static final String GENERATION_PATH = "/services/aigc/text-generation/generation";

    @Transactional
    public Map<String, Object> chat(Long employeeId, String sessionKey,
                                    String userMessage, BigDecimal latitude, BigDecimal longitude) {
        if (apiKey == null || apiKey.isBlank()) {
            return Map.of("reply", "AI 助手暂未配置（需设置 DASHSCOPE_API_KEY 环境变量），其他考勤功能正常使用。", "actionTaken", "");
        }
        Employee employee = employeeRepository.findById(employeeId).orElseThrow();

        // 加载或创建会话
        AiConversationSession session = sessionRepository.findBySessionKey(sessionKey)
                .orElseGet(() -> {
                    AiConversationSession s = AiConversationSession.builder()
                            .employee(employee)
                            .sessionKey(sessionKey)
                            .messagesJson("[]")
                            .build();
                    return sessionRepository.save(s);
                });

        List<Map<String, Object>> messages = loadMessages(session.getMessagesJson());

        // 注入系统提示（首次对话）
        if (messages.isEmpty()) {
            messages.add(Map.of("role", "system", "content", buildSystemPrompt(employee)));
        }

        // 添加用户消息
        messages.add(Map.of("role", "user", "content", userMessage));

        // 工具调用循环
        String finalReply = null;
        String actionTaken = null;
        int maxLoops = 5;

        for (int loop = 0; loop < maxLoops; loop++) {
            JsonNode response = callQwen(trimMessages(messages));
            JsonNode choice = response.path("output").path("choices").get(0);
            String finishReason = choice.path("finish_reason").asText();
            JsonNode message = choice.path("message");

            if ("tool_calls".equals(finishReason) || message.has("tool_calls")) {
                // 添加 assistant 消息
                Map<String, Object> assistantMsg = new LinkedHashMap<>();
                assistantMsg.put("role", "assistant");
                if (message.has("content")) {
                    assistantMsg.put("content", message.path("content").asText(""));
                }
                List<Map<String, Object>> toolCallsList = new ArrayList<>();
                JsonNode toolCalls = message.path("tool_calls");
                for (JsonNode tc : toolCalls) {
                    Map<String, Object> tcMap = new LinkedHashMap<>();
                    tcMap.put("id", tc.path("id").asText());
                    tcMap.put("type", "function");
                    tcMap.put("function", Map.of(
                            "name", tc.path("function").path("name").asText(),
                            "arguments", tc.path("function").path("arguments").asText()
                    ));
                    toolCallsList.add(tcMap);
                }
                assistantMsg.put("tool_calls", toolCallsList);
                messages.add(assistantMsg);

                // 执行每个工具
                for (JsonNode tc : toolCalls) {
                    String toolName = tc.path("function").path("name").asText();
                    String argsJson = tc.path("function").path("arguments").asText();
                    String toolCallId = tc.path("id").asText();

                    AttendanceToolExecutor.ToolResult result = toolExecutor.execute(
                            employeeId, toolName, argsJson, latitude, longitude);

                    messages.add(Map.of(
                            "role", "tool",
                            "tool_call_id", toolCallId,
                            "content", result.content()
                    ));

                    if (actionTaken == null && result.actionTaken() != null) {
                        actionTaken = result.actionTaken();
                    }
                }
            } else {
                // 最终回复
                finalReply = message.path("content").asText("好的，我已为您处理完成。");
                Map<String, Object> assistantMsg = Map.of("role", "assistant", "content", finalReply);
                messages.add(assistantMsg);
                break;
            }
        }

        if (finalReply == null) {
            finalReply = "操作已完成，请查看考勤记录。";
        }

        // 保存会话历史
        session.setMessagesJson(saveMessages(messages));
        session.setLastActiveAt(LocalDateTime.now());
        sessionRepository.save(session);

        return Map.of("reply", finalReply, "actionTaken", actionTaken != null ? actionTaken : "");
    }

    @Transactional
    public void clearSession(Long employeeId) {
        sessionRepository.findByEmployeeId(employeeId).ifPresent(s -> {
            s.setMessagesJson("[]");
            sessionRepository.save(s);
        });
    }

    private JsonNode callQwen(List<Map<String, Object>> messages) {
        ObjectNode requestBody = objectMapper.createObjectNode();
        requestBody.put("model", model);

        ObjectNode input = requestBody.putObject("input");
        input.set("messages", objectMapper.valueToTree(messages));

        ObjectNode parameters = requestBody.putObject("parameters");
        parameters.put("result_format", "message");
        parameters.set("tools", buildToolsDefinition());
        parameters.put("tool_choice", "auto");

        try {
            String responseStr = webClient.post()
                    .uri(GENERATION_PATH)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();
            return objectMapper.readTree(responseStr);
        } catch (Exception e) {
            log.error("Qwen API error", e);
            throw new RuntimeException("AI服务调用失败：" + e.getMessage());
        }
    }

    private ArrayNode buildToolsDefinition() {
        ArrayNode tools = objectMapper.createArrayNode();

        tools.add(buildTool("do_check_in", "为当前员工执行上班或下班打卡。在用户表达打卡意图时调用。",
                Map.of("check_type", Map.of(
                        "type", "string",
                        "enum", List.of("CHECK_IN", "CHECK_OUT"),
                        "description", "CHECK_IN=上班打卡, CHECK_OUT=下班打卡"
                )), List.of("check_type")));

        tools.add(buildTool("query_today_attendance", "查询当前员工今天的打卡记录",
                Map.of(), List.of()));

        tools.add(buildTool("query_monthly_attendance",
                "查询当前员工指定月份的考勤统计，包括迟到次数、缺卡次数等",
                Map.of(
                        "year", Map.of("type", "integer", "description", "年份"),
                        "month", Map.of("type", "integer", "minimum", 1, "maximum", 12, "description", "月份")
                ), List.of("year", "month")));

        tools.add(buildTool("query_attendance_range",
                "查询员工在指定日期范围内的考勤记录",
                Map.of(
                        "start_date", Map.of("type", "string", "description", "开始日期 YYYY-MM-DD"),
                        "end_date", Map.of("type", "string", "description", "结束日期 YYYY-MM-DD")
                ), List.of("start_date", "end_date")));

        return tools;
    }

    private ObjectNode buildTool(String name, String description,
                                  Map<String, Object> properties, List<String> required) {
        ObjectNode tool = objectMapper.createObjectNode();
        tool.put("type", "function");
        ObjectNode function = tool.putObject("function");
        function.put("name", name);
        function.put("description", description);
        ObjectNode params = function.putObject("parameters");
        params.put("type", "object");
        params.set("properties", objectMapper.valueToTree(properties));
        params.set("required", objectMapper.valueToTree(required));
        return tool;
    }

    private String buildSystemPrompt(Employee employee) {
        String now = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        return String.format(
                "你是一个智能考勤助手，只处理与考勤相关的操作和查询。\n" +
                "当前员工：%s（工号：%s）\n" +
                "当前时间：%s\n" +
                "当员工要打卡时，调用 do_check_in 工具；查询记录时，调用对应查询工具。\n" +
                "用简洁友好的中文回复，控制在100字以内。",
                employee.getName(), employee.getEmployeeNo(), now
        );
    }

    private List<Map<String, Object>> loadMessages(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }

    private String saveMessages(List<Map<String, Object>> messages) {
        try {
            return objectMapper.writeValueAsString(messages);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    private List<Map<String, Object>> trimMessages(List<Map<String, Object>> messages) {
        if (messages.size() <= maxHistoryTurns + 1) {
            return messages;
        }
        // 保留 system message + 最近 maxHistoryTurns 条
        List<Map<String, Object>> trimmed = new ArrayList<>();
        if (!messages.isEmpty() && "system".equals(messages.get(0).get("role"))) {
            trimmed.add(messages.get(0));
        }
        int start = Math.max(1, messages.size() - maxHistoryTurns);
        trimmed.addAll(messages.subList(start, messages.size()));
        return trimmed;
    }
}

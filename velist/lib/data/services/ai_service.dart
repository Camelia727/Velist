import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';

class ParsedTaskData {
  final String title;
  final DateTime? dueDate;
  final bool hasTime;
  final List<String> tags;

  ParsedTaskData({
    required this.title,
    this.dueDate,
    this.hasTime = false,
    this.tags = const [],
  });
}

class AIService {
  // DeepSeek API 配置
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const String _model = 'deepseek-chat'; // 使用 V3 模型

  Future<ParsedTaskData> parseTask(String input) async {
    // 1. 构造 Prompt
    final sysPrompt = '''
    你是一个任务解析助手。
    当前时间: ${DateTime.now().toIso8601String()}
    
    请提取任务信息并以纯 JSON 格式返回：
    {
      "title": "任务标题(去除时间/标签词)",
      "dueDate": "ISO8601时间字符串(如2025-12-05T15:00:00)或null",
      "hasTime": true/false(是否有具体时间点),
      "tags": ["中文标签"]
    }
    ''';

    try {
      // 2. 发起 HTTP 请求
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.deepseekApiKey}',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "system", "content": sysPrompt},
            {"role": "user", "content": input}
          ],
          // 强制 JSON 模式 (DeepSeek 特性)
          "response_format": {"type": "json_object"}, 
          "temperature": 0.1, // 低温度，更精准
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode} ${response.body}');
      }

      // 3. 解析结果
      // UTF8 解码防止中文乱码
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      final contentStr = data['choices'][0]['message']['content'] as String;

      // 这里的 contentStr 应该是一个干净的 JSON 字符串
      final json = jsonDecode(contentStr) as Map<String, dynamic>;

      print(json['title']);
      print(json['dueDate']);
      print(json['hasTime']);
      print(json['tags']);

      return ParsedTaskData(
        title: json['title'] ?? input,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        hasTime: json['hasTime'] ?? false,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );

    } catch (e) {
      if (kDebugMode) {
        print('AI Parse Error: $e');
      }
      // 失败降级
      return ParsedTaskData(title: input);
    }
  }
}
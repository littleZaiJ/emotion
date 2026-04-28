import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../constants/longcat_config.dart';

class AiVerdictResult {
  final double perfunctory; // 0~100 敷衍指数
  final double delusion; // 0~100 脑补浓度
  final double shatter; // 0~100 滤镜破碎度
  final String label; // 滤镜粉碎 / 开始裂痕 / 可疑上头
  final String diagnosis; // 一句话结论
  final double ciDelta; // -0.15~0.05

  const AiVerdictResult({
    required this.perfunctory,
    required this.delusion,
    required this.shatter,
    required this.label,
    required this.diagnosis,
    required this.ciDelta,
  });
}

class AiVerdictService {
  static Future<AiVerdictResult?> analyzeCrush({
    String? apiKey,
    required List<Uint8List> images,
    required String note,
  }) async {
    final key = (apiKey ?? kLongcatApiKey).trim();
    if (key.isEmpty) return null;
    if (images.isEmpty) return null;

    final content = <Map<String, Object?>>[
      {
        'type': 'text',
        'text': _buildPrompt(note: note, imageCount: images.length),
      },
      for (final img in images)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/png;base64,${base64Encode(img)}',
          },
        },
    ];

    try {
      final response = await http
          .post(
            Uri.parse(kLongcatChatCompletionsEndpoint),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': kLongcatCrushModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '你是一个“Crush 粉碎机”，任务是把聊天记录里的滤镜打碎，用毒舌但不恶意的方式输出结构化结论。',
                },
                {
                  'role': 'user',
                  'content': content,
                },
              ],
              'temperature': 0.4,
              'max_tokens': 800,
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] as String?;
      if (text == null || text.trim().isEmpty) return null;

      final jsonText = _extractJson(text.trim());
      if (jsonText == null) return null;

      final obj = jsonDecode(jsonText);
      if (obj is! Map) return null;

      double? readNum(String k) {
        final v = obj[k];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }

      String? readStr(String k) {
        final v = obj[k];
        return v is String ? v.trim() : null;
      }

      final perfunctory = readNum('perfunctory');
      final delusion = readNum('delusion');
      final shatter = readNum('shatter');
      final ciDelta = readNum('ciDelta');
      final label = readStr('label');
      final diagnosis = readStr('diagnosis');

      if (perfunctory == null ||
          delusion == null ||
          shatter == null ||
          ciDelta == null ||
          label == null ||
          diagnosis == null) {
        return null;
      }

      return AiVerdictResult(
        perfunctory: perfunctory.clamp(0.0, 100.0).toDouble(),
        delusion: delusion.clamp(0.0, 100.0).toDouble(),
        shatter: shatter.clamp(0.0, 100.0).toDouble(),
        label: label.isEmpty ? '可疑上头' : label,
        diagnosis: diagnosis,
        ciDelta: ciDelta.clamp(-0.15, 0.05).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _buildPrompt({required String note, required int imageCount}) {
    final safeNote = note.trim();
    return '''
请你根据我提供的聊天截图，生成一份“CRUSH 粉碎机报告”。

备注（可能为空）：${safeNote.isEmpty ? '（无）' : safeNote}
截图张数：$imageCount

你必须只输出一段 JSON（不要任何多余文字/Markdown），字段如下：
{
  "perfunctory": number,  // 0~100 敷衍指数
  "delusion": number,     // 0~100 脑补浓度
  "shatter": number,      // 0~100 滤镜破碎度
  "label": string,        // 只能是：滤镜粉碎 / 开始裂痕 / 可疑上头
  "diagnosis": string,    // 1~2 句、辛辣但不恶意
  "ciDelta": number       // 只能在 -0.15 ~ 0.05 之间，表示 CI 变化
}

要求：
- 指标要和聊天内容一致，不能凭空编。
- diagnosis 不超过 60 字。
''';
  }

  static String? _extractJson(String s) {
    // 模型偶尔会在 JSON 前后加点废话；这里尽量抓取第一段 {...}
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(s);
    return match?.group(0);
  }
}

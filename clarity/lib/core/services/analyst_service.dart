import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalystService {
  static const _model = 'LongCat-Flash-Chat';
  static const _endpoint = 'https://api.longcat.chat/openai/v1/chat/completions';

  /// 调用 LongCat API 生成一份股评风格的情感分析报告。
  /// 失败时返回 null，调用方应回退到规则报告。
  static Future<String?> generateAnalysis({
    required String apiKey,
    required double totalInvestment,
    required double totalReturn,
    required double roi,
    required double cpw,
    required int totalWords,
    required double deficit,
  }) async {
    if (apiKey.trim().isEmpty) return null;

    final prompt = '''你是一位辛辣毒舌的 A 股研报分析师，专门分析"情感关系"这支私募股权。
请根据以下财务数据，用 80 字以内写一段一针见血的分析，语气要像真正的券商研报：

总投入：¥${totalInvestment.toStringAsFixed(0)}
总回馈：¥${totalReturn.toStringAsFixed(0)}
ROI：${(roi * 100).toStringAsFixed(1)}%
单字成本（CPW）：${cpw > 0 ? '¥${cpw.toStringAsFixed(2)}/字' : '无回复数据'}
对方累计回复：$totalWords 字
情感赤字：${deficit >= 0 ? '+' : ''}¥${deficit.toStringAsFixed(0)}

要求：
• 用股市术语（多空、止损、割肉、底部、情绪价值等）
• 直白评价感情现状和对方"标的质量"
• 最后一行给出一个建议操作（买入 / 持有 / 减仓 / 清仓）
• 不超过 80 字，不要废话''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 300,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String?;
        return text?.trim();
      }
    } catch (_) {
      // Network error or timeout — fall back to rule-based
    }
    return null;
  }
}

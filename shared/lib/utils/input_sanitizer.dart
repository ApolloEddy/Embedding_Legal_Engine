/// 输入消毒工具
/// 
/// 用于清理用户输入，防止Prompt注入攻击。
class InputSanitizer {
  /// 清理用户输入，防止Prompt注入
  /// 
  /// 处理策略：
  /// 1. 移除潜在的指令覆盖尝试（中英文）
  /// 2. 移除可能被用于伪造输出的Markdown代码块
  /// 3. 移除可疑的JSON字面量（防止直接注入输出结构）
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    
    var cleaned = input;
    
    // 1. 移除潜在的指令覆盖尝试（中文）
    cleaned = cleaned.replaceAll(
      RegExp(r'忽略.{0,30}(指令|要求|规则|提示)', caseSensitive: false), 
      '[已过滤]'
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'不要.{0,20}(遵守|按照|听从)', caseSensitive: false), 
      '[已过滤]'
    );
    
    // 2. 移除潜在的指令覆盖尝试（英文）
    cleaned = cleaned.replaceAll(
      RegExp(r'ignore.{0,30}(instruction|rule|prompt|system)', caseSensitive: false), 
      '[filtered]'
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'disregard.{0,20}(above|previous|prior)', caseSensitive: false), 
      '[filtered]'
    );
    
    // 3. 移除Markdown代码块（可能被用于伪造输出）
    cleaned = cleaned.replaceAll(
      RegExp(r'```[\s\S]*?```'), 
      '[代码块已移除]'
    );
    
    // 4. 移除可疑的JSON结构（防止直接注入输出）
    // 仅移除包含slot_id关键词的JSON对象
    cleaned = cleaned.replaceAll(
      RegExp(r'\{[^{}]*"slot_id"[^{}]*\}', caseSensitive: false), 
      '[可疑结构已移除]'
    );
    
    // 5. 移除XML/HTML标签（防止标记注入）
    cleaned = cleaned.replaceAll(
      RegExp(r'<[^>]+>'), 
      ''
    );
    
    return cleaned.trim();
  }
  
  /// 检查输入是否包含可疑内容
  /// 
  /// 返回true表示输入可能包含注入尝试
  static bool containsSuspiciousContent(String input) {
    final suspiciousPatterns = [
      RegExp(r'忽略.{0,30}指令', caseSensitive: false),
      RegExp(r'ignore.{0,30}instruction', caseSensitive: false),
      RegExp(r'"slot_id"', caseSensitive: false),
      RegExp(r'```json', caseSensitive: false),
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }
}

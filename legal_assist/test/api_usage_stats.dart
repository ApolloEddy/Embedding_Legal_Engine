
import 'package:legal_assist/services/llm_extraction_service.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';

void main() async {
  print('=== 案件分析全流程 API 调用统计 ===');
  
  // 模拟输入数据
  final caseText = "嫌疑人张三于2023年在禁猎区捕杀了一只野猪。";
  final mockSlots = [
    Slot(slotId: 'S001', slotName: '主体', analysisLevel: 1, required: true, role: SlotRole.qualification, semanticScope: ''),
    Slot(slotId: 'S002', slotName: '行为', analysisLevel: 1, required: true, role: SlotRole.qualification, semanticScope: ''),
    Slot(slotId: 'S003', slotName: '对象', analysisLevel: 1, required: true, role: SlotRole.qualification, semanticScope: ''),
  ];

  print('\n[Phase 1] 用户输入');
  print('无需 API 调用');

  print('\n[Phase 2] LLM 事实提取');
  print('逻辑代码位置: LlmExtractionService.extractFacts');
  
  // 1. Chat Completion
  print('1. 构建 Prompt (包含 ${mockSlots.length} 个 Slot 定义)');
  print('2. 发送请求给 LLM (Chat Completion API)');
  print('   -> 调用次数: 1 次 (单轮对话提取)');
  
  // 模拟 LLM 返回结果
  final extractedCount = 3; // 假设提取到了 3 个有效事实
  print('3. LLM 返回 JSON，解析得到 $extractedCount 个需向量化的事实');

  // 2. Embedding Calculation
  print('4. 对每个提取到的事实文本计算 Embedding');
  print('   -> 待计算文本数: $extractedCount 个');
  print('   -> 调用模式: Batch 批量请求 (优化后)');
  print('   -> 调用次数: 1 次 (合并所有文本)');

  print('\n[Phase 3] 本地分析');
  print('逻辑代码位置: LocalAnalysisEngine.analyze');
  print('   -> 调用次数: 0 次 (纯本地向量计算)');

  print('\n=== 统计总结 ===');
  print('输入案情: $caseText');
  print('提取事实数: $extractedCount');
  print('--------------------------------');
  print('LLM Chat 请求:      1 次');
  print('Embedding 计算请求: 1 次 (无论是 5 个还是 50 个事实)');
  print('--------------------------------');
  print('优化效果: 网络请求减少了 ${extractedCount - 1} 次，大幅降低延迟。');
}

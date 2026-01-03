import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import '../providers/app_provider.dart';

/// 分析结果页面
class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '罪名分析结果',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  if (provider.analysisResult != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新分析'),
                      onPressed: () => provider.analyzeCase(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Phase 3 分析结果（100% 本地确定性算法，禁止调用 LLM）',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              // 分析信息
              if (provider.analysisResult != null)
                _buildAnalysisInfo(context, provider.analysisResult!),
              const SizedBox(height: 16),
              // 主要内容
              Expanded(
                child: provider.analysisResult == null
                    ? _buildEmptyState(context)
                    : _buildResults(context, provider.analysisResult!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisInfo(BuildContext context, AnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildInfoChip(context, 'YAML 版本', result.yamlVersion),
          const SizedBox(width: 16),
          _buildInfoChip(context, 'Embedding 版本', result.embeddingVersion),
          const SizedBox(width: 16),
          _buildInfoChip(context, '分析层级', '第 ${result.analysisLevel} 级'),
          const SizedBox(width: 16),
          _buildInfoChip(context, '相似度阈值', '${(result.similarityThreshold * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '尚无分析结果',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '请先在案情输入页面输入案件描述并执行分析',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, AnalysisResult result) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：罪名列表
        Expanded(
          flex: 1,
          child: _buildCrimeList(context, result),
        ),
        const SizedBox(width: 16),
        // 右侧：详细信息
        Expanded(
          flex: 2,
          child: _buildDetailPanel(context, result),
        ),
      ],
    );
  }

  Widget _buildCrimeList(BuildContext context, AnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list),
                const SizedBox(width: 8),
                Text('罪名列表', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: result.crimeResults.length,
                itemBuilder: (context, index) {
                  final crime = result.crimeResults[index];
                  return _buildCrimeListItem(context, crime);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeListItem(BuildContext context, CrimeAnalysisResult crime) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (crime.isConstituted == true) {
      statusColor = Colors.red;
      statusIcon = Icons.check_circle;
      statusText = '可能构成';
    } else if (crime.isConstituted == false) {
      statusColor = Colors.green;
      statusIcon = Icons.cancel;
      statusText = '不构成';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.help;
      statusText = '待定';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: statusColor.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(crime.crimeName),
        subtitle: Text(statusText),
        trailing: Text(
          '${(crime.overallScore * 100).toInt()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, AnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description),
                const SizedBox(width: 8),
                Text('详细分析', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: result.crimeResults.length,
                itemBuilder: (context, index) {
                  final crime = result.crimeResults[index];
                  return _buildCrimeDetail(context, crime);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeDetail(BuildContext context, CrimeAnalysisResult crime) {
    return ExpansionTile(
      leading: const Icon(Icons.gavel),
      title: Text(crime.crimeName),
      subtitle: Text('匹配度: ${(crime.overallScore * 100).toInt()}%'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 命中的必需要件
              _buildSlotSection(
                context,
                '命中的必需要件',
                crime.hitRequiredSlots,
                Colors.green,
                Icons.check_circle,
              ),
              const SizedBox(height: 12),
              // 缺失的必需要件
              _buildSlotSection(
                context,
                '缺失的必需要件',
                crime.missingRequiredSlots,
                Colors.red,
                Icons.cancel,
              ),
              const SizedBox(height: 12),
              // 命中的排除要件
              if (crime.hitExclusionSlots.isNotEmpty)
                _buildSlotSection(
                  context,
                  '命中的排除要件（阻却事由）',
                  crime.hitExclusionSlots,
                  Colors.blue,
                  Icons.shield,
                ),
              // 不确定要件
              if (crime.uncertainSlots.isNotEmpty)
                _buildSlotSection(
                  context,
                  '不确定要件',
                  crime.uncertainSlots,
                  Colors.orange,
                  Icons.help,
                ),
              const Divider(),
              // 解释文本
              Text(
                '分析说明',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  crime.explanationText ?? '无说明',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSection(
    BuildContext context,
    String title,
    List<SlotMatchResult> slots,
    Color color,
    IconData icon,
  ) {
    if (slots.isEmpty) {
      return Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$title: 无', style: TextStyle(color: color)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text('$title (${slots.length})', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ...slots.map((slot) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${slot.slotName} (${slot.slotId})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (slot.similarityScore != null)
                  Text(
                    '${(slot.similarityScore! * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

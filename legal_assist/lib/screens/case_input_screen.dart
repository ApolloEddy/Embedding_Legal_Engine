import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// 案情输入页面
class CaseInputScreen extends StatefulWidget {
  const CaseInputScreen({super.key});

  @override
  State<CaseInputScreen> createState() => _CaseInputScreenState();
}

class _CaseInputScreenState extends State<CaseInputScreen> {
  final _caseTextController = TextEditingController();
  
  /// 平板/桌面断点
  static const double _tabletBreakpoint = 768;

  @override
  void dispose() {
    _caseTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= _tabletBreakpoint;
    
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.all(isWide ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '案情输入',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (!isWide || provider.errorMessage != null || provider.successMessage != null) ...[
                  Text(
                    '请输入案件的自然语言描述，系统将自动提取结构化事实并进行罪名分析',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 16),
              ],

              // 消息提示
              if (provider.errorMessage != null)
                _buildMessageBar(context, provider.errorMessage!, Colors.red),
              if (provider.successMessage != null)
                _buildMessageBar(context, provider.successMessage!, Colors.green),
              if (provider.errorMessage != null || provider.successMessage != null)
                 const SizedBox(height: 16),

              // 检查资产加载状态
              if (provider.yamlBase == null || provider.embeddingPackage == null || provider.llmConfig == null) ...[
                _buildAssetWarning(context, provider),
                const SizedBox(height: 16),
              ],
              
              // 核心布局
              Expanded(
                child: isWide 
                  ? _buildWideLayout(context, provider)
                  : _buildMobileLayout(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(BuildContext context, AppProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch, // 关键：拉伸高度使得左右等高
      children: [
        // 左侧：输入区
        Expanded(
          flex: 2,
          child: _buildInputAreaWide(context, provider),
        ),
        const SizedBox(width: 16),
        // 右侧：提取结果预览
        Expanded(
          flex: 1,
          child: _buildExtractionPreviewWide(context, provider),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 上部：输入区 (使用 ExpansionTile)
          _buildInputAreaMobile(context, provider),
          const SizedBox(height: 12),
          // 下部：提取结果预览 (使用 ExpansionTile)
          _buildExtractionPreviewMobile(context, provider),
        ],
      ),
    );
  }

  // ... [MessageBar and Warning Helpers remain same, omitted here but assumed present in file context if I could partial replace. 
  // Since I am replacing the whole class content or large chunks, I must include helper methods to avoid deletion]
  // Wait, I should use partial replacements or include everything. 
  // Given user wants "Full height", replacing the whole build logic is safer.
  
  Widget _buildMessageBar(BuildContext context, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.red ? Icons.error : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context.read<AppProvider>().clearMessages(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetWarning(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '请先在设置页面加载必要资产',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.yamlBase == null
                      ? '• YAML 基座未加载'
                      : '✓ YAML 基座已加载',
                ),
                Text(
                  provider.embeddingPackage == null
                      ? '• Embedding 包未加载'
                      : '✓ Embedding 包已加载',
                ),
                Text(
                  provider.llmConfig == null
                      ? '• LLM 未配置'
                      : '✓ LLM 已配置',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 桌面/Web 宽屏输入区：全高度，无 ExpansionTile
  Widget _buildInputAreaWide(BuildContext context, AppProvider provider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit_document),
                const SizedBox(width: 8),
                Text('案情描述', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (provider.caseText.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('清空'),
                    onPressed: () {
                      _caseTextController.clear();
                      provider.resetAnalysis();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Text Field (Expanded to fill space)
            Expanded(
              child: TextField(
                controller: _caseTextController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: '请输入案件描述...\n\n例如：\n2023年5月15日晚，被告人张某在某小区门口与被害人李某发生口角，后张某持刀将李某刺伤，致李某当场死亡。案发后，张某主动到公安机关投案，并如实供述了犯罪事实。',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => provider.setCaseText(value),
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _canExtract(provider)
                        ? () => provider.extractFacts()
                        : null,
                    icon: provider.isLoading && provider.currentPhase == 2
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: const Text('Phase 2: 提取事实'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: provider.caseExtraction != null
                        ? () => provider.analyzeCase()
                        : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Phase 3: 分析罪名'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 移动端输入区：保持 ExpansionTile 和自适应高度
  Widget _buildInputAreaMobile(BuildContext context, AppProvider provider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Icon(Icons.edit_document),
            const SizedBox(width: 8),
            Text('案情描述', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        trailing: provider.caseText.isNotEmpty 
          ? TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('清空'),
              onPressed: () {
                _caseTextController.clear();
                provider.resetAnalysis();
              },
            )
          : null,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 200,
            child: TextField(
              controller: _caseTextController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '请输入案件描述...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => provider.setCaseText(value),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _canExtract(provider)
                    ? () => provider.extractFacts()
                    : null,
                icon: provider.isLoading && provider.currentPhase == 2
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Phase 2: 提取事实'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: provider.caseExtraction != null
                    ? () => provider.analyzeCase()
                    : null,
                icon: const Icon(Icons.analytics),
                label: const Text('Phase 3: 分析罪名'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 桌面/Web 宽屏结果预览：全高度，无 ExpansionTile
  Widget _buildExtractionPreviewWide(BuildContext context, AppProvider provider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check),
                const SizedBox(width: 8),
                Text('提取结果', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (provider.caseExtraction == null)
              const Expanded(
                child: Center(
                  child: Text('尚未提取事实'),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: _buildExtractionListItems(context, provider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 移动端结果预览：ExpansionTile
  Widget _buildExtractionPreviewMobile(BuildContext context, AppProvider provider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Icon(Icons.fact_check),
            const SizedBox(width: 8),
            Text('提取结果', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        childrenPadding: const EdgeInsets.all(0),
        children: [
          if (provider.caseExtraction == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('尚未提取事实'),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _buildExtractionListItems(context, provider),
              ),
            )
        ],
      ),
    );
  }

  List<Widget> _buildExtractionListItems(BuildContext context, AppProvider provider) {
    return [
      Text(
        '提取的要素 (${provider.caseExtraction!.extractedSlotIds.length})',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      ...provider.caseExtraction!.slotExtractions.map((e) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            e.hasContent ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: e.hasContent ? Colors.green : Colors.grey,
          ),
          title: Text(e.slotId),
          subtitle: e.slotText != null
              ? Text(
                  e.slotText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                )
              : const Text('未提取到', style: TextStyle(fontSize: 11)),
          trailing: e.confidence != null
              ? Text('${(e.confidence! * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11))
              : null,
        );
      }),
      const Divider(),
      if (provider.caseExtraction!.involvedPersons != null &&
          provider.caseExtraction!.involvedPersons!.isNotEmpty) ...[
        Text(
          '涉案人员 (${provider.caseExtraction!.involvedPersons!.length})',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...provider.caseExtraction!.involvedPersons!.map((p) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person, size: 18),
            title: Text(p.name),
            subtitle: p.role != null ? Text(p.role!) : null,
          );
        }),
      ],
    ];
  }

  bool _canExtract(AppProvider provider) {
    return provider.yamlBase != null &&
        provider.llmConfig != null &&
        provider.caseText.isNotEmpty &&
        !provider.isLoading;
  }
}

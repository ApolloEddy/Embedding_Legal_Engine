import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import '../utils/file_exporter.dart';
import '../providers/app_provider.dart';
import '../widgets/mind_map_view.dart';

/// 分析结果页面 - 支持列表视图和思维导图视图
class AnalysisResultScreen extends StatefulWidget {
  const AnalysisResultScreen({super.key});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  /// 视图模式：true = 思维导图，false = 列表（默认列表视图）
  bool _isMindMapMode = false;
  
  /// 思维导图的 GlobalKey，用于导出
  final GlobalKey<MindMapViewState> _mindMapKey = GlobalKey();
  
  /// 是否正在导出
  bool _isExporting = false;

  /// 平板/桌面断点
  static const double _tabletBreakpoint = 768;

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
              // 标题栏
              // 标题栏
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '罪名分析结果',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 视图切换按钮
                    if (provider.tieredResult != null) ...[
                      _buildViewToggle(),
                      const SizedBox(width: 8),
                      // 导出按钮（仅思维导图模式显示）
                      if (_isMindMapMode)
                        IconButton(
                          icon: _isExporting 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          tooltip: '导出为 PNG',
                          onPressed: _isExporting ? null : () => _exportMindMap(context),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新分析'),
                        onPressed: () => provider.analyzeCase(),
                      ),
                    ],
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '罪名分析结果',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    // 移动端操作栏
                    if (provider.tieredResult != null)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildViewToggle(),
                            const SizedBox(width: 8),
                            if (_isMindMapMode)
                              IconButton.filledTonal(
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.download, size: 20),
                                onPressed: _isExporting ? null : () => _exportMindMap(context),
                              ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('重分析'),
                              onPressed: () => provider.analyzeCase(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              if (isWide)
                Text(
                  '自适应分层分析结果（L1核心要件 → L2阻却事由 → L3量刑情节）',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              const SizedBox(height: 16),
              // 分析信息
              if (provider.tieredResult != null)
                _buildAnalysisInfo(context, provider.tieredResult!, isWide),
              const SizedBox(height: 16),
              // 主要内容
              Expanded(
                child: provider.tieredResult == null
                    ? _buildEmptyState(context)
                    : _isMindMapMode
                        ? _buildMindMapView(context, provider.tieredResult!)
                        : _buildListView(context, provider.tieredResult!, isWide),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 视图切换按钮
  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.account_tree,
            label: '导图',
            isSelected: _isMindMapMode,
            onTap: () => setState(() => _isMindMapMode = true),
          ),
          _buildToggleButton(
            icon: Icons.list,
            label: '列表',
            isSelected: !_isMindMapMode,
            onTap: () => setState(() => _isMindMapMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 导出思维导图为 PNG
  Future<void> _exportMindMap(BuildContext context) async {
    setState(() => _isExporting = true);
    
    try {
      // 获取 MindMapView 的 State
      final mindMapState = _mindMapKey.currentState;
      if (mindMapState == null) {
        throw Exception('思维导图未加载');
      }
      
      final pngBytes = await mindMapState.exportToPng();
      if (pngBytes == null) {
        throw Exception('导出失败');
      }
      
      // 导出图片
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'crime_analysis_$timestamp.png';
      
      final filePath = await FileExporter.exportImage(pngBytes, filename);
      
      if (context.mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已导出: $filePath'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () {
                  FileExporter.openFile(filePath);
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// 构建MindMapView with Key
  Widget _buildMindMapView(BuildContext context, TieredAnalysisResult result) {
    final rootNode = _buildMindMapTree(result);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < _tabletBreakpoint;
    
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            MindMapView(
              key: _mindMapKey,
              rootNode: rootNode,
              // 手机端使用更小的节点尺寸
              nodeWidth: isMobile ? 120 : 160,
              nodeHeight: isMobile ? 45 : 55,
              horizontalSpacing: isMobile ? 20 : 30,
              verticalSpacing: isMobile ? 50 : 70,
              onNodeTap: (node) {
                if (node.metadata != null && node.metadata!['crime'] != null) {
                  _showCrimeDetails(context, node.metadata!['crime'] as TieredCrimeAnalysis);
                }
              },
            ),
            // 手机端显示缩放提示
            if (isMobile)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('双指缩放', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 将分析结果转换为思维导图树
  MindMapNode _buildMindMapTree(TieredAnalysisResult result) {
    // 根节点
    final rootNode = MindMapNode(
      id: 'root',
      title: '案情分析',
      subtitle: '${result.crimeAnalyses.length} 个罪名',
      color: Colors.blue.shade700,
      backgroundColor: Colors.blue.shade50,
      icon: Icons.gavel,
      children: result.crimeAnalyses.map((crime) => _buildCrimeNode(crime)).toList(),
    );

    return rootNode;
  }

  /// 构建单个罪名节点
  MindMapNode _buildCrimeNode(TieredCrimeAnalysis crime) {
    final (color, bgColor, conclusionText) = _getConclusionStyle(crime.finalConclusion);

    final children = <MindMapNode>[
      // L1 核心要件
      MindMapNode(
        id: '${crime.crimeId}_L1',
        title: 'L1 核心要件',
        subtitle: crime.coreElements.isPreliminaryConstituted ? '✓ 满足' : '✗ 不满足',
        color: crime.coreElements.isPreliminaryConstituted ? Colors.green.shade700 : Colors.red.shade700,
        backgroundColor: crime.coreElements.isPreliminaryConstituted ? Colors.green.shade50 : Colors.red.shade50,
        icon: Icons.check_circle_outline,
        children: [
          if (crime.coreElements.hitSlots.isNotEmpty)
            MindMapNode(
              id: '${crime.crimeId}_L1_hit',
              title: '命中 ${crime.coreElements.hitSlots.length}',
              subtitle: crime.coreElements.hitSlots.map((s) => s.slotName).join('、'),
              color: Colors.green.shade600,
              backgroundColor: Colors.green.shade50,
            ),
          if (crime.coreElements.missingSlots.isNotEmpty)
            MindMapNode(
              id: '${crime.crimeId}_L1_miss',
              title: '缺失 ${crime.coreElements.missingSlots.length}',
              subtitle: crime.coreElements.missingSlots.map((s) => s.slotName).join('、'),
              color: Colors.red.shade600,
              backgroundColor: Colors.red.shade50,
            ),
        ],
      ),
    ];

    // L2 阻却事由
    if (crime.exclusionAnalysis != null) {
      children.add(MindMapNode(
        id: '${crime.crimeId}_L2',
        title: 'L2 阻却事由',
        subtitle: crime.exclusionAnalysis!.isExcluded ? '⚠ 存在排除' : '✓ 无排除',
        color: crime.exclusionAnalysis!.isExcluded ? Colors.orange.shade700 : Colors.green.shade700,
        backgroundColor: crime.exclusionAnalysis!.isExcluded ? Colors.orange.shade50 : Colors.green.shade50,
        icon: Icons.shield,
      ));
    }

    // L3 量刑情节
    if (crime.sentencingAnalysis != null) {
      final sentencing = crime.sentencingAnalysis!;
      children.add(MindMapNode(
        id: '${crime.crimeId}_L3',
        title: 'L3 量刑情节',
        subtitle: _sentencingLevelText(sentencing.sentencingLevel),
        color: _getSentencingColor(sentencing.sentencingLevel),
        backgroundColor: _getSentencingColor(sentencing.sentencingLevel).withValues(alpha: 0.1),
        icon: Icons.balance,
        children: [
          if (sentencing.aggravatingFactors.isNotEmpty)
            MindMapNode(
              id: '${crime.crimeId}_L3_agg',
              title: '加重 ${sentencing.aggravatingFactors.length}',
              subtitle: sentencing.aggravatingFactors.map((s) => s.slotName).join('、'),
              color: Colors.red.shade600,
              backgroundColor: Colors.red.shade50,
              icon: Icons.arrow_upward,
            ),
          if (sentencing.mitigatingFactors.isNotEmpty)
            MindMapNode(
              id: '${crime.crimeId}_L3_mit',
              title: '减轻 ${sentencing.mitigatingFactors.length}',
              subtitle: sentencing.mitigatingFactors.map((s) => s.slotName).join('、'),
              color: Colors.green.shade600,
              backgroundColor: Colors.green.shade50,
              icon: Icons.arrow_downward,
            ),
        ],
      ));
    }

    return MindMapNode(
      id: crime.crimeId,
      title: crime.crimeName,
      subtitle: conclusionText,
      color: color,
      backgroundColor: bgColor,
      icon: _getConclusionIcon(crime.finalConclusion),
      children: children,
      metadata: {'crime': crime},
    );
  }

  (Color, Color, String) _getConclusionStyle(CrimeConclusion conclusion) {
    switch (conclusion) {
      case CrimeConclusion.notConstitutedMissingElements:
        return (Colors.grey.shade600, Colors.grey.shade100, '不构成');
      case CrimeConclusion.notConstitutedExcluded:
        return (Colors.green.shade600, Colors.green.shade50, '排除');
      case CrimeConclusion.constitutedMinor:
        return (Colors.orange.shade600, Colors.orange.shade50, '轻微');
      case CrimeConclusion.constitutedNormal:
        return (Colors.deepOrange.shade600, Colors.deepOrange.shade50, '一般');
      case CrimeConclusion.constitutedSerious:
        return (Colors.red.shade600, Colors.red.shade50, '严重');
      case CrimeConclusion.constitutedVerySevere:
        return (Colors.red.shade900, Colors.red.shade100, '特别严重');
      case CrimeConclusion.uncertain:
        return (Colors.amber.shade600, Colors.amber.shade50, '待定');
    }
  }

  IconData _getConclusionIcon(CrimeConclusion conclusion) {
    switch (conclusion) {
      case CrimeConclusion.notConstitutedMissingElements:
        return Icons.cancel_outlined;
      case CrimeConclusion.notConstitutedExcluded:
        return Icons.shield_outlined;
      case CrimeConclusion.constitutedMinor:
      case CrimeConclusion.constitutedNormal:
        return Icons.warning_amber;
      case CrimeConclusion.constitutedSerious:
      case CrimeConclusion.constitutedVerySevere:
        return Icons.dangerous;
      case CrimeConclusion.uncertain:
        return Icons.help_outline;
    }
  }

  Color _getSentencingColor(SentencingLevel level) {
    switch (level) {
      case SentencingLevel.minor:
        return Colors.green.shade600;
      case SentencingLevel.normal:
        return Colors.orange.shade600;
      case SentencingLevel.serious:
        return Colors.red.shade600;
      case SentencingLevel.verySevere:
        return Colors.red.shade900;
    }
  }

  void _showCrimeDetails(BuildContext context, TieredCrimeAnalysis crime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                crime.crimeName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _buildConclusionBadge(crime.finalConclusion),
              const SizedBox(height: 24),
              Text(
                '详细分析',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(crime.explanationText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== 列表视图相关方法 ==========

  Widget _buildAnalysisInfo(BuildContext context, TieredAnalysisResult result, bool isWide) {
    if (!isWide) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoChip(context, '分析模式', '自适应'),
            _buildInfoChip(context, '阈值', '${(result.similarityThreshold * 100).toInt()}%'),
          ],
        ),
      );
    }

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
          _buildInfoChip(context, '分析模式', '自适应分层'),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, TieredAnalysisResult result, bool isWide) {
    return ListView.builder(
      itemCount: result.crimeAnalyses.length,
      itemBuilder: (context, index) {
        final crime = result.crimeAnalyses[index];
        return _buildTieredCrimeCard(context, crime, isWide);
      },
    );
  }

  Widget _buildTieredCrimeCard(BuildContext context, TieredCrimeAnalysis crime, bool isWide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildConclusionIcon(crime.finalConclusion),
        title: Row(
          children: [
            Expanded(child: Text(crime.crimeName)),
            _buildConclusionBadge(crime.finalConclusion),
          ],
        ),
        subtitle: Text(
          '匹配度: ${(crime.overallScore * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLevelSection(
                  context,
                  level: 1,
                  title: '核心构成要件',
                  icon: Icons.gavel,
                  color: Colors.blue,
                  content: _buildCoreElementsContent(context, crime.coreElements),
                ),
                const SizedBox(height: 12),
                if (crime.exclusionAnalysis != null)
                  _buildLevelSection(
                    context,
                    level: 2,
                    title: '排除阻却事由',
                    icon: Icons.shield,
                    color: crime.exclusionAnalysis!.isExcluded ? Colors.red : Colors.green,
                    content: _buildExclusionContent(context, crime.exclusionAnalysis!),
                  ),
                if (crime.exclusionAnalysis != null) const SizedBox(height: 12),
                if (crime.sentencingAnalysis != null)
                  _buildLevelSection(
                    context,
                    level: 3,
                    title: '量刑情节',
                    icon: Icons.balance,
                    color: Colors.orange,
                    content: _buildSentencingContent(context, crime.sentencingAnalysis!),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    crime.explanationText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(
    BuildContext context, {
    required int level,
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'L$level',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildCoreElementsContent(BuildContext context, CoreElementsResult core) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (core.hitSlots.isNotEmpty)
          _buildSlotList(context, '✓ 命中要件', core.hitSlots, Colors.green),
        if (core.missingSlots.isNotEmpty)
          _buildSlotList(context, '✗ 缺失要件', core.missingSlots, Colors.red),
        if (core.uncertainSlots.isNotEmpty)
          _buildSlotList(context, '? 不确定', core.uncertainSlots, Colors.orange),
        const SizedBox(height: 4),
        Text(
          '初步判定: ${core.isPreliminaryConstituted ? "可能构成" : "不满足"}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: core.isPreliminaryConstituted ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildExclusionContent(BuildContext context, ExclusionResult exclusion) {
    if (exclusion.hitExclusions.isEmpty) {
      return const Text('未发现排除事由', style: TextStyle(color: Colors.green));
    }
    return _buildSlotList(context, '⚠ 存在排除事由', exclusion.hitExclusions, Colors.red);
  }

  Widget _buildSentencingContent(BuildContext context, SentencingResult sentencing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sentencing.aggravatingFactors.isNotEmpty)
          _buildSlotList(context, '↑ 加重情节', sentencing.aggravatingFactors, Colors.red),
        if (sentencing.mitigatingFactors.isNotEmpty)
          _buildSlotList(context, '↓ 减轻情节', sentencing.mitigatingFactors, Colors.green),
        if (sentencing.aggravatingFactors.isEmpty && sentencing.mitigatingFactors.isEmpty)
          const Text('无特殊情节', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '量刑等级: ${_sentencingLevelText(sentencing.sentencingLevel)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSlotList(BuildContext context, String title, List<SlotMatchResult> slots, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$title: ', style: TextStyle(fontSize: 12, color: color)),
          ...slots.map((s) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text(s.slotName, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConclusionIcon(CrimeConclusion conclusion) {
    final (icon, color) = switch (conclusion) {
      CrimeConclusion.notConstitutedMissingElements => (Icons.cancel, Colors.grey),
      CrimeConclusion.notConstitutedExcluded => (Icons.shield, Colors.green),
      CrimeConclusion.constitutedMinor => (Icons.warning, Colors.orange),
      CrimeConclusion.constitutedNormal => (Icons.warning, Colors.deepOrange),
      CrimeConclusion.constitutedSerious => (Icons.dangerous, Colors.red),
      CrimeConclusion.constitutedVerySevere => (Icons.dangerous, Colors.red.shade900),
      CrimeConclusion.uncertain => (Icons.help, Colors.amber),
    };
    return Icon(icon, color: color);
  }

  Widget _buildConclusionBadge(CrimeConclusion conclusion) {
    final (color, text) = switch (conclusion) {
      CrimeConclusion.notConstitutedMissingElements => (Colors.grey, '不构成'),
      CrimeConclusion.notConstitutedExcluded => (Colors.green, '排除'),
      CrimeConclusion.constitutedMinor => (Colors.orange, '轻微'),
      CrimeConclusion.constitutedNormal => (Colors.deepOrange, '一般'),
      CrimeConclusion.constitutedSerious => (Colors.red, '严重'),
      CrimeConclusion.constitutedVerySevere => (Colors.red.shade900, '特别严重'),
      CrimeConclusion.uncertain => (Colors.amber, '待定'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _sentencingLevelText(SentencingLevel level) {
    switch (level) {
      case SentencingLevel.minor:
        return '情节轻微';
      case SentencingLevel.normal:
        return '一般情节';
      case SentencingLevel.serious:
        return '情节严重';
      case SentencingLevel.verySevere:
        return '情节特别严重';
    }
  }
}

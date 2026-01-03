import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';

/// Embedding 计算页面
class EmbeddingScreen extends StatelessWidget {
  const EmbeddingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Embedding 计算',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '根据 YAML 基座定义的 Slot 结构，调用 LLM 计算法律条文的 Embedding 向量',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 24),
              // 消息提示
              if (provider.errorMessage != null)
                _buildMessageBar(context, provider.errorMessage!, Colors.red),
              if (provider.successMessage != null)
                _buildMessageBar(context, provider.successMessage!, Colors.green),
              const SizedBox(height: 16),
              // 主内容
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：步骤
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildStepCard(
                              context,
                              step: 1,
                              title: 'YAML 基座',
                              description: provider.yamlBase == null
                                  ? '请先在 YAML 编辑页面加载或创建基座'
                                  : '已加载 ${provider.yamlBase!.slots.length} 个 Slot，${provider.yamlBase!.crimes.length} 个罪名',
                              isComplete: provider.yamlBase != null,
                              child: null,
                            ),
                            _buildStepCard(
                              context,
                              step: 2,
                              title: 'LLM 配置',
                              description: provider.llmConfig == null
                                  ? '请在设置页面配置 LLM API'
                                  : '模型: ${provider.llmConfig!.embeddingModel}',
                              isComplete: provider.llmConfig != null,
                              child: null,
                            ),
                            _buildStepCard(
                              context,
                              step: 3,
                              title: '法律条文',
                              description: '已加载 ${provider.articles.length} 个条文文件',
                              isComplete: provider.articles.isNotEmpty,
                              child: OutlinedButton.icon(
                                onPressed: () => _loadArticles(context, provider),
                                icon: const Icon(Icons.folder_open),
                                label: const Text('选择条文目录'),
                              ),
                            ),
                            _buildStepCard(
                              context,
                              step: 4,
                              title: '计算 Embedding',
                              description: provider.embeddingPackage == null
                                  ? '点击下方按钮开始计算'
                                  : '已完成 ${provider.embeddingPackage!.embeddings.length} 个 Embedding',
                              isComplete: provider.embeddingPackage != null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (provider.isLoading && provider.embeddingTotal > 0)
                                    _buildProgressIndicator(provider),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: _canCompute(provider)
                                        ? () => provider.computeEmbeddings()
                                        : null,
                                    icon: provider.isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.play_arrow),
                                    label: Text(provider.isLoading ? '计算中...' : '开始计算'),
                                  ),
                                ],
                              ),
                            ),
                            _buildStepCard(
                              context,
                              step: 5,
                              title: '导出 Embedding 包',
                              description: '将计算结果导出为只读资产文件',
                              isComplete: false,
                              child: OutlinedButton.icon(
                                onPressed: provider.embeddingPackage != null
                                    ? () => _exportPackage(context, provider)
                                    : null,
                                icon: const Icon(Icons.download),
                                label: const Text('导出 .pak 文件'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 右侧：预览
                    Expanded(
                      flex: 1,
                      child: _buildPreviewCard(context, provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildStepCard(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    required bool isComplete,
    required Widget? child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isComplete
                    ? Colors.green
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text('$step'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 12),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AppProvider provider) {
    final progress = provider.embeddingTotal > 0
        ? provider.embeddingProgress / provider.embeddingTotal
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text(
          '${provider.embeddingProgress}/${provider.embeddingTotal} - ${provider.embeddingStatus}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview),
                const SizedBox(width: 8),
                Text('Embedding 预览',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (provider.embeddingPackage == null)
              const Expanded(
                child: Center(
                  child: Text('尚无 Embedding 数据'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.embeddingPackage!.embeddings.length,
                  itemBuilder: (context, index) {
                    final embedding = provider.embeddingPackage!.embeddings[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.memory, size: 18),
                      title: Text(embedding.slotId),
                      subtitle: Text(
                        '维度: ${embedding.dimension}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canCompute(AppProvider provider) {
    return provider.yamlBase != null &&
        provider.llmConfig != null &&
        !provider.isLoading;
  }

  Future<void> _loadArticles(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择法律条文目录',
    );

    if (result != null) {
      await provider.loadArticlesFromDirectory(result);
    }
  }

  Future<void> _exportPackage(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出 Embedding 包',
      fileName: 'embeddings_${DateTime.now().millisecondsSinceEpoch}.pak',
      type: FileType.any,
    );

    if (result != null) {
      await provider.exportEmbeddingPackage(result);
    }
  }
}

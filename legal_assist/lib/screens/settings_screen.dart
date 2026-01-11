import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/llm_extraction_service.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedProvider = 'aliyun';
  String _selectedModel = 'text-embedding-v4';
  int _dimension = 1024;

  final Map<String, List<Map<String, dynamic>>> _providerModels = {
    'aliyun': [
      {'name': 'text-embedding-v4', 'dimension': 1024},
      {'name': 'text-embedding-v3', 'dimension': 1024},
      {'name': 'text-embedding-v2', 'dimension': 1536},
    ],
    'openai': [
      {'name': 'text-embedding-3-small', 'dimension': 1536},
      {'name': 'text-embedding-3-large', 'dimension': 3072},
      {'name': 'text-embedding-ada-002', 'dimension': 1536},
    ],
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('设置', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                // 消息提示
                if (provider.errorMessage != null || provider.successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildMessageSection(context, provider),
                  ),
                // 资产加载
                _buildAssetLoaderCard(context, provider),
                const SizedBox(height: 16),
                // LLM 配置
                _buildLlmConfigCard(context, provider),
                const SizedBox(height: 16),
                // 分析配置
                _buildAnalysisConfigCard(context, provider),
                const SizedBox(height: 16),
                // 关于
                _buildAboutCard(context),
                const SizedBox(height: 16),
                _buildCacheControlCard(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageSection(BuildContext context, AppProvider provider) {
    final isError = provider.errorMessage != null;
    final message = isError ? provider.errorMessage! : provider.successMessage!;
    final color = isError ? Colors.red : Colors.green;

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
            isError ? Icons.error : Icons.check_circle,
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

  Widget _buildAssetLoaderCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder),
                const SizedBox(width: 8),
                Text('资产加载', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            // YAML 基座
            _buildAssetItem(
              context: context,
              title: 'YAML 基座',
              subtitle: provider.yamlPath ?? '未加载',
              isLoaded: provider.yamlBase != null,
              onPressed: () => _loadYaml(context, provider),
            ),
            const Divider(height: 1),
            // Embedding 包
            _buildAssetItem(
              context: context,
              title: 'Embedding 包',
              subtitle: provider.embeddingPath ?? '未加载',
              isLoaded: provider.embeddingPackage != null,
              onPressed: () => _loadEmbedding(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isLoaded,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLoaded ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isLoaded ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: double.infinity, // Mobile friendly full width button
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.file_open, size: 18),
                label: const Text('选择文件'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLlmConfigCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud),
                const SizedBox(width: 8),
                Text('LLM 配置（仅用于 Phase 2 提取）',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            // 配置来源提示
            if (provider.configSource != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '配置来源: ${provider.configSource}',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            // 提供商选择
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'API 提供商',
                prefixIcon: Icon(Icons.business),
              ),
              items: const [
                DropdownMenuItem(value: 'aliyun', child: Text('阿里云 DashScope')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProvider = value!;
                  final models = _providerModels[value]!;
                  _selectedModel = models[0]['name'] as String;
                  _dimension = models[0]['dimension'] as int;
                });
              },
            ),
            const SizedBox(height: 16),
            // 模型选择
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Embedding 模型 (需与 Program A 一致)',
                prefixIcon: Icon(Icons.memory),
              ),
              items: _providerModels[_selectedProvider]!.map((model) {
                return DropdownMenuItem(
                  value: model['name'] as String,
                  child: Text('${model['name']} (${model['dimension']}维)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                  _dimension = _providerModels[_selectedProvider]!
                      .firstWhere((m) => m['name'] == value)['dimension'] as int;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (provider.llmConfig != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已配置: ${provider.llmConfig!.embeddingModel} (${provider.llmConfig!.embeddingDimension}维)',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _apiKeyController.text.isNotEmpty
                  ? () => _saveLlmConfig(provider)
                  : null,
              icon: const Icon(Icons.save),
              label: const Text('保存配置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisConfigCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 8),
                Text('分析配置', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            // 分析层级
            // 自适应分层分析说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '采用自适应分层分析：系统自动执行 L1核心要件 → L2阻却事由 → L3量刑情节 的全量分析',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 相似度阈值
            ListTile(
              title: Text('相似度阈值: ${(provider.similarityThreshold * 100).toInt()}%'),
              subtitle: Slider(
                value: provider.similarityThreshold,
                min: 0.3,
                max: 0.9,
                divisions: 12,
                label: '${(provider.similarityThreshold * 100).toInt()}%',
                onChanged: (v) => provider.setSimilarityThreshold(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text('关于程序 B', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            const Text('法律案件分析主程序'),
            const SizedBox(height: 8),
            const Text('功能：'),
            const Text('1. 加载 YAML 基座和 Embedding 包'),
            const Text('2. 接收用户输入案情'),
            const Text('3. Phase 2: 调用 LLM 提取案件事实'),
            const Text('4. Phase 3: 本地执行罪名分析'),
            const Text('5. 渲染解释性结果到 UI'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phase 3 是 100% 本地确定性算法，禁止调用 LLM',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheControlCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.red),
                const SizedBox(width: 8),
                Text('重置与清除', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('清除应用程序配置将重置所有自动保存的路径和 Setting，需要重新加载。'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清除'),
                    content: const Text('确定要清除所有配置和缓存吗？此操作不可撤销。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                      TextButton(
                        onPressed: () async {
                          await provider.clearAllState();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('所有配置已清除')),
                            );
                          }
                        },
                        child: const Text('清除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.red,
              ),
              icon: const Icon(Icons.delete),
              label: const Text('清除所有配置'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadYaml(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null) {
      await provider.loadYamlBase(result.files.single);
    }
  }

  Future<void> _loadEmbedding(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null) {
      await provider.loadEmbeddingPackage(result.files.single);
    }
  }

  void _saveLlmConfig(AppProvider provider) {
    LlmConfig config;
    if (_selectedProvider == 'aliyun') {
      config = LlmConfig.aliyunDashScope(
        apiKey: _apiKeyController.text,
        model: _selectedModel,
        dimension: _dimension,
      );
    } else {
      config = LlmConfig.openAI(
        apiKey: _apiKeyController.text,
        model: _selectedModel,
        dimension: _dimension,
      );
    }
    provider.configureLlm(config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LLM 配置已保存'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

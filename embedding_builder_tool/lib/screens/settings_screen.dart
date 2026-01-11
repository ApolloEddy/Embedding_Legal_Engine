import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/llm_service.dart';

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
                Text(
                  '设置',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                // LLM 配置卡片
                _buildLlmConfigCard(context, provider),
                const SizedBox(height: 16),
                // 关于卡片
                const SizedBox(height: 16),
                // 关于卡片
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
                Text('LLM Embedding 配置',
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
            const SizedBox(height: 8),
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
                labelText: 'Embedding 模型',
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
            // API Key
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                prefixIcon: Icon(Icons.key),
                hintText: '请输入您的 API Key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            // 当前配置状态
            if (provider.llmConfig != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '当前配置: ${provider.llmConfig!.embeddingModel} (${provider.llmConfig!.embeddingDimension}维)',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // 保存按钮
            FilledButton.icon(
              onPressed: _apiKeyController.text.isNotEmpty
                  ? () => _saveConfig(provider)
                  : null,
              icon: const Icon(Icons.save),
              label: const Text('保存配置'),
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
                Text('关于程序 A',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('法律 Embedding 离线工具'),
            const SizedBox(height: 8),
            Text(
              '职责范围（不可扩展）：',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            const Text('1. 维护与编辑 YAML 基座文件'),
            const Text('2. 按 YAML 中定义的 Slot 结构，对法律条文逐条调用 LLM 计算 Embedding'),
            const Text('3. 导出只读的法律 Embedding 包'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '程序 A 禁止：解析案件事实、进行罪名分析、调用任何裁决或推理逻辑',
                      style: TextStyle(color: Colors.red),
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
                Text('缓存控制', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('清除应用程序缓存将重置所有配置（API Key、路径等），需要重新加载。'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清除'),
                    content: const Text('确定要清除所有缓存和配置吗？此操作不可撤销。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                      TextButton(
                        onPressed: () {
                          provider.clearCache();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('缓存已清除')),
                          );
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
              label: const Text('清除所有缓存'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfig(AppProvider provider) {
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

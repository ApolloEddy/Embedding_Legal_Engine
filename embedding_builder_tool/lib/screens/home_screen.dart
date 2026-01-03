import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'yaml_editor_screen.dart';
import 'embedding_screen.dart';
import 'settings_screen.dart';

/// 主页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    YamlEditorScreen(),
    EmbeddingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边导航栏
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gavel,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '离线工具',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: Text('YAML 编辑'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.memory_outlined),
                selectedIcon: Icon(Icons.memory),
                label: Text('Embedding 计算'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('设置'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容区
          Expanded(
            child: Column(
              children: [
                // 顶部状态栏
                _buildStatusBar(context),
                // 页面内容
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              // 当前文件
              if (provider.currentYamlPath != null)
                Chip(
                  avatar: const Icon(Icons.insert_drive_file, size: 16),
                  label: Text(
                    provider.currentYamlPath!.split(RegExp(r'[/\\]')).last,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (provider.currentYamlPath == null && provider.yamlBase != null)
                const Chip(
                  avatar: Icon(Icons.insert_drive_file, size: 16),
                  label: Text('未保存的模板', style: TextStyle(fontSize: 12)),
                ),
              const Spacer(),
              // LLM 配置状态
              if (provider.llmConfig != null)
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  label: Text(
                    provider.llmConfig!.embeddingModel,
                    style: const TextStyle(fontSize: 12),
                  ),
                )
              else
                const Chip(
                  avatar: Icon(Icons.warning, size: 16, color: Colors.orange),
                  label: Text('未配置 LLM', style: TextStyle(fontSize: 12)),
                ),
              const SizedBox(width: 8),
              // 加载状态
              if (provider.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        );
      },
    );
  }
}

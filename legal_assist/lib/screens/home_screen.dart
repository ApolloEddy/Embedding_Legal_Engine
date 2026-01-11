import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'case_input_screen.dart';
import 'analysis_result_screen.dart';
import 'settings_screen.dart';

/// 主页面 - 响应式布局
/// 
/// 手机竖屏：底部导航栏
/// 平板/桌面：侧边导航栏
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  /// 侧边栏是否展开（平板/桌面端）
  bool _isRailExtended = true;

  final List<Widget> _screens = const [
    CaseInputScreen(),
    AnalysisResultScreen(),
    SettingsScreen(),
  ];

  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < _mobileBreakpoint;

    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  /// 手机端布局（底部导航）
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 状态栏（简化版）
        _buildMobileStatusBar(context),
        // 页面内容
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ],
    );
  }

  /// 桌面端布局（侧边导航）
  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    // 平板竖版默认收起侧栏
    final isTabletPortrait = screenWidth < _tabletBreakpoint;
    
    return Row(
      children: [
        // 侧边导航栏
        NavigationRail(
          extended: isTabletPortrait ? _isRailExtended : true,
          minExtendedWidth: 200,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // 添加折叠按钮（仅平板竖版显示）
          trailing: isTabletPortrait ? Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IconButton(
                  icon: Icon(_isRailExtended ? Icons.chevron_left : Icons.chevron_right),
                  onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
                  tooltip: _isRailExtended ? '收起侧栏' : '展开侧栏',
                ),
              ),
            ),
          ) : null,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield,  // 盾牌图标（公安风格）
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Legal Assist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                ),
              ],
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.edit_document),
              selectedIcon: Icon(Icons.edit_document),
              label: Text('案情输入'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: Text('分析结果'),
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
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 底部导航栏（手机端）
  Widget? _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.edit_document),
          label: '案情输入',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics),
          label: '分析结果',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
    );
  }

  /// 手机端状态栏（简化版）
  Widget _buildMobileStatusBar(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Legal Assist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 加载指示器
                if (provider.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                // 资产状态指示点
                if (provider.yamlBase != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (provider.embeddingPackage != null)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 桌面端状态栏
  Widget _buildStatusBar(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // 阶段指示器
              _buildPhaseIndicator(context, provider),
              const Spacer(),
              // 资产状态
              if (provider.yamlBase != null)
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  label: Text('YAML: ${provider.yamlBase!.slots.length} slots',
                      style: const TextStyle(fontSize: 12)),
                )
              else
                const Chip(
                  avatar: Icon(Icons.warning, size: 16, color: Colors.orange),
                  label: Text('未加载 YAML', style: TextStyle(fontSize: 12)),
                ),
              const SizedBox(width: 8),
              if (provider.embeddingPackage != null)
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  label: Text('Embedding: ${provider.embeddingPackage!.embeddings.length}',
                      style: const TextStyle(fontSize: 12)),
                )
              else
                const Chip(
                  avatar: Icon(Icons.warning, size: 16, color: Colors.orange),
                  label: Text('未加载 Embedding', style: TextStyle(fontSize: 12)),
                ),
              const SizedBox(width: 8),
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

  Widget _buildPhaseIndicator(BuildContext context, AppProvider provider) {
    return Row(
      children: [
        _buildPhaseChip(context, 1, 'Phase 1: 输入', provider.currentPhase >= 1),
        const Icon(Icons.arrow_right),
        _buildPhaseChip(context, 2, 'Phase 2: 提取', provider.currentPhase >= 2),
        const Icon(Icons.arrow_right),
        _buildPhaseChip(context, 3, 'Phase 3: 分析', provider.currentPhase >= 3),
      ],
    );
  }

  Widget _buildPhaseChip(BuildContext context, int phase, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: active ? Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

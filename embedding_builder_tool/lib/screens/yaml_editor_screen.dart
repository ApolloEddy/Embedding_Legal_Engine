import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import '../providers/app_provider.dart';

/// YAML 编辑器页面
class YamlEditorScreen extends StatelessWidget {
  const YamlEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 工具栏
              _buildToolbar(context, provider),
              const SizedBox(height: 16),
              // 消息提示
              if (provider.errorMessage != null)
                _buildMessageBar(context, provider.errorMessage!, Colors.red),
              if (provider.successMessage != null)
                _buildMessageBar(context, provider.successMessage!, Colors.green),
              const SizedBox(height: 8),
              // 主要内容
              Expanded(
                child: provider.yamlBase == null
                    ? _buildEmptyState(context, provider)
                    : _buildEditor(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, AppProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => provider.createDefaultTemplate(),
          icon: const Icon(Icons.add),
          label: const Text('新建模板'),
        ),
        OutlinedButton.icon(
          onPressed: () => _loadYamlFile(context, provider),
          icon: const Icon(Icons.folder_open),
          label: const Text('打开文件'),
        ),
        OutlinedButton.icon(
          onPressed: provider.yamlBase != null
              ? () => _saveYamlFile(context, provider)
              : null,
          icon: const Icon(Icons.save),
          label: const Text('保存'),
        ),
      ],
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

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '尚未加载 YAML 基座',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '点击"新建模板"创建默认模板，或"打开文件"加载现有 YAML',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, AppProvider provider) {
    final yamlBase = provider.yamlBase!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：全局信息和 Slots
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlobalInfoCard(context, yamlBase),
                const SizedBox(height: 16),
                _buildSlotsCard(context, provider, yamlBase),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 右侧：Crimes
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildCrimesCard(context, provider, yamlBase),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalInfoCard(BuildContext context, YamlBase yamlBase) {
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
                Text('全局信息', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildInfoRow('YAML 版本', yamlBase.yamlVersion),
            _buildInfoRow('法律体系', _getLegalSystemTypeName(yamlBase.legalSystemType)),
            _buildInfoRow('分析层级', '${yamlBase.analysisLevels.length} 级'),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsCard(BuildContext context, AppProvider provider, YamlBase yamlBase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text('构成要素 (${yamlBase.slots.length})', 
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddSlotDialog(context, provider),
                  tooltip: '添加 Slot',
                ),
              ],
            ),
            const Divider(),
            ...yamlBase.slots.map((slot) => _buildSlotTile(context, provider, slot)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTile(BuildContext context, AppProvider provider, Slot slot) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        child: Text('${slot.analysisLevel}', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(slot.slotName),
      subtitle: Text(slot.semanticScope, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (slot.required)
            const Chip(
              label: Text('必需', style: TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () => provider.removeSlot(slot.slotId),
          ),
        ],
      ),
    );
  }

  Widget _buildCrimesCard(BuildContext context, AppProvider provider, YamlBase yamlBase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel),
                const SizedBox(width: 8),
                Text('罪名定义 (${yamlBase.crimes.length})', 
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddCrimeDialog(context, provider),
                  tooltip: '添加罪名',
                ),
              ],
            ),
            const Divider(),
            ...yamlBase.crimes.map((crime) => _buildCrimeTile(context, provider, crime)),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeTile(BuildContext context, AppProvider provider, Crime crime) {
    return ExpansionTile(
      leading: const Icon(Icons.balance),
      title: Text(crime.crimeName),
      subtitle: Text('ID: ${crime.crimeId}'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('必需要件', crime.requiredSlots.join(', ')),
              _buildInfoRow('可选要件', crime.optionalSlots.isEmpty ? '无' : crime.optionalSlots.join(', ')),
              _buildInfoRow('排除要件', crime.exclusionSlots.isEmpty ? '无' : crime.exclusionSlots.join(', ')),
              const SizedBox(height: 8),
              Text('解释模板:', style: Theme.of(context).textTheme.labelMedium),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(crime.explanationTemplate, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('删除'),
                  onPressed: () => provider.removeCrime(crime.crimeId),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getLegalSystemTypeName(LegalSystemType type) {
    switch (type) {
      case LegalSystemType.criminal:
        return '刑事';
      case LegalSystemType.administrative:
        return '行政';
      case LegalSystemType.civil:
        return '民事';
    }
  }

  Future<void> _loadYamlFile(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );

    if (result != null && result.files.single.path != null) {
      await provider.loadYamlFile(result.files.single.path!);
    }
  }

  Future<void> _saveYamlFile(BuildContext context, AppProvider provider) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '保存 YAML 文件',
      fileName: 'legal_base.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );

    if (result != null) {
      await provider.saveYamlFile(result);
    }
  }

  void _showAddSlotDialog(BuildContext context, AppProvider provider) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final scopeController = TextEditingController();
    int level = 1;
    bool required = false;
    SlotRole role = SlotRole.qualification;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加构成要素'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Slot ID'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: scopeController,
                  decoration: const InputDecoration(labelText: '语义边界'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: level,
                  decoration: const InputDecoration(labelText: '分析层级'),
                  items: [1, 2, 3].map((l) => DropdownMenuItem(
                    value: l,
                    child: Text('第 $l 级'),
                  )).toList(),
                  onChanged: (v) => setState(() => level = v!),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('必需'),
                  value: required,
                  onChanged: (v) => setState(() => required = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                provider.addSlot(Slot(
                  slotId: idController.text,
                  slotName: nameController.text,
                  analysisLevel: level,
                  required: required,
                  role: role,
                  semanticScope: scopeController.text,
                ));
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCrimeDialog(BuildContext context, AppProvider provider) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final templateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加罪名'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Crime ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '罪名'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: templateController,
                decoration: const InputDecoration(labelText: '解释模板'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.addCrime(Crime(
                crimeId: idController.text,
                crimeName: nameController.text,
                applicableCaseType: 'criminal',
                requiredSlots: [],
                optionalSlots: [],
                exclusionSlots: [],
                explanationTemplate: templateController.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

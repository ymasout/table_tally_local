import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/table_provider.dart';
import 'item_management_screen.dart';

/// Settings Screen - 设置页面
/// Allows configuration of table count and access to menu management
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tableCountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tableCountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<TableProvider>();
    _tableCountController.text = provider.tableCount.toString();
  }

  Future<void> _saveTableCount() async {
    final newCount = int.tryParse(_tableCountController.text);
    if (newCount == null || newCount < 1 || newCount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的桌台数量 (1-100)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TableProvider>();
      await provider.updateTableCount(newCount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已更新桌台数量为 $newCount')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToItemManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Consumer<TableProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              // Table Settings Section
              _buildSectionHeader('桌台设置'),
              _buildTableCountCard(provider),

              const Divider(height: 32),

              // Menu Settings Section
              _buildSectionHeader('菜单管理'),
              _buildMenuManagementCard(),

              const Divider(height: 32),

              // App Info Section
              _buildSectionHeader('关于'),
              _buildAppInfoCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildTableCountCard(TableProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_restaurant, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  '桌台数量',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '当前桌台数: ${provider.tables.length}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tableCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '桌台总数',
                      hintText: '输入桌台数量',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTableCount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('应用'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '提示: 增加 will 添加新桌台，减少将保留现有数据',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuManagementCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Icon(Icons.restaurant_menu, color: Colors.green.shade700),
        title: const Text('商品管理'),
        subtitle: const Text('添加、编辑或删除商品'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _navigateToItemManagement,
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  '应用信息',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('应用名称', '桌台实时累加系统'),
            _buildInfoRow('版本', '1.0.0'),
            _buildInfoRow('存储模式', '本地存储 (SQLite)'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

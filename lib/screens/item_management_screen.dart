import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/table_provider.dart';
import '../models/item_model.dart';

/// Item Management Screen - 商品管理页面
/// Allows CRUD operations for menu items
class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure items are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().initialize();
    });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        title: '添加商品',
        onSave: (item) async {
          await context.read<TableProvider>().addNewItem(item);
        },
      ),
    );
  }

  void _showEditItemDialog(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        title: '编辑商品',
        item: item,
        onSave: (updatedItem) async {
          await context.read<TableProvider>().updateExistingItem(updatedItem);
        },
      ),
    );
  }

  Future<void> _deleteItem(ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${item.name}" 吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TableProvider>().deleteExistingItem(item.itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${item.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品管理'),
      ),
      body: Consumer<TableProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final items = provider.items;

          if (items.isEmpty) {
            return const Center(
              child: Text('暂无商品，点击右下角按钮添加'),
            );
          }

          // Group items by category
          final countingItems = items.where((i) => i.isCountingItem).toList();
          final weighingItems = items.where((i) => i.isWeighingItem).toList();

          return ListView(
            children: [
              if (countingItems.isNotEmpty) ...[
                _buildCategoryHeader('计数类商品', countingItems.length),
                ...countingItems.map((item) => _ItemCard(
                      item: item,
                      onEdit: () => _showEditItemDialog(item),
                      onDelete: () => _deleteItem(item),
                    )),
              ],
              if (weighingItems.isNotEmpty) ...[
                _buildCategoryHeader('称重类商品', weighingItems.length),
                ...weighingItems.map((item) => _ItemCard(
                      item: item,
                      onEdit: () => _showEditItemDialog(item),
                      onDelete: () => _deleteItem(item),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        label: const Text('添加商品'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item Card Widget - 商品卡片
class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: item.isWeighingItem ? Colors.blue : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '¥${item.formattedPrice}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' / ${item.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isWeighingItem
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isWeighingItem ? '称重' : '计数',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isWeighingItem
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}

/// Item Form Dialog - 商品表单对话框
class _ItemFormDialog extends StatefulWidget {
  final String title;
  final ItemModel? item; // null for add, non-null for edit
  final Future<void> Function(ItemModel) onSave;

  const _ItemFormDialog({
    required this.title,
    this.item,
    required this.onSave,
  });

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _stepController = TextEditingController();

  String _category = 'counting';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _unitController.text = widget.item!.unit;
      _stepController.text = widget.item!.step.toString();
      _category = widget.item!.category;
    } else {
      _unitController.text = '份';
      _stepController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);
      final step = double.parse(_stepController.text);

      final item = ItemModel(
        itemId: widget.item?.itemId ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        price: price,
        unit: _unitController.text.trim(),
        step: step,
        category: _category,
      );

      await widget.onSave(item);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? '商品添加成功' : '商品更新成功'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '商品名称 *',
                  hintText: '如: 可乐、酸菜鱼',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入商品名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price field
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '单价 (元) *',
                  hintText: '如: 15.00',
                  border: OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入单价';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return '请输入有效的价格';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit field
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: '单位 *',
                  hintText: '如: 瓶、碗、kg、斤',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入单位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Step field
              TextFormField(
                controller: _stepController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '默认步长 *',
                  hintText: '计数类通常为1，称重类通常为0.5',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入步长';
                  }
                  final step = double.tryParse(value);
                  if (step == null || step <= 0) {
                    return '请输入有效的步长';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category selection
              const Text(
                '商品类型',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('计数类'),
                      subtitle: const Text('+/- 按钮', style: TextStyle(fontSize: 12)),
                      value: 'counting',
                      groupValue: _category,
                      onChanged: (value) {
                        setState(() => _category = value!);
                        if (value == 'counting') {
                          _stepController.text = '1';
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('称重类'),
                      subtitle: const Text('数字键盘', style: TextStyle(fontSize: 12)),
                      value: 'weighing',
                      groupValue: _category,
                      onChanged: (value) {
                        setState(() => _category = value!);
                        if (value == 'weighing') {
                          _stepController.text = '0.5';
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/table_provider.dart';
import '../models/item_model.dart';
import '../models/log_model.dart';

/// Table Detail Screen - 桌台详情页
/// Refactored for busy restaurant scenarios with single-page GridView
class TableDetailScreen extends StatefulWidget {
  final int tableId;

  const TableDetailScreen({super.key, required this.tableId});

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().loadTableData(widget.tableId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tableId}号桌详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _showBillDialog(),
            tooltip: '查看账单',
          ),
        ],
      ),
      body: Consumer<TableProvider>(
        builder: (context, provider, child) {
          final totalAmount = provider.getTableTotal(widget.tableId);
          final tableItems = provider.getTableItems(widget.tableId);
          final allItems = provider.items;

          return Column(
            children: [
              // Total amount display
              _TotalAmountDisplay(amount: totalAmount),
              // All items in a single GridView
              Expanded(
                child: allItems.isEmpty
                    ? const Center(child: Text('暂无商品'))
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.75,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: allItems.length,
                          itemBuilder: (context, index) {
                            final item = allItems[index];
                            final tableItem = tableItems.cast<TableItemModel?>().firstWhere(
                              (ti) => ti?.itemId == item.itemId,
                              orElse: () => null,
                            );

                            return _LargeItemCard(
                              item: item,
                              quantity: tableItem?.quantity ?? 0.0,
                              onTap: () => _handleItemTap(item, provider),
                              onAdd: () => provider.addItemToTable(widget.tableId, item.itemId),
                              onRemove: () => provider.removeItemFromTable(widget.tableId, item.itemId),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      // Bottom bar with undo and checkout
      bottomNavigationBar: _BottomActionBar(tableId: widget.tableId),
    );
  }

  void _handleItemTap(ItemModel item, TableProvider provider) {
    if (item.isWeighingItem) {
      // Show numeric keypad bottom sheet for weighing items
      _showWeighingBottomSheet(item, provider);
    } else {
      // Direct +1 for counting items
      provider.addItemToTable(widget.tableId, item.itemId);
    }
  }

  void _showWeighingBottomSheet(ItemModel item, TableProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WeighingKeypadBottomSheet(
        item: item,
        onConfirm: (quantity) {
          provider.setTableItemQuantity(widget.tableId, item.itemId, quantity);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBillDialog() {
    final provider = context.read<TableProvider>();
    final tableItems = provider.getTableItems(widget.tableId);
    final logs = provider.getTableLogs(widget.tableId);
    final total = provider.getTableTotal(widget.tableId);

    // 辅助函数：根据 itemId 查找商品名称
    String getItemName(String itemId) {
      try {
        return provider.items.firstWhere((i) => i.itemId == itemId).name;
      } catch (_) {
        return itemId; // 找不到就显示原始 ID
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.tableId}号桌账单'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (tableItems.isNotEmpty) ...[
                const Text('商品明细', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...tableItems.map((item) {
                  final itemModel = provider.items.firstWhere(
                    (i) => i.itemId == item.itemId,
                    orElse: () => ItemModel(
                      itemId: item.itemId,
                      name: 'Unknown',
                      unit: '',
                      price: 0,
                      step: 1,
                    ),
                  );
                  final subtotal = item.quantity * itemModel.price;
                  return ListTile(
                    dense: true,
                    title: Text(itemModel.name),
                    subtitle: Text('${item.quantity} ${itemModel.unit} × ¥${itemModel.price}'),
                    trailing: Text(
                      '¥${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
                const Divider(),
                ListTile(
                  dense: true,
                  title: const Text('总计', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    '¥${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '当前桌台暂无商品',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  ),
                ),
              if (logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('最近操作', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...logs.take(30).map((log) {
                  // 结账分割线
                  if (log.itemId == '__checkout__') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.orange.shade300, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '已结账 ${log.formattedTimestamp}  金额: ¥${log.delta.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.orange.shade300, thickness: 1)),
                        ],
                      ),
                    );
                  }
                  // 普通操作日志
                  return ListTile(
                    dense: true,
                    leading: Text(
                      log.formattedDelta,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: log.formattedDelta.startsWith('+')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(getItemName(log.itemId)),
                    subtitle: Text(log.formattedTimestamp),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

}

/// Total Amount Display Widget
class _TotalAmountDisplay extends StatelessWidget {
  final double amount;

  const _TotalAmountDisplay({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade200, width: 1)),
      ),
      child: Column(
        children: [
          const Text(
            '当前金额',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            '¥${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large Item Card Widget - 外卖APP风格卡片
/// Vertical layout: Top (image) + Bottom (info + actions)
class _LargeItemCard extends StatelessWidget {
  final ItemModel item;
  final double quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _LargeItemCard({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isWeighing = item.isWeighingItem;

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // ========== 底层: 图片铺满整个卡片 ==========
            Positioned.fill(
              child: _buildImageSection(),
            ),
            // ========== 上层: 半透明信息浮层（底部） ==========
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 商品名称
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 价格 + 单位
                    Text(
                      '¥${item.formattedPrice}/${item.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 操作区
                    _buildOperationSection(isWeighing),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection() {
    if (item.hasImage && !kIsWeb) {
      // 显示商品图片（不裁切，顶部对齐）
      return Container(
        color: Colors.grey.shade100,
        width: double.infinity,
        height: double.infinity,
        child: Image.file(
          File(item.imagePath!),
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ),
      );
    }
    // Fallback: 色块 + Icon
    return _buildPlaceholderImage();
  }

  /// 默认占位图
  Widget _buildPlaceholderImage() {
    final isWeighing = item.isWeighingItem;
    return Container(
      width: double.infinity,
      color: isWeighing ? Colors.blue.shade50 : Colors.orange.shade50,
      child: Center(
        child: Icon(
          isWeighing ? Icons.scale : Icons.fastfood,
          size: 40,
          color: isWeighing ? Colors.blue.shade200 : Colors.orange.shade200,
        ),
      ),
    );
  }

  /// 构建操作区域
  Widget _buildOperationSection(bool isWeighing) {
    if (isWeighing) {
      // 称重类: 显示重量 + "输入"按钮
      return Row(
        children: [
          // 当前重量
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  quantity == 0 ? '0.0' : quantity.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 输入按钮
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '输入',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 计数类: 显示数量 + 加减按钮
      return Row(
        children: [
          // 减按钮
          _buildSmallButton(
            icon: Icons.remove,
            color: Colors.red,
            onPressed: quantity > 0 ? onRemove : null,
          ),
          const SizedBox(width: 8),
          // 当前数量
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  quantity == 0 ? '0' : quantity.toInt().toString(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 加按钮
          _buildSmallButton(
            icon: Icons.add,
            color: Colors.green,
            onPressed: onAdd,
          ),
        ],
      );
    }
  }

  /// 构建小按钮
  Widget _buildSmallButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.grey,
          size: 22,
        ),
      ),
    );
  }
}

/// Action Button Widget for +/- buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Weighing Item Numeric Keypad Bottom Sheet
/// Full-width bottom sheet with custom numeric keypad
class _WeighingKeypadBottomSheet extends StatefulWidget {
  final ItemModel item;
  final Function(double) onConfirm;

  const _WeighingKeypadBottomSheet({
    required this.item,
    required this.onConfirm,
  });

  @override
  State<_WeighingKeypadBottomSheet> createState() => _WeighingKeypadBottomSheetState();
}

class _WeighingKeypadBottomSheetState extends State<_WeighingKeypadBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleKeyPress(String value) {
    final currentText = _controller.text;
    if (value == 'DEL') {
      if (currentText.isNotEmpty) {
        _controller.text = currentText.substring(0, currentText.length - 1);
      }
    } else if (value == '.') {
      if (!currentText.contains('.')) {
        _controller.text = currentText + '.';
      }
    } else {
      _controller.text = currentText + value;
    }
    setState(() {});
  }

  void _handleConfirm() {
    if (_controller.text.isEmpty) return;
    final quantity = double.tryParse(_controller.text);
    if (quantity != null && quantity >= 0) {
      widget.onConfirm(quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with item name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请输入重量 (${widget.item.unit})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Display current input
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: _controller.text.isEmpty
                      ? Text(
                          '请输入重量',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          _controller.text,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
            // Numeric keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _KeypadButton(label: '1', onPressed: () => _handleKeyPress('1')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '2', onPressed: () => _handleKeyPress('2')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '3', onPressed: () => _handleKeyPress('3')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _KeypadButton(label: '4', onPressed: () => _handleKeyPress('4')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '5', onPressed: () => _handleKeyPress('5')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '6', onPressed: () => _handleKeyPress('6')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _KeypadButton(label: '7', onPressed: () => _handleKeyPress('7')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '8', onPressed: () => _handleKeyPress('8')),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '9', onPressed: () => _handleKeyPress('9')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _KeypadButton(
                        label: '.',
                        onPressed: () => _handleKeyPress('.'),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 8),
                      _KeypadButton(label: '0', onPressed: () => _handleKeyPress('0')),
                      const SizedBox(width: 8),
                      _KeypadButton(
                        label: 'DEL',
                        onPressed: () => _handleKeyPress('DEL'),
                        backgroundColor: Colors.red.shade100,
                        icon: Icons.backspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Confirm button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numeric Keypad Button Widget
class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final IconData? icon;

  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 28, color: Colors.grey.shade700)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Action Bar with Undo and Checkout buttons
class _BottomActionBar extends StatelessWidget {
  final int tableId;

  const _BottomActionBar({required this.tableId});

  @override
  Widget build(BuildContext context) {
    // 使用 watch 监听状态变化，实时更新金额和按钮状态
    final provider = context.watch<TableProvider>();
    final total = provider.getTableTotal(tableId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Undo button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await provider.undoLastOperation(tableId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已撤销上次操作')),
                    );
                  }
                },
                icon: const Icon(Icons.undo, size: 22),
                label: const Text('撤销', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Checkout button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: total > 0
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _CheckoutSummaryScreen(tableId: tableId),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('结账', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '¥${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkout Summary Screen (shown after pressing checkout)
class _CheckoutSummaryScreen extends StatelessWidget {
  final int tableId;

  const _CheckoutSummaryScreen({required this.tableId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableProvider>();
    final tableItems = provider.getTableItems(tableId);
    final total = provider.getTableTotal(tableId);

    return Scaffold(
      appBar: AppBar(
        title: Text('$tableId号桌结账'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    '商品明细',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...tableItems.map((item) {
                    final itemModel = provider.items.firstWhere(
                      (i) => i.itemId == item.itemId,
                      orElse: () => ItemModel(
                        itemId: item.itemId,
                        name: 'Unknown',
                        unit: '',
                        price: 0,
                        step: 1,
                      ),
                    );
                    final subtotal = item.quantity * itemModel.price;
                    return Card(
                      child: ListTile(
                        title: Text(itemModel.name),
                        subtitle: Text('${item.quantity} ${itemModel.unit} × ¥${itemModel.price}'),
                        trailing: Text(
                          '¥${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      title: const Text('总计', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '¥${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await provider.clearTable(tableId);
                  if (context.mounted) {
                    // pop 结账明细页 → 回到桌台详情页
                    Navigator.of(context).pop();
                    // pop 桌台详情页 → 回到主页
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('结账成功，桌台已清空')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确认结账并清台',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

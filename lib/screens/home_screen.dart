import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/table_provider.dart';
import '../models/table_model.dart';
import 'table_detail_screen.dart';
import 'settings_screen.dart';

/// Home Screen - 桌台列表页
/// Section 3.1: Table list with status display
/// Responsive: 2 columns for phones, 4 columns for tablets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().initialize();
      _createDefaultTables();
    });
  }

  /// Create default tables if none exist
  Future<void> _createDefaultTables() async {
    final provider = context.read<TableProvider>();
    if (provider.tables.isEmpty) {
      // Use the configured table count
      final tableCount = provider.tableCount;
      for (int i = 1; i <= tableCount; i++) {
        await provider.createTable(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('桌台列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TableProvider>().initialize();
            },
            tooltip: '刷新',
          ),
        ],
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

          if (provider.tables.isEmpty) {
            return const Center(child: Text('No tables available'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Determine columns based on screen width
              // Phone: 2 columns, Tablet: 4 columns
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              final aspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.0;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: provider.tables.length,
                itemBuilder: (context, index) {
                  final table = provider.tables[index];
                  return _TableCard(
                    table: table,
                    totalAmount: provider.getTableTotal(table.tableId),
                    hasPendingVoiceMemo: provider.hasPendingVoiceMemo(table.tableId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Table Card Widget - 桌台卡片
class _TableCard extends StatelessWidget {
  final TableModel table;
  final double totalAmount;
  final bool hasPendingVoiceMemo;

  const _TableCard({
    required this.table,
    required this.totalAmount,
    required this.hasPendingVoiceMemo,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = table.isIdle;

    return Card(
      elevation: isIdle ? 2 : 4,
      color: isIdle ? Colors.white : Colors.orange.shade50,
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table number
                  Text(
                    '${table.tableId}号桌',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isIdle ? Colors.grey.shade700 : Colors.orange.shade700,
                        ),
                  ),
                  const Spacer(),
                  // Status
                  Row(
                    children: [
                      Icon(
                        isIdle ? Icons.event_available : Icons.restaurant,
                        size: 16,
                        color: isIdle ? Colors.grey : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isIdle ? '空闲' : '用餐中',
                        style: TextStyle(
                          color: isIdle ? Colors.grey : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Amount
                  Text(
                    '¥${totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            // Voice memo indicator (red dot)
            if (hasPendingVoiceMemo)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableDetailScreen(tableId: table.tableId),
      ),
    );
  }
}

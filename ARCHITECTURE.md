# 桌台实时累加系统 - 架构文档

> **项目名称**: Table Tally Local
> **版本**: 1.2.0
> **最后更新**: 2025年2月
> **技术栈**: Flutter + SQLite + SharedPreferences + ImagePicker

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术栈](#2-技术栈)
3. [项目结构](#3-项目结构)
4. [核心功能模块](#4-核心功能模块)
5. [数据模型](#5-数据模型)
6. [存储架构](#6-存储架构)
7. [状态管理](#7-状态管理)
8. [页面与路由](#8-页面与路由)
9. [UI 组件](#9-ui-组件)
10. [开发指南](#10-开发指南)
11. [注意事项](#11-注意事项)
12. [未来扩展](#12-未来扩展)

---

## 1. 项目概述

### 1.1 项目定位

一款面向**餐厅场景**的本地消费累加系统，核心解决高峰期快速记账需求。

### 1.2 核心设计原则

| 原则 | 说明 |
|------|------|
| 桌台即账本 | 每个桌台独立记账，数据互不干扰 |
| 累加/减少模式 | 所有操作都是数量的增减，无表单填写 |
| 一步操作 | 单击即可完成添加/移除，无确认弹窗 |
| 操作可撤销 | 支持撤销最近一次操作，防止误触 |
| 离线优先 | 所有数据存储本地，无需网络 |

### 1.3 目标用户

- 中小型餐厅、大排档、快餐店
- 需要快速记账的用餐场景
- 平板/手机双端适配

### 1.4 V1 版本范围

**包含**:
- ✅ 桌台管理
- ✅ 商品累加/减少
- ✅ 计数类商品 (+/- 按钮)
- ✅ 称重类商品 (数字键盘)
- ✅ 结账清台
- ✅ 操作日志与撤销
- ✅ 设置页面 (桌台数量配置)
- ✅ 商品管理 (添加/编辑/删除)
- ✅ 商品图片上传与展示 (新增)

**不包含**:
- ❌ 语音识别
- ❌ 云同步/登录
- ❌ 多设备协作
- ❌ 复杂报表
- ❌ 会员/营销系统

---

## 2. 技术栈

### 2.1 核心框架

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.38.9+ | 跨平台 UI 框架 |
| Dart | 3.5.0+ | 编程语言 |

### 2.2 依赖包

```yaml
dependencies:
  # 状态管理
  provider: ^6.1.1

  # 本地数据库
  sqflite: ^2.3.0           # SQLite 数据库 (移动端)
  sqflite_common_ffi: ^2.3.0 # SQLite FFI (桌面端)
  path: ^1.8.3              # 路径处理

  # 工具类
  intl: ^0.18.1             # 国际化/日期格式
  uuid: ^4.3.1              # UUID 生成
  shared_preferences: ^2.2.2 # 本地偏好设置存储

  # 图片处理 (新增)
  image_picker: ^1.0.7      # 图片选择器
  path_provider: ^2.1.1     # 应用目录路径

  # 音频功能 (预留)
  flutter_sound: ^9.3.3     # 音频录制/播放
  permission_handler: ^11.1.0 # 权限管理
```

### 2.3 支持平台

| 平台 | 状态 | 存储方式 |
|------|------|---------|
| Android | ✅ 支持 | SQLite |
| iOS | ✅ 支持 | SQLite |
| Windows | ⚠️ 需 Visual Studio | SQLite (FFI) |
| Web | ✅ 支持 | 内存存储 (刷新丢失) |

---

## 3. 项目结构

```
table_tally_local/
├── lib/
│   ├── main.dart                    # 应用入口
│   │
│   ├── models/                      # 数据模型
│   │   ├── table_model.dart         # 桌台模型
│   │   ├── item_model.dart          # 商品模型
│   │   └── log_model.dart           # 操作日志 + TableItem 模型
│   │
│   ├── providers/                   # 状态管理
│   │   └── table_provider.dart      # 全局状态 Provider
│   │
│   ├── screens/                     # 页面
│   │   ├── home_screen.dart         # 桌台列表页
│   │   ├── table_detail_screen.dart # 桌台详情页
│   │   ├── settings_screen.dart     # 设置页面 (新增)
│   │   └── item_management_screen.dart # 商品管理页面 (新增)
│   │
│   └── services/                    # 服务层
│       ├── storage_service.dart     # 存储接口抽象
│       ├── database_helper.dart     # SQLite 实现
│       └── memory_storage.dart      # 内存存储实现 (Web)
│
├── web/                             # Web 平台资源
├── android/                         # Android 平台配置
├── ios/                             # iOS 平台配置
├── windows/                         # Windows 平台配置
│
├── pubspec.yaml                     # 依赖配置
├── Development Plan.md              # 开发计划
└── ARCHITECTURE.md                  # 本文档
```

---

## 4. 核心功能模块

### 4.1 桌台管理模块 (Table Module)

**文件位置**: `lib/screens/home_screen.dart`

**功能描述**:
- 展示所有桌台的网格列表
- 显示每个桌台的状态（空闲/用餐中）和当前金额
- 支持新增桌台
- 点击进入桌台详情

**关键组件**:
```dart
class HomeScreen extends StatefulWidget        // 桌台列表页
class _TableCard extends StatelessWidget      // 桌台卡片组件
```

**状态显示**:
- `idle` (空闲): 白色背景，灰色文字
- `in_use` (用餐中): 橙色背景，橙色文字

**响应式布局**:
- 手机: 2列网格
- 平板: 4列网格

---

### 4.2 桌台详情/累加模块 (Table Detail Module)

**文件位置**: `lib/screens/table_detail_screen.dart`

**功能描述**:
- 展示桌台内所有商品
- 支持商品的添加/移除
- 实时显示当前金额
- 底部操作栏（撤销/结账）

**关键组件**:
```dart
class TableDetailScreen extends StatefulWidget           // 桌台详情页
class _TotalAmountDisplay extends StatelessWidget       // 金额显示
class _LargeItemCard extends StatelessWidget            // 商品卡片
class _ActionButton extends StatelessWidget             // +/- 按钮
class _BottomActionBar extends StatelessWidget          // 底部操作栏
class _CheckoutSummaryScreen extends StatelessWidget    // 结账确认页
```

**商品操作流程**:
1. **计数类商品**: 点击 +/- 按钮直接增减
2. **称重类商品**: 点击卡片 → 弹出数字键盘 → 输入重量 → 确认

---

### 4.3 称重键盘模块 (Numeric Keypad Module)

**文件位置**: `lib/screens/table_detail_screen.dart`

**功能描述**:
- 为称重类商品提供专用数字键盘
- 支持小数点输入
- 支持删除操作

**关键组件**:
```dart
class _WeighingKeypadBottomSheet extends StatefulWidget  // 键盘底部弹窗
class _KeypadButton extends StatelessWidget             // 键盘按钮
```

**键盘布局**:
```
[1] [2] [3]
[4] [5] [6]
[7] [8] [9]
[.] [0] [DEL]
   [确认]
```

---

### 4.4 结账模块 (Checkout Module)

**文件位置**: `lib/screens/table_detail_screen.dart`

**功能描述**:
- 显示商品明细和总价
- 确认后清空桌台
- 重置桌台状态为空闲

**流程**:
1. 点击底部「结账」按钮
2. 显示结账确认页（商品明细 + 总价）
3. 点击「确认结账并清台」
4. 清空桌台数据，返回首页

---

### 4.5 操作日志与撤销模块 (Log & Undo Module)

**文件位置**: `lib/services/database_helper.dart`, `lib/providers/table_provider.dart`

**功能描述**:
- 记录每次商品增减操作
- 支持撤销最近一次操作
- 撤销后自动删除对应日志

**日志结构**:
```dart
class LogModel {
  final int id;           // 主键
  final int tableId;      // 桌台ID
  final String itemId;    // 商品ID
  final double delta;     // 变化量 (+/-)
  final DateTime timestamp; // 时间戳
}
```

---

### 4.6 设置模块 (Settings Module)

**文件位置**: `lib/screens/settings_screen.dart`

**功能描述**:
- 配置桌台总数量 (1-100)
- 跳转到商品管理页面
- 显示应用信息

**关键组件**:
```dart
class SettingsScreen extends StatefulWidget      // 设置页面
```

**桌台数量配置**:
- 使用 `shared_preferences` 持久化存储设置
- 增加数量会自动创建新桌台
- 减少数量会保留现有桌台数据

**Provider 方法**:
```dart
Future<void> updateTableCount(int newCount)  // 更新桌台数量
int get tableCount                           // 获取当前桌台数量设置
```

---

### 4.7 商品管理模块 (Item Management Module)

**文件位置**: `lib/screens/item_management_screen.dart`

**功能描述**:
- 展示所有商品列表（按分类分组）
- 添加新商品（含图片上传）
- 编辑现有商品（含图片修改）
- 删除商品（自动清理图片文件）

**关键组件**:
```dart
class ItemManagementScreen extends StatefulWidget  // 商品管理页面
class _ItemCard extends StatelessWidget           // 商品卡片（含图片预览）
class _ItemFormDialog extends StatefulWidget      // 商品表单对话框（含图片选择）
```

**商品表单字段**:
| 字段 | 类型 | 说明 |
|------|------|------|
| image | 图片 | 商品图片 (可选) |
| name | 文本 | 商品名称 (必填) |
| price | 数字 | 单价 (必填) |
| unit | 文本 | 单位 (必填) |
| step | 数字 | 默认步长 (必填) |
| category | 单选 | 计数类/称重类 |

**图片上传 UI**:
- 无图片：100x100 灰色背景 + 相机图标 + "点击上传"
- 有图片：图片预览 + 右上角删除按钮 + 右下角修改图标

**CRUD 操作**:
```dart
Future<void> addNewItem(ItemModel item)       // 添加商品
Future<void> updateExistingItem(ItemModel item) // 更新商品
Future<void> deleteExistingItem(String itemId) // 删除商品
```

**删除保护**:
- 删除前显示确认对话框
- 删除商品时自动删除关联图片文件

---

### 4.8 商品图片模块 (Image Support Module)

**文件位置**: `lib/screens/item_management_screen.dart`, `lib/screens/table_detail_screen.dart`

**功能描述**:
- 商品图片选择与上传
- 图片持久化存储
- 商品卡片图片展示

#### 4.8.1 图片上传逻辑

**流程**:
```
1. 点击图片区域 → 调用 image_picker (Gallery)
2. 选择图片 → 获取临时文件路径
3. 复制到应用目录 → {DocumentsDirectory}/item_images/item_{uuid}.jpg
4. 保存路径到数据库 → imagePath 字段
```

**存储路径**:
```
{getApplicationDocumentsDirectory()}/item_images/item_{uuid}.jpg
```

**关键代码**:
```dart
// 选择图片
final XFile? image = await _picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 512,
  maxHeight: 512,
  imageQuality: 85,
);

// 生成唯一文件名
final fileName = 'item_${_uuid.v4()}.jpg';

// 复制到应用目录
final appDir = await getApplicationDocumentsDirectory();
final savedPath = path.join(appDir.path, 'item_images', fileName);
await File(image.path).copy(savedPath);
```

#### 4.8.2 图片展示 UI

**商品管理页卡片**:
- 60x60 圆角图片预览
- 无图片时显示分类色块 + 图标

**桌台详情页卡片 (外卖 APP 风格)**:
```
┌─────────────────────┐
│                     │
│    图片区域 (4)      │  ← Flex 4
│   BoxFit.cover      │
│                     │
├─────────────────────┤
│ 商品名称 (加粗)      │
│ ¥价格 / 单位        │  ← Flex 5
│                     │
│ [−]  数量  [+]      │
│ 或 [重量] [输入]    │
└─────────────────────┘
```

**视觉效果**:
- 卡片阴影 (elevation: 4)
- 圆角 (12dp)
- 图片上圆角，下方直角
- 文字溢出自动截断

#### 4.8.3 平台兼容性

| 平台 | 图片上传 | 图片展示 | 说明 |
|------|---------|---------|------|
| Android | ✅ | ✅ | 需要相册权限 |
| iOS | ✅ | ✅ | 需要相册权限 |
| Windows | ✅ | ✅ | - |
| Web | ❌ | ⚠️ 占位图 | 不支持文件存储 |

#### 4.8.4 权限配置

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择商品图片</string>
```

---

## 5. 数据模型

### 5.1 TableModel (桌台模型)

**文件**: `lib/models/table_model.dart`

```dart
class TableModel {
  final int tableId;        // 桌号 (主键)
  final String status;      // 状态: 'idle' | 'in_use'
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间
}
```

**数据库表**:
```sql
CREATE TABLE tables (
  table_id INTEGER PRIMARY KEY,
  status TEXT NOT NULL CHECK(status IN ('idle', 'in_use')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

---

### 5.2 ItemModel (商品模型)

**文件**: `lib/models/item_model.dart`

```dart
class ItemModel {
  final String itemId;      // 商品ID (主键)
  final String name;        // 商品名称
  final String unit;        // 单位: 'kg' | '瓶' | '碗' | '斤'
  final double price;       // 单价
  final double step;        // 默认步长
  final String category;    // 分类: 'weighing' | 'counting'
  final String? imagePath;  // 商品图片路径 (新增，可选)
}
```

**分类说明**:
- `counting` (计数类): 使用 +/- 按钮，每次增减 step 量
- `weighing` (称重类): 使用数字键盘，手动输入数量

**图片路径说明**:
- 存储在应用文档目录下的 `item_images/` 文件夹
- 文件名格式: `item_{uuid}.jpg`
- 使用 `hasImage` getter 检查是否有图片

**数据库表**:
```sql
CREATE TABLE items (
  item_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  price REAL NOT NULL,
  step REAL NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('weighing', 'counting')),
  image_path TEXT  -- 新增: 图片路径
)
```

**数据库版本**: v2 (从 v1 迁移会自动添加 image_path 列)

---

### 5.3 TableItemModel (桌台商品明细)

**文件**: `lib/models/log_model.dart`

```dart
class TableItemModel {
  final int tableId;        // 桌台ID
  final String itemId;      // 商品ID
  final double quantity;    // 当前数量
  final DateTime updatedAt; // 更新时间
}
```

**数据库表**:
```sql
CREATE TABLE table_items (
  table_id INTEGER NOT NULL,
  item_id TEXT NOT NULL,
  quantity REAL NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (table_id, item_id),
  FOREIGN KEY (table_id) REFERENCES tables(table_id),
  FOREIGN KEY (item_id) REFERENCES items(item_id)
)
```

---

### 5.4 LogModel (操作日志)

**文件**: `lib/models/log_model.dart`

```dart
class LogModel {
  final int id;             // 主键 (自增)
  final int tableId;        // 桌台ID
  final String itemId;      // 商品ID
  final double delta;       // 变化量 (正数=添加, 负数=移除)
  final DateTime timestamp; // 时间戳
}
```

**数据库表**:
```sql
CREATE TABLE ops_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id INTEGER NOT NULL,
  item_id TEXT NOT NULL,
  delta REAL NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (table_id) REFERENCES tables(table_id),
  FOREIGN KEY (item_id) REFERENCES items(item_id)
)
```

---

## 6. 存储架构

### 6.1 架构设计

项目采用**接口抽象 + 平台适配**的存储架构：

```
┌─────────────────────────────────────┐
│          TableProvider              │
│      (状态管理层，不直接操作存储)      │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│       StorageService (接口)          │
│   getAllTables(), createTable()...  │
└───────────────┬─────────────────────┘
                │
        ┌───────┴───────┐
        ▼               ▼
┌───────────────┐ ┌───────────────┐
│DatabaseHelper │ │ MemoryStorage │
│   (SQLite)    │ │  (In-Memory)  │
│  移动端/桌面   │ │    Web端      │
└───────────────┘ └───────────────┘
```

### 6.2 StorageService 接口

**文件**: `lib/services/storage_service.dart`

```dart
abstract class StorageService {
  // 桌台操作
  Future<List<TableModel>> getAllTables();
  Future<TableModel?> getTable(int tableId);
  Future<void> createTable(int tableId);
  Future<void> updateTableStatus(int tableId, String status);
  Future<void> clearTable(int tableId);

  // 商品操作
  Future<List<ItemModel>> getAllItems();
  Future<ItemModel?> getItem(String itemId);
  Future<void> addItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem(String itemId);

  // 桌台商品操作
  Future<List<TableItemModel>> getTableItems(int tableId);
  Future<TableItemModel?> getTableItem(int tableId, String itemId);
  Future<void> updateTableItemQuantity(int tableId, String itemId, double delta);
  Future<double> getTableTotal(int tableId);

  // 日志操作
  Future<List<LogModel>> getTableLogs(int tableId, {int limit = 50});
  Future<List<LogModel>> getAllLogs({int limit = 100});
  Future<void> undoLastOperation(int tableId);
}
```

### 6.3 平台适配

**文件**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web 平台使用内存存储
    await MemoryStorage.instance.initialize();
  } else {
    // 移动端/桌面使用 SQLite
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}
```

**Provider 初始化**:
```dart
// lib/providers/table_provider.dart
TableProvider() {
  if (kIsWeb) {
    _db = MemoryStorage.instance;
  } else {
    _db = DatabaseHelper.instance;
  }
}
```

### 6.4 默认数据

首次启动时自动插入以下默认商品：

| ID | 名称 | 单位 | 单价 | 步长 | 分类 |
|----|------|------|------|------|------|
| item_cola | 可乐 | 瓶 | 5.0 | 1.0 | counting |
| item_water | 矿泉水 | 瓶 | 3.0 | 1.0 | counting |
| item_rice | 米饭 | 碗 | 2.0 | 1.0 | counting |
| item_fish | 招牌酸菜鱼 | kg | 68.0 | 0.5 | weighing |
| item_vegetable | 娃娃菜 | 斤 | 12.0 | 0.5 | weighing |

---

## 7. 状态管理

### 7.1 Provider 架构

使用 `provider` 包进行全局状态管理：

```dart
// lib/main.dart
ChangeNotifierProvider(
  create: (context) => TableProvider(),
  child: MaterialApp(...),
)
```

### 7.2 TableProvider 状态

**文件**: `lib/providers/table_provider.dart`

```dart
class TableProvider extends ChangeNotifier {
  // 存储服务
  late final StorageService _db;

  // 状态数据
  List<TableModel> _tables = [];           // 所有桌台
  List<ItemModel> _items = [];             // 所有商品
  Map<int, List<TableItemModel>> _tableItems = {};  // 桌台商品
  Map<int, double> _tableTotals = {};      // 桌台金额
  Map<int, List<LogModel>> _tableLogs = {}; // 操作日志
  Map<int, bool> _hasPendingVoiceMemo = {}; // 语音备忘 (预留)

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;
}
```

### 7.3 主要方法

| 方法 | 说明 |
|------|------|
| `initialize()` | 初始化，加载所有桌台和商品 |
| `createTable(tableId)` | 创建新桌台 |
| `loadTableData(tableId)` | 加载指定桌台的数据 |
| `addItemToTable(tableId, itemId)` | 添加商品到桌台 |
| `removeItemFromTable(tableId, itemId)` | 从桌台移除商品 |
| `addCustomQuantity(tableId, itemId, quantity)` | 添加自定义数量 |
| `undoLastOperation(tableId)` | 撤销最后一次操作 |
| `clearTable(tableId)` | 清空桌台 (结账) |
| `updateTableCount(newCount)` | 更新桌台总数量 (新增) |
| `addNewItem(item)` | 添加新商品 (新增) |
| `updateExistingItem(item)` | 更新现有商品 (新增) |
| `deleteExistingItem(itemId)` | 删除商品 (新增) |

### 7.4 设置状态

```dart
class TableProvider extends ChangeNotifier {
  // 设置相关
  int _tableCount = 12;                    // 桌台数量设置
  static const String _tableCountKey = 'table_count'; // SharedPreferences key
}
```

**设置持久化**:
- 使用 `shared_preferences` 存储 `tableCount`
- 应用启动时自动加载设置

### 7.4 使用示例

```dart
// 在 Widget 中获取 Provider
final provider = context.read<TableProvider>();

// 监听变化
Consumer<TableProvider>(
  builder: (context, provider, child) {
    return Text('Total: ${provider.getTableTotal(tableId)}');
  },
)
```

---

## 8. 页面与路由

### 8.1 页面结构

```
HomeScreen (桌台列表)
│
├── AppBar
│   ├── Title: "桌台列表"
│   ├── Settings Button (→ SettingsScreen)
│   └── Refresh Button
│
├── Body: GridView of TableCards
│   └── TableCard × N
│       ├── 桌号
│       ├── 状态 (空闲/用餐中)
│       ├── 金额
│       └── 语音备忘标记 (预留)
│
└── FAB: 新增桌台
```

```
TableDetailScreen (桌台详情)
│
├── AppBar
│   ├── Title: "X号桌详情"
│   └── 查看账单按钮
│
├── Body
│   ├── TotalAmountDisplay (金额显示)
│   └── GridView of LargeItemCards (商品卡片)
│       ├── 商品名称
│       ├── 单价/单位
│       ├── 当前数量
│       └── +/- 按钮 (计数类) 或 点击输入 (称重类)
│
└── BottomActionBar
    ├── 撤销按钮
    └── 结账按钮
```

```
SettingsScreen (设置页面)
│
├── AppBar
│   └── Title: "设置"
│
└── Body: ListView
    ├── 桌台设置
    │   └── 桌台数量配置 (TextField + 应用按钮)
    ├── 菜单管理
    │   └── 商品管理入口 (→ ItemManagementScreen)
    └── 关于
        └── 应用信息
```

```
ItemManagementScreen (商品管理页面)
│
├── AppBar
│   └── Title: "商品管理"
│
├── Body: ListView
│   ├── 计数类商品分组
│   │   └── ItemCard × N
│   │       ├── 商品信息 (名称、价格、单位、分类)
│   │       ├── 编辑按钮 → _ItemFormDialog
│   │       └── 删除按钮 → 确认对话框
│   └── 称重类商品分组
│       └── ItemCard × N
│
└── FAB: 添加商品 → _ItemFormDialog
```

### 8.2 路由导航

当前使用 Flutter 原生导航：

```dart
// 进入桌台详情
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TableDetailScreen(tableId: tableId),
  ),
);

// 进入设置页面
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SettingsScreen()),
);

// 进入商品管理页面
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ItemManagementScreen()),
);

// 结账后返回首页
Navigator.of(context).pop();
Navigator.of(context).pop();
```

### 8.3 导航流程图

```
HomeScreen
    │
    ├── [TableCard] ──→ TableDetailScreen
    │                           │
    │                           └── [结账] ──→ 返回 HomeScreen
    │
    ├── [Settings] ──→ SettingsScreen
    │                           │
    │                           └── [商品管理] ──→ ItemManagementScreen
    │                                                   │
    │                                                   ├── [添加] ──→ Dialog
    │                                                   ├── [编辑] ──→ Dialog
    │                                                   └── [删除] ──→ 确认 Dialog
    │
    └── [FAB] ──→ Dialog (新增桌台)
```

---

## 9. UI 组件

### 9.1 自定义组件列表

| 组件 | 文件位置 | 说明 |
|------|---------|------|
| `_TableCard` | home_screen.dart | 桌台卡片 |
| `_TotalAmountDisplay` | table_detail_screen.dart | 金额显示 |
| `_LargeItemCard` | table_detail_screen.dart | 商品卡片 (外卖APP风格) |
| `_WeighingKeypadBottomSheet` | table_detail_screen.dart | 称重键盘 |
| `_KeypadButton` | table_detail_screen.dart | 键盘按键 |
| `_BottomActionBar` | table_detail_screen.dart | 底部操作栏 |
| `_CheckoutSummaryScreen` | table_detail_screen.dart | 结账确认页 |
| `_ItemCard` | item_management_screen.dart | 商品管理卡片 |
| `_ItemFormDialog` | item_management_screen.dart | 商品表单对话框 |

### 9.2 商品卡片布局 (_LargeItemCard)

**外卖 APP 风格垂直布局**:
```
┌─────────────────────┐
│                     │
│    图片区域 (4)      │  ← Flex 4: Image.file / 占位图
│   BoxFit.cover      │
│                     │
├─────────────────────┤
│ 商品名称 (加粗)      │
│ ¥价格 / 单位        │  ← Flex 5: 商品信息 + 操作区
│                     │
│ [−]  数量  [+]      │  ← 计数类
│ 或 [重量] [输入]    │  ← 称重类
└─────────────────────┘
```

**样式规范**:
- 卡片阴影: elevation: 4, shadowColor: Colors.black26
- 圆角: 12dp (BorderRadius.circular(12))
- 图片区域: 上圆角，下方直角 (clipBehavior: Clip.antiAlias)
- 文字溢出: TextOverflow.ellipsis

### 9.3 图片上传区域 (_ItemFormDialog)

**100x100 上传区域**:
- 无图片: 灰色背景 + 相机图标 + "点击上传"
- 有图片: 图片预览 + 删除按钮 + 编辑图标

### 9.4 设计规范

**颜色**:
- 主色: `Colors.orange`
- 成功/结账: `Colors.green`
- 危险/删除: `Colors.red`
- 金额: `Colors.green.shade700`
- 称重类: `Colors.blue`
- 计数类: `Colors.orange`

**字体大小**:
- 桌号: `headlineSmall` (约 24sp)
- 金额: `headlineMedium` (约 32sp)
- 商品名称: 15sp (加粗)
- 价格: 16-18sp
- 按钮文字: 13-16sp

**响应式**:
- 手机: 2列网格
- 平板 (>600px): 4列网格
- 商品卡片宽高比: 0.75 (垂直布局)

---

## 10. 开发指南

### 10.1 环境要求

- Flutter SDK 3.38.9+
- Dart SDK 3.5.0+
- Android Studio (Android 开发)
- Visual Studio + C++ 桌面开发 (Windows 开发)
- Chrome 浏览器 (Web 开发)

### 10.2 常用命令

```bash
# 获取依赖
flutter pub get

# 运行应用 (Chrome)
flutter run -d chrome

# 运行应用 (Android)
flutter run -d <device_id>

# 构建 APK
flutter build apk --release

# 构建Web
flutter build web --release

# 检查环境
flutter doctor
```

### 10.3 添加新商品

1. 修改 `lib/services/database_helper.dart` 中的 `_insertDefaultItems()` 方法
2. 或通过 UI 调用 `provider.addNewItem(item)`

### 10.4 添加新页面

1. 在 `lib/screens/` 下创建新文件
2. 在 `main.dart` 或现有页面中添加导航

### 10.5 修改数据库结构

1. 更新 `lib/services/database_helper.dart` 中的表定义
2. 增加 `version` 号
3. 在 `onUpgrade()` 中处理迁移逻辑

---

## 11. 注意事项

### 11.1 Web 平台限制

⚠️ **重要**: Web 版本使用**内存存储**，刷新页面数据会丢失！

原因: `sqflite` 不支持 Web 平台，IndexedDB 方案配置复杂。

解决方案:
- Web 版本仅用于开发测试
- 生产环境使用 Android/iOS 版本

### 11.2 数据库初始化

确保在 `main()` 中正确初始化：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 必须首先调用

  if (kIsWeb) {
    await MemoryStorage.instance.initialize();
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}
```

### 11.3 Provider 使用规范

```dart
// ✅ 正确: 读取数据不监听变化
context.read<TableProvider>().initialize();

// ✅ 正确: 监听数据变化
Consumer<TableProvider>(
  builder: (context, provider, child) => ...,
)

// ❌ 错误: 在 build 方法中调用异步方法
@override
Widget build(BuildContext context) {
  context.read<TableProvider>().initialize(); // 不要这样做
}
```

### 11.4 事务操作

涉及多表操作时使用事务：

```dart
await db.transaction((txn) async {
  await txn.update('table_items', ...);
  await txn.insert('ops_log', ...);
  await txn.update('tables', ...);
});
```

### 11.5 Windows 开发

需要安装 Visual Studio 并勾选：
- "使用 C++ 的桌面开发"
- Windows 10/11 SDK

### 11.6 图片功能注意事项

**存储路径**:
- 图片存储在应用文档目录：`{getApplicationDocumentsDirectory()}/item_images/`
- 文件名格式：`item_{uuid}.jpg`
- ⚠️ 不要使用临时路径，应用重启后图片会丢失

**平台限制**:
- Web 平台不支持图片上传（使用 `kIsWeb` 检测）
- Web 平台显示占位图标

**文件清理**:
- 删除商品时需手动删除关联图片
- 编辑商品更换图片时需删除旧图片

**权限配置**:
- Android: `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`
- iOS: `NSPhotoLibraryUsageDescription`

**图片规格**:
- 最大尺寸: 512x512
- 压缩质量: 85%
- 支持格式: JPG

---

## 12. 未来扩展

### 12.1 计划中的功能

| 功能 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| 语音备忘 | 中 | 🔄 占位完成 | Section 3.2.1，待实现录音功能 |
| 商品管理页面 | 高 | ✅ 已完成 | 添加/编辑/删除商品 |
| 设置页面 | 中 | ✅ 已完成 | 桌台数量配置 |
| 商品图片上传 | 高 | ✅ 已完成 | 图片选择、存储、展示 |
| 数据导出 | 中 | 📋 待开发 | CSV/JSON 格式 |
| 打印小票 | 低 | 📋 待开发 | 蓝牙/USB 打印机 |
| 主题设置 | 低 | 📋 待开发 | 深色/浅色模式 |

### 12.2 架构扩展点

1. **添加新的存储实现**:
   - 实现 `StorageService` 接口
   - 在 `TableProvider` 构造函数中切换

2. **添加语音功能**:
   - 参考 `TableProvider` 中的 `startVoiceMemo()` 等占位方法
   - 使用 `flutter_sound` 实现

3. **添加云同步**:
   - 创建 `CloudStorageService` 实现
   - 添加用户认证模块

### 12.3 性能优化建议

- 大量桌台时考虑分页加载
- 商品列表使用 `ListView.builder`
- 图片资源使用缓存

---

## 附录

### A. 相关文档

- [Development Plan.md](./Development%20Plan.md) - 开发计划
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Provider 包文档](https://pub.dev/packages/provider)
- [SQLite 包文档](https://pub.dev/packages/sqflite)

### B. 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2025-02 | 1.2.0 | 新增图片功能：商品图片上传、存储、展示；UI重构为外卖APP风格卡片 |
| 2025-02 | 1.1.0 | 新增管理功能：设置页面、商品管理页面、SharedPreferences 持久化 |
| 2025-02 | 1.0.0 | 初始版本，完成 MVP 功能 |

---

*文档维护: 开发团队*
*如有问题请参考 Development Plan.md 或联系开发者*

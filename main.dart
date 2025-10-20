
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const ShopTidyApp());
}

/* =========================
   Theme & App Entry
   ========================= */
class AppTheme {
  static const Color primaryGreen = Color(0xFFBFD9B0);
  static const Color darkGreen = Color(0xFF61734F);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
}

class ShopTidyApp extends StatelessWidget {
  const ShopTidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopTidy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.primaryGreen,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppTheme.primaryGreen,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

/* =========================
   Models
   ========================= */
class ItemModel {
  String id;
  String name;
  String brand;
  String category;
  String storage;
  int quantity;
  DateTime? expiry;
  String notes;
  String status; // fresh / expiring / expired

  ItemModel({
    required this.id,
    required this.name,
    this.brand = '',
    this.category = 'Uncategorized',
    this.storage = 'Dry storage',
    this.quantity = 1,
    this.expiry,
    this.notes = '',
    this.status = 'fresh',
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      storage: json['storage'] ?? 'Dry storage',
      quantity: (json['quantity'] ?? 1) as int,
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'fresh',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'storage': storage,
        'quantity': quantity,
        'expiry': expiry?.toIso8601String(),
        'notes': notes,
        'status': status,
      };

  static List<ItemModel> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final List decoded = json.decode(jsonString) as List;
    return decoded.map((e) => ItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ItemModel> list) {
    final encoded = list.map((e) => e.toJson()).toList();
    return json.encode(encoded);
  }
}

/* =========================
   Local Storage (SharedPreferences)
   ========================= */
class LocalStorage {
  static late SharedPreferences _prefs;
  static const String _itemsKey = 'shoptidy_items';
  static const String _shoppingKey = 'shoptidy_shopping';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey(_itemsKey)) {
      final sample = [
        ItemModel(
          id: '1',
          name: 'Milk',
          category: 'Dairy and Eggs',
          quantity: 1,
          expiry: DateTime.now().add(const Duration(days: 10)),
          status: 'fresh',
        ),
        ItemModel(
          id: '2',
          name: 'Eggs',
          category: 'Meat & Protein',
          quantity: 12,
          expiry: DateTime.now().subtract(const Duration(days: 2)),
          status: 'expired',
        ),
        ItemModel(
          id: '3',
          name: 'Rice',
          category: 'Grains & Pasta',
          quantity: 1,
          expiry: DateTime.now().add(const Duration(days: 4)),
          status: 'expiring',
        ),
      ];
      await saveItems(sample);
    }
  }

  static List<ItemModel> loadItems() {
    final jsonString = _prefs.getString(_itemsKey);
    return ItemModel.listFromJson(jsonString);
  }

  static Future<void> saveItems(List<ItemModel> items) async {
    await _prefs.setString(_itemsKey, ItemModel.listToJson(items));
  }

  static List<Map<String, dynamic>> loadShoppingList() {
    final s = _prefs.getString(_shoppingKey);
    if (s == null || s.isEmpty) return [];
    final List decoded = json.decode(s) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> saveShoppingList(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_shoppingKey, json.encode(list));
  }
}

/* =========================
   Main Navigation (Bottom Nav)
   ========================= */
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PantryScreen(),
    RecipeScreen(),
    ShoppingListScreen(),
    NotificationScreen(),
    SharingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
        ],
      ),
    );
  }
}

/* =========================
   Pantry Screen (Main)
   ========================= */
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<ItemModel> items = [];
  String selectedCategory = 'All';
  final categories = [
    'All',
    'Meat & Protein',
    'Dairy and Eggs',
    'Vegetables',
    'Fruits',
    'Canned Goods',
    'Frozen Foods',
    'Grains & Pasta',
    'Snacks',
    'Baking & Sweets',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    items = LocalStorage.loadItems();
    _updateStatuses();
    setState(() {});
  }

  void _updateStatuses() {
    final now = DateTime.now();
    for (var it in items) {
      if (it.expiry == null) {
        it.status = 'fresh';
      } else {
        final diff = it.expiry!.difference(now).inDays;
        if (diff < 0) it.status = 'expired';
        else if (diff <= 5) it.status = 'expiring';
        else it.status = 'fresh';
      }
    }
    LocalStorage.saveItems(items);
  }

  void _openAdd([ItemModel? editItem]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(item: editItem),
      ),
    );
    if (result == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 'All'
        ? items
        : items.where((e) => e.category == selectedCategory).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        appBar: AppBar(
          title: const Text('ShopTidy'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.black12),
          ),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
          child: Column(
            children: [
              // Search + QR icon (UI only)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search item name...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openAdd(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // category chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final c = categories[idx];
                    final selected = c == selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              // title + list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Pantry Items',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No items', style: TextStyle(color: Colors.white70)))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final it = filtered[idx];
                                  return PantryItemCard(
                                    item: it,
                                    onDelete: () {
                                      items.removeWhere((e) => e.id == it.id);
                                      LocalStorage.saveItems(items);
                                      setState(() {});
                                    },
                                    onTapEdit: () async {
                                      final res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AddItemScreen(item: it)),
                                      );
                                      if (res == true) load();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAdd(),
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}

/* =========================
   Add Item Screen
   ========================= */
class AddItemScreen extends StatefulWidget {
  final ItemModel? item;
  const AddItemScreen({super.key, this.item});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _expiry;
  int _quantity = 1;
  String _storage = 'Dry storage';
  String _category = 'Uncategorized';
  final List<String> categories = [
    'Uncategorized',
    'Meat & Protein',
    'Dairy and Eggs',
    'Vegetables',
    'Fruits',
    'Canned Goods',
    'Frozen Foods',
    'Grains & Pasta',
    'Snacks',
    'Baking & Sweets',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameCtrl.text = widget.item!.name;
      _brandCtrl.text = widget.item!.brand;
      _notesCtrl.text = widget.item!.notes;
      _expiry = widget.item!.expiry;
      _quantity = widget.item!.quantity;
      _storage = widget.item!.storage;
      _category = widget.item!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }
    final items = LocalStorage.loadItems();
    final now = DateTime.now();
    final status = _expiry == null
        ? 'fresh'
        : ((_expiry!.difference(now).inDays < 0)
            ? 'expired'
            : (_expiry!.difference(now).inDays <= 5 ? 'expiring' : 'fresh'));

    if (widget.item != null) {
      final idx = items.indexWhere((e) => e.id == widget.item!.id);
      if (idx != -1) {
        items[idx] = ItemModel(
          id: widget.item!.id,
          name: name,
          brand: _brandCtrl.text,
          category: _category,
          storage: _storage,
          quantity: _quantity,
          expiry: _expiry,
          notes: _notesCtrl.text,
          status: status,
        );
      }
    } else {
      // create id
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      items.add(ItemModel(
        id: id,
        name: name,
        brand: _brandCtrl.text,
        category: _category,
        storage: _storage,
        quantity: _quantity,
        expiry: _expiry,
        notes: _notesCtrl.text,
        status: status,
      ));
    }

    await LocalStorage.saveItems(items);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null && mounted) setState(() => _expiry = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('ADD ITEM'),
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name', hintText: 'Name of the item'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(labelText: 'Brand', hintText: 'Brand'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Enter barcode (UI simulation)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleSmall(label: 'Dry storage', selected: _storage == 'Dry storage', onTap: () => setState(() => _storage = 'Dry storage')),
                ToggleSmall(label: 'Freezer', selected: _storage == 'Freezer', onTap: () => setState(() => _storage = 'Freezer')),
                ToggleSmall(label: 'Fridge', selected: _storage == 'Fridge', onTap: () => setState(() => _storage = 'Fridge')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _category,
                      underline: const SizedBox(),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text('$_quantity'),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_expiry == null ? 'MM/DD/YYYY' : DateFormat.yMMMd().format(_expiry!)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(hintText: 'Notes e.g., opened on Oct 13...'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48)),
              onPressed: _save,
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Simulated Barcode Screen
   ========================= */
class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode'), leading: BackButton(color: Colors.black)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 120, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text('This scanner is a UI simulation. Use manual entry on the add screen to input barcodes.'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: const Text('Enter Manually'),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Pantry Item Card Widget
   ========================= */
class PantryItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onDelete;
  final VoidCallback onTapEdit;

  const PantryItemCard({super.key, required this.item, required this.onDelete, required this.onTapEdit});

  Color _statusColor(String s) {
    switch (s) {
      case 'expired':
        return Colors.red;
      case 'expiring':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  String _formatExpiry(DateTime? d) {
    if (d == null) return '';
    return 'Expiry ${DateFormat.yMMMd().format(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 50,
              decoration: BoxDecoration(color: _statusColor(item.status), borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(item.category + (item.brand.isNotEmpty ? ' • ${item.brand}' : ''), style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(_formatExpiry(item.expiry), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _statusColor(item.status), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    item.status == 'expired' ? 'Expired' : (item.status == 'expiring' ? 'Expiring soon' : 'Fresh'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Small Toggle (used in Add Item)
   ========================= */
class ToggleSmall extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ToggleSmall({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white)),
      ),
    );
  }
}

/* =========================
   Shopping List Screen
   ========================= */
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<Map<String, dynamic>> list = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    list = LocalStorage.loadShoppingList();
    setState(() {});
  }

  void save() => LocalStorage.saveShoppingList(list);

  void addItem() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to shopping list'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Item name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                list.add({'name': nameCtrl.text.trim(), 'qty': 1, 'checked': false});
                save();
                load();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void toggleChecked(int idx) {
    list[idx]['checked'] = !(list[idx]['checked'] as bool);
    save();
    setState(() {});
  }

  void deleteItem(int idx) {
    list.removeAt(idx);
    save();
    setState(() {});
  }

  void changeQty(int idx, int delta) {
    final newQty = (list[idx]['qty'] as int) + delta;
    if (newQty >= 1) list[idx]['qty'] = newQty;
    save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      appBar: AppBar(title: const Text('SHOPPING LIST'), leading: BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('No items'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final it = list[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => toggleChecked(idx),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: it['checked'] ? Colors.green : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(it['name'])),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove), onPressed: () => changeQty(idx, -1)),
                                  Text('${it['qty']}'),
                                  IconButton(icon: const Icon(Icons.add), onPressed: () => changeQty(idx, 1)),
                                ],
                              ),
                              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => deleteItem(idx)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: addItem,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              child: const Text('Add to list'),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Recipe Screen (UI only)
   ========================= */
/* =========================
   Recipe Model
   ========================= */
class RecipeModel {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String time;
  final String difficulty;
  final double rating;

  RecipeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.time,
    required this.difficulty,
    this.rating = 4.5,
  });
}

/* =========================
   Recipe Card Widget
   ========================= */
class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  recipe.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Based on your pantry',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      recipe.time,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.rating.toStringAsFixed(1)} ${recipe.difficulty}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Recipe Screen (Full Design Implementation)
   ========================= */
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  // State for category filtering
  String selectedRecipeCategory = 'All';
  final List<String> recipeCategories = const [
    'All', 'Meat', 'Veggies', 'Pasta', 'Quick Meals', 'Healthy Choices', 'Breakfast', 'Dinner', 'Dessert'
  ];

  // Sample recipe data
  final List<RecipeModel> allRecipes = [
    RecipeModel(
      id: '1',
      name: 'Creamy Carbonara',
      imageUrl: 'ttps://media.istockphoto.com/id/537835940/photo/grilled-shrimp-kababs-with-sriracha-and-lime.jpg?s=612x612&w=is&k=20&c=pIOp-ugRUUAqYlq_smRdg5tp0APQqRLKkGjxNWTY6WY=',
      category: 'Pasta',
      time: '30 mins',
      difficulty: 'Easy',
    ),
    RecipeModel(
      id: '2',
      name: 'Garlic Butter Shrimp',
      imageUrl: 'https://media.istockphoto.com/id/537835940/photo/grilled-shrimp-kababs-with-sriracha-and-lime.jpg?s=612x612&w=is&k=20&c=pIOp-ugRUUAqYlq_smRdg5tp0APQqRLKkGjxNWTY6WY=',
      category: 'Quick Meals',
      time: '20 mins',
      difficulty: 'Easy',
    ),
    RecipeModel(
      id: '3',
      name: 'Chicken and Broccoli Stir-fry',
      imageUrl: 'ttps://media.istockphoto.com/id/537835940/photo/grilled-shrimp-kababs-with-sriracha-and-lime.jpg?s=612x612&w=is&k=20&c=pIOp-ugRUUAqYlq_smRdg5tp0APQqRLKkGjxNWTY6WY=',
      category: 'Healthy Choices',
      time: '25 mins',
      difficulty: 'Medium',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter recipes based on the selected category
    final filteredRecipes = selectedRecipeCategory == 'All'
        ? allRecipes
        : allRecipes.where((recipe) => recipe.category.toLowerCase().contains(selectedRecipeCategory.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: null, // Custom header handled below
      
      body: Column(
        children: [
          // 1. Top Header Section (ShopTidy Title & Divider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Text(
                  'ShopTidy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen, 
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inventory and Expiry Tracker for Home Kitchens',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.grey[300]),
              ],
            ),
          ),

          // 2. Main Content Area (RECIPE SUGGESTION Title, Chips, and List)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECIPE SUGGESTION',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 40, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // **KEY for horizontal scroll**
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: recipeCategories.length,
                      itemBuilder: (context, index) {
                        final category = recipeCategories[index];
                        final isSelected = category == selectedRecipeCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRecipeCategory = category;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recipe List (Vertical Scrolling)
                  filteredRecipes.isEmpty
                      ? const Center(child: Text('No recipes found for this category.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            return RecipeCard(recipe: filteredRecipes[index]);
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Notification Screen (UI only)
   ========================= */
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'Milk expires in 5 days', 'time': '7 hours ago'},
      {'title': 'Added Milo Cereal to shopping list', 'time': '3 hours ago'},
      {'title': 'Share pantry updated', 'time': 'Yesterday'},
      {'title': 'Bread expired yesterday', 'time': 'Yesterday'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      appBar: AppBar(title: const Text('NOTIFICATION'), leading: BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final n = notifications[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none),
                  const SizedBox(width: 12),
                  Expanded(child: Text(n['title']!)),
                  Text(n['time']!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/* =========================
   Sharing Screen (UI only)
   ========================= */
class SharingScreen extends StatelessWidget {
  const SharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = [
      {'title': 'My Pantry', 'role': 'Owner'},
      {'title': "Mommy's Pantry", 'role': 'Member'},
      {'title': 'Sevi', 'role': 'Member'},
    ];
    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      appBar: AppBar(title: const Text('PANTRY SHARING'), leading: BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          itemCount: profiles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final p = profiles[idx];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(p['title']!),
              subtitle: Text(p['role']!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            );
          },
        ),
      ),
    );
  }
}

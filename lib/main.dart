import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const GlobalSearchApp());
class GlobalSearchApp extends StatelessWidget {
  const GlobalSearchApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '全局搜索增强', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true, brightness: Brightness.dark),
    home: const GlobalSearchHomePage());
}

class SearchResult {
  String title, subtitle, type, icon;
  SearchResult({required this.title, required this.subtitle, required this.type, required this.icon});
}

class GlobalSearchHomePage extends StatefulWidget {
  const GlobalSearchHomePage({super.key});
  @override
  State<GlobalSearchHomePage> setState() => _GlobalSearchHomePageState();
}

class _GlobalSearchHomePageState extends State<GlobalSearchHomePage> {
  final _ctrl = TextEditingController();
  List<SearchResult> _results = [];
  List<String> _history = [];
  String _filter = '全部';

  final _allItems = [
    SearchResult(title: '设置', subtitle: '系统设置', type: '应用', icon: '⚙️'),
    SearchResult(title: '浏览器', subtitle: '网页浏览', type: '应用', icon: '🌐'),
    SearchResult(title: '文件管理器', subtitle: '文件管理', type: '应用', icon: '📁'),
    SearchResult(title: '计算器', subtitle: '数学计算', type: '应用', icon: '🔢'),
    SearchResult(title: '终端', subtitle: '命令行', type: '应用', icon: '💻'),
    SearchResult(title: '项目报告.docx', subtitle: '~/Documents/', type: '文件', icon: '📄'),
    SearchResult(title: '照片.jpg', subtitle: '~/Pictures/', type: '文件', icon: '🖼️'),
    SearchResult(title: '音乐.mp3', subtitle: '~/Music/', type: '文件', icon: '🎵'),
    SearchResult(title: 'Wi-Fi设置', subtitle: '管理无线网络', type: '设置', icon: '📶'),
    SearchResult(title: '蓝牙设置', subtitle: '管理蓝牙设备', type: '设置', icon: '🔵'),
    SearchResult(title: '显示设置', subtitle: '调整屏幕亮度', type: '设置', icon: '🖥️'),
    SearchResult(title: '声音设置', subtitle: '调整音量', type: '设置', icon: '🔊'),
    SearchResult(title: '存储管理', subtitle: '查看存储空间', type: '设置', icon: '💾'),
    SearchResult(title: 'Flutter文档', subtitle: 'Dart语言教程', type: '书签', icon: '📚'),
    SearchResult(title: 'GitHub', subtitle: '代码仓库', type: '书签', icon: '🐙'),
  ];

  @override
  void initState() { super.initState(); _loadHistory(); _ctrl.addListener(_search); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('global_search_history');
    if (d != null) setState(() => _history = List<String>.from(json.decode(d)));
  }
  Future<void> _saveHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('global_search_history', json.encode(_history));
  }

  void _search() {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _results = _allItems.where((item) {
      if (_filter != '全部' && item.type != _filter) return false;
      return item.title.toLowerCase().contains(q) || item.subtitle.toLowerCase().contains(q);
    }).toList());
  }

  void _pick(SearchResult r) {
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) { _history.remove(q); _history.insert(0, q); if (_history.length > 20) _history = _history.sublist(0, 20); _saveHistory(); }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('打开: ${r.title}'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(children: [
        Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(28)), child: TextField(controller: _ctrl, autofocus: true, decoration: InputDecoration(hintText: '搜索应用、文件、设置、书签...', prefixIcon: const Icon(Icons.search), suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _search(); }) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)))),
        const SizedBox(height: 8),
        SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: ['全部', '应用', '文件', '设置', '书签'].map((f) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(f, style: const TextStyle(fontSize: 12)), selected: _filter == f, onSelected: (_) { setState(() => _filter = f); _search(); }, visualDensity: VisualDensity.compact))).toList())),
      ])),
      const Divider(height: 1),
      Expanded(child: _ctrl.text.isEmpty ? _buildHistory() : _buildResults()),
    ])));
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('输入关键词搜索', style: TextStyle(color: Colors.grey.shade500))]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('搜索历史', style: TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () { setState(() => _history.clear()); _saveHistory(); }, child: const Text('清除'))])),
      Expanded(child: ListView.builder(itemCount: _history.length, itemBuilder: (ctx, i) => ListTile(leading: const Icon(Icons.history), title: Text(_history[i]), onTap: () { _ctrl.text = _history[i]; _search(); }))),
    ]);
  }

  Widget _buildResults() {
    if (_results.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('没有找到匹配结果', style: TextStyle(color: Colors.grey.shade500))]));
    return ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _results.length, itemBuilder: (ctx, i) {
      final r = _results[i];
      final tc = r.type == '应用' ? Colors.blue : r.type == '文件' ? Colors.orange : r.type == '设置' ? Colors.green : Colors.purple;
      return ListTile(leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: tc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(r.icon, style: const TextStyle(fontSize: 24)))), title: Text(r.title), subtitle: Text(r.subtitle, style: const TextStyle(fontSize: 12)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(r.type, style: TextStyle(fontSize: 11, color: tc))), onTap: () => _pick(r));
    });
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import '../models/layout_config.dart';

class LayoutPreferences {
  static const String _key = 'layout_config';
  
  static Future<void> saveLayout(LayoutConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final String layoutStr = _configToString(config);
    await prefs.setString(_key, layoutStr);
  }
  
  static Future<LayoutConfig> loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final String? layoutStr = prefs.getString(_key);
    if (layoutStr == null) {
      return getDefaultLayout();
    }
    return _stringToConfig(layoutStr);
  }
  
  static String _configToString(LayoutConfig config) {
    String row1Str = config.row1.map((item) => '${item.name}:${item.span}').join(',');
    String row2Str = config.row2.map((item) => '${item.name}:${item.span}').join(',');
    return '$row1Str;$row2Str';
  }
  
  static LayoutConfig _stringToConfig(String str) {
    final rows = str.split(';');
    if (rows.length != 2) return getDefaultLayout();
    
    List<LayoutItem> parseRow(String rowStr) {
      return rowStr.split(',').map((itemStr) {
        final parts = itemStr.split(':');
        if (parts.length != 2) return const LayoutItem(name: 'VitalStats', span: 1);
        return LayoutItem(
          name: parts[0],
          span: int.tryParse(parts[1]) ?? 1,
        );
      }).toList();
    }
    
    return LayoutConfig(
      row1: parseRow(rows[0]),
      row2: parseRow(rows[1]),
    );
  }
  
  static LayoutConfig getDefaultLayout() {
    return const LayoutConfig(
      row1: [
        LayoutItem(name: 'VitalStats', span: 3),
        LayoutItem(name: 'Paracetamol', span: 1),
      ],
      row2: [
        LayoutItem(name: 'Breathing', span: 2),
        LayoutItem(name: 'Osteoporosis', span: 2),
      ],
    );
  }
} 
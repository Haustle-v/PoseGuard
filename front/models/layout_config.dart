class LayoutItem {
  final String name;
  final int span;

  const LayoutItem({
    required this.name,
    required this.span,
  });
}

class LayoutConfig {
  final List<LayoutItem> row1;
  final List<LayoutItem> row2;

  const LayoutConfig({
    required this.row1,
    required this.row2,
  });
} 
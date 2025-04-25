import 'package:flutter/material.dart';
import '../models/layout_config.dart';
import 'medication_card.dart';
import 'vital_stats_card.dart';
import 'posture_card.dart';
import 'osteoporosis_card.dart';
import 'breathing_card.dart';

class AdaptiveGrid extends StatelessWidget {
  final LayoutConfig config;
  final Color cardColor;
  final Color primaryColor;

  const AdaptiveGrid({
    super.key,
    required this.config,
    required this.cardColor,
    required this.primaryColor,
  });

  void _showCardDetails(BuildContext context, String name) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + button.size.height + 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '这是 $name 的详细信息',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);

    // 3秒后自动关闭
    Future.delayed(const Duration(seconds: 3), () {
      overlay.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.white, // 移除白色背景
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowSpacing = constraints.maxHeight * 0.04;
          final firstRowHeight = (constraints.maxHeight - rowSpacing) * 0.38;
          final secondRowHeight = (constraints.maxHeight - rowSpacing) * 0.62;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: firstRowHeight,
                child: _buildRow(config.row1, constraints.maxWidth, context),
              ),
              SizedBox(height: rowSpacing),
              SizedBox(
                height: secondRowHeight,
                child: _buildRow(config.row2, constraints.maxWidth, context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(List<LayoutItem> items, double totalWidth, BuildContext context) {
    final totalSpan = items.fold<int>(0, (int sum, item) => sum + item.span);
    final spacing = totalWidth * 0.05;
    final availableWidth = totalWidth - (spacing * (items.length - 1));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          SizedBox(
            width: (availableWidth / totalSpan) * items[i].span,
            child: GestureDetector(
              onTap: () => _showCardDetails(context, items[i].name),
              child: Container(
                decoration: BoxDecoration(
                  color: items[i].name == 'Osteoporosis' 
                    ? Colors.black.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.7),  // 修改卡片背景为半透明
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildCard(items[i].name),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(String name) {
    switch (name) {
      case 'Paracetamol':
        return MedicationCard(
          cardColor: Colors.white.withOpacity(0.7),  // 修改为半透明
          primaryColor: primaryColor,
        );
      case 'VitalStats':
        return PostureCard(
          cardColor: Colors.white.withOpacity(0.7),
          primaryColor: primaryColor,
        );
      case 'Osteoporosis':
        return const OsteoporosisCard();
      case 'ScanCardiology':
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      case 'Breathing':
        return BreathingCard(
          cardColor: Colors.white.withOpacity(0.7),
          primaryColor: primaryColor,
        );
      default:
        return Container();
    }
  }
} 
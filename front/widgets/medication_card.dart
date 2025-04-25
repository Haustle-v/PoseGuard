import 'package:flutter/material.dart';

class MedicationCard extends StatelessWidget {
  final Color cardColor;
  final Color primaryColor;

  const MedicationCard({
    super.key,
    required this.cardColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 获取可用空间的宽度和高度
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // 计算各元素的尺寸比例
        final double iconSizeRatio = 0.18; // 放大图标
        final double titleFontRatio = 0.07; // 放大标题字体
        final double subtitleFontRatio = 0.045; // 放大副标题字体
        
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(width * 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI图标
              Container(
                width: width * iconSizeRatio * 2.2,
                height: width * iconSizeRatio * 2.2,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: width * iconSizeRatio,
                    color: primaryColor,
                  ),
                ),
              ),
              
              SizedBox(height: height * 0.06),
              
              // 标题
              Text(
                '每日健康总结',
                style: TextStyle(
                  fontSize: width * titleFontRatio,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: height * 0.025),
              
              // 副标题
              Text(
                '由AI智能分析您的健康数据',
                style: TextStyle(
                  fontSize: width * subtitleFontRatio,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: height * 0.06),
              
              // 生成按钮
              InkWell(
                onTap: () {
                  // 显示生成中的提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('正在生成每日健康总结...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: width * 0.8,
                  padding: EdgeInsets.symmetric(
                    vertical: height * 0.035,
                    horizontal: width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.8),
                        primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: width * 0.07,
                      ),
                      SizedBox(width: width * 0.03),
                      Text(
                        '生成总结',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
} 
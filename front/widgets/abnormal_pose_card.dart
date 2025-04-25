import 'package:flutter/material.dart';
import '../models/abnormal_pose_record.dart';
import 'package:intl/intl.dart';

class AbnormalPoseCard extends StatelessWidget {
  final AbnormalPoseRecord record;
  
  const AbnormalPoseCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    // 获取有异常的姿势（次数大于0）
    final abnormalPoses = record.getAbnormalPosesWithCount();
    
    // 格式化时间戳
    DateTime dateTime;
    try {
      // 尝试解析时间戳
      dateTime = DateTime.parse(record.timestamp.replaceAll(' ', 'T'));
    } catch (e) {
      // 如果解析失败，使用当前时间
      dateTime = DateTime.now();
      print('时间戳解析失败: ${record.timestamp}, 错误: $e');
    }
    
    final String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
    final String formattedTime = DateFormat('HH:mm:ss').format(dateTime);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间戳
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '$formattedDate $formattedTime',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 异常姿势列表
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: abnormalPoses.entries.map((entry) {
                return _buildAbnormalPoseChip(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbnormalPoseChip(String poseName, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColorForPose(poseName).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getColorForPose(poseName).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poseName,
            style: TextStyle(
              fontSize: 13,
              color: _getColorForPose(poseName),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getColorForPose(poseName).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: _getColorForPose(poseName),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根据姿势类型返回不同的颜色
  Color _getColorForPose(String poseName) {
    switch (poseName) {
      case '头部左倾':
      case '头部右倾':
      case '头部扭曲':
        return Colors.orange;
      case '驼背':
      case '颈部前倾':
        return Colors.red;
      case '手撑下巴':
        return Colors.purple;
      case '身体左倾':
      case '身体右倾':
        return Colors.blue;
      case '肩膀左倾':
      case '肩膀右倾':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 
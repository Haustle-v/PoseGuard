import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/abnormal_pose_record.dart';

class AbnormalPoseService {
  // 单例模式
  static final AbnormalPoseService _instance = AbnormalPoseService._internal();
  factory AbnormalPoseService() => _instance;
  AbnormalPoseService._internal();

  // 缓存所有记录
  List<AbnormalPoseRecord>? _allRecords;

  static const String _jsonPath = 'assets/AbnormalPoseRecord.json';

  // 加载所有异常姿势记录
  Future<List<AbnormalPoseRecord>> loadRecords() async {
    if (_allRecords != null) {
      return _allRecords!;
    }

    try {
      // 读取JSON文件
      final String jsonString = await rootBundle.loadString(_jsonPath);
      
      // 解析JSON数据
      _allRecords = AbnormalPoseRecord.parseRecords(jsonString);
      
      // 按时间戳倒序排序（最新的在前面）
      _allRecords!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return _allRecords!;
    } catch (e) {
      print('加载异常姿势记录失败: $e');
      return [];
    }
  }

  // 获取最近的记录（可选参数：限制数量）
  Future<List<AbnormalPoseRecord>> getRecentRecords({int limit = 10}) async {
    final records = await loadRecords();
    
    // 按时间戳排序（最新的在前）
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // 返回限制数量的记录
    return records.take(limit).toList();
  }

  // 分页获取记录
  Future<List<AbnormalPoseRecord>> getRecordsByPage(int page, int pageSize) async {
    final allRecords = await loadRecords();
    
    final startIndex = page * pageSize;
    if (startIndex >= allRecords.length) {
      return [];
    }
    
    final endIndex = (startIndex + pageSize) < allRecords.length 
        ? (startIndex + pageSize) 
        : allRecords.length;
    
    return allRecords.sublist(startIndex, endIndex);
  }

  // 获取只有异常姿势的记录
  Future<List<AbnormalPoseRecord>> getRecordsWithAbnormalPoses() async {
    final allRecords = await loadRecords();
    return allRecords.where((record) => record.hasAbnormalPoses()).toList();
  }

  // 分页获取只有异常姿势的记录
  Future<List<AbnormalPoseRecord>> getAbnormalRecordsByPage(int page, int pageSize) async {
    final abnormalRecords = await getRecordsWithAbnormalPoses();
    
    final startIndex = page * pageSize;
    if (startIndex >= abnormalRecords.length) {
      return [];
    }
    
    final endIndex = (startIndex + pageSize) < abnormalRecords.length 
        ? (startIndex + pageSize) 
        : abnormalRecords.length;
    
    return abnormalRecords.sublist(startIndex, endIndex);
  }
} 
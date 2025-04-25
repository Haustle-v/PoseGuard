import 'dart:convert';

class AbnormalPoseRecord {
  final String timestamp;
  final int headLeft;
  final int headRight;
  final int hunchback;
  final int chinInHands;
  final int bodyLeft;
  final int bodyRight;
  final int neckForward;
  final int shoulderLeft;
  final int shoulderRight;
  final int twistedHead;

  AbnormalPoseRecord({
    required this.timestamp,
    required this.headLeft,
    required this.headRight,
    required this.hunchback,
    required this.chinInHands,
    required this.bodyLeft,
    required this.bodyRight,
    required this.neckForward,
    required this.shoulderLeft,
    required this.shoulderRight,
    required this.twistedHead,
  });

  factory AbnormalPoseRecord.fromJson(Map<String, dynamic> json) {
    return AbnormalPoseRecord(
      timestamp: json['timestamp'] ?? '',
      headLeft: json['head_left'] ?? 0,
      headRight: json['head_right'] ?? 0,
      hunchback: json['hunchback'] ?? 0,
      chinInHands: json['chin_in_hands'] ?? 0,
      bodyLeft: json['body_left'] ?? 0,
      bodyRight: json['body_right'] ?? 0,
      neckForward: json['neck_forward'] ?? 0,
      shoulderLeft: json['shoulder_left'] ?? 0,
      shoulderRight: json['shoulder_right'] ?? 0,
      twistedHead: json['twisted_head'] ?? 0,
    );
  }

  // 检查是否有任何异常姿势
  bool hasAbnormalPoses() {
    return headLeft > 0 || 
           headRight > 0 || 
           hunchback > 0 || 
           chinInHands > 0 || 
           bodyLeft > 0 || 
           bodyRight > 0 || 
           neckForward > 0 || 
           shoulderLeft > 0 || 
           shoulderRight > 0 || 
           twistedHead > 0;
  }

  // 获取所有异常姿势及其次数
  Map<String, int> getAbnormalPosesWithCount() {
    final Map<String, int> result = {};
    
    if (headLeft > 0) result['头部左倾'] = headLeft;
    if (headRight > 0) result['头部右倾'] = headRight;
    if (hunchback > 0) result['驼背'] = hunchback;
    if (chinInHands > 0) result['手撑下巴'] = chinInHands;
    if (bodyLeft > 0) result['身体左倾'] = bodyLeft;
    if (bodyRight > 0) result['身体右倾'] = bodyRight;
    if (neckForward > 0) result['颈部前倾'] = neckForward;
    if (shoulderLeft > 0) result['肩膀左倾'] = shoulderLeft;
    if (shoulderRight > 0) result['肩膀右倾'] = shoulderRight;
    if (twistedHead > 0) result['头部扭曲'] = twistedHead;
    
    return result;
  }

  // 从JSON字符串解析记录列表
  static List<AbnormalPoseRecord> parseRecords(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => AbnormalPoseRecord.fromJson(json)).toList();
  }
} 
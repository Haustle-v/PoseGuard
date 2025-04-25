import 'package:flutter/material.dart';
import '../models/abnormal_pose_record.dart';
import '../services/abnormal_pose_service.dart';
import '../widgets/abnormal_pose_card.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with AutomaticKeepAliveClientMixin {
  final AbnormalPoseService _poseService = AbnormalPoseService();
  final ScrollController _scrollController = ScrollController();
  
  List<AbnormalPoseRecord> _records = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _isInitialized = false;
  
  // 保持页面状态
  @override
  bool get wantKeepAlive => false; // 设置为false，不保留状态，每次都重新创建
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  // 初始化数据
  void _initializeData() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadMoreRecords();
      
      // 添加滚动监听器，实现滚动到底部自动加载更多
      _scrollController.addListener(_scrollListener);
    }
  }
  
  // 滚动监听器函数
  void _scrollListener() {
    if (!mounted) return;
    
    if (_scrollController.hasClients && 
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMoreRecords();
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保在依赖变化时也检查初始化
    _initializeData();
  }
  
  @override
  void dispose() {
    // 移除滚动监听器
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _isInitialized = false;
    super.dispose();
  }
  
  // 重置页面状态
  void _resetPageState() {
    if (!mounted) return;
    
    setState(() {
      _records = [];
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMoreRecords();
  }
  
  // 加载更多记录
  Future<void> _loadMoreRecords() async {
    if (_isLoading || !_hasMore || !mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newRecords = await _poseService.getAbnormalRecordsByPage(_currentPage, _pageSize);
      
      if (!mounted) return;
      
      setState(() {
        _records.addAll(newRecords);
        _currentPage++;
        _hasMore = newRecords.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载记录失败: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '异常姿势列表',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _resetPageState,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading && _records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '没有异常姿势记录',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '保持良好姿势，继续加油！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              return AbnormalPoseCard(record: _records[index]);
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (!_isLoading && _hasMore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _loadMoreRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text('加载更多'),
            ),
          ),
      ],
    );
  }
} 
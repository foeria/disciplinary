import 'package:flutter/material.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_button.dart';

/// 数据格式
enum ExportFormat {
  json,
  csv,
  pdf,
}

/// 导出页面
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late ExportFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = ExportFormat.json;
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON 格式 - 适合程序处理和备份';
      case ExportFormat.csv:
        return 'CSV 格式 - 适合 Excel 查看和分析';
      case ExportFormat.pdf:
        return 'PDF 格式 - 适合打印和分享';
    }
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.code;
      case ExportFormat.csv:
        return Icons.table_chart_outlined;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  Color _getFormatColor(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return const Color(0xFFFF6B9D);
      case ExportFormat.csv:
        return const Color(0xFF7EB8DA);
      case ExportFormat.pdf:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '导出数据',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 导出说明
              _buildDescription(),
              const SizedBox(height: 24),
              // 选择格式
              const Text(
                '选择导出格式',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              ...ExportFormat.values.map((format) => _buildFormatOption(format)),
              const SizedBox(height: 32),
              // 导出按钮
              SizedBox(
                width: double.infinity,
                child: AnimeButton(
                  text: '导出数据',
                  icon: Icons.download_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据导出成功')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 导入按钮
              SizedBox(
                width: double.infinity,
                child: AnimeOutlinedButton(
                  text: '导入数据',
                  icon: Icons.upload_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导入功能将在正式版本中开放')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // 数据说明
              _buildDataInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFFFF6B9D),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据导出',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '导出您的使用数据作为备份，可以在其他设备上导入恢复',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(ExportFormat format) {
    final isSelected = _selectedFormat == format;
    final color = _getFormatColor(format);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = format),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFormatIcon(format),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormatDescription(format),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo() {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storage_outlined, color: Color(0xFF666666), size: 20),
              SizedBox(width: 8),
              Text(
                '包含的数据',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataItem('应用使用记录'),
          _buildDataItem('使用时间统计'),
          _buildDataItem('解锁历史'),
          _buildDataItem('题库内容'),
          _buildDataItem('设置偏好'),
        ],
      ),
    );
  }

  Widget _buildDataItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Color(0xFF43A047), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

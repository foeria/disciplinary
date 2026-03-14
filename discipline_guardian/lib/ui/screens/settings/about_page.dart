import 'package:flutter/material.dart';
import '../../widgets/anime_card.dart';

/// 关于页面
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          '关于',
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
            children: [
              // 应用图标和名称
              _buildAppInfo(),
              const SizedBox(height: 24),
              // 版本信息
              _buildVersionInfo(),
              const SizedBox(height: 24),
              // 链接
              _buildLinks(),
              const SizedBox(height: 24),
              // 版权信息
              _buildCopyright(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '自律守护者',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Discipline Guardian',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow('版本', 'v1.0.0'),
          const Divider(height: 24),
          _buildInfoRow('构建', '2026.03.07'),
          const Divider(height: 24),
          _buildInfoRow('Flutter', '3.41.4'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildLinks() {
    return Column(
      children: [
        _buildLinkItem(
          icon: Icons.privacy_tip_outlined,
          title: '隐私政策',
          subtitle: '了解我们如何保护您的数据',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildLinkItem(
          icon: Icons.description_outlined,
          title: '服务条款',
          subtitle: '使用本应用的服务条款',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildLinkItem(
          icon: Icons.mail_outline,
          title: '联系我们',
          subtitle: 'support@discipline-guardian.com',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return AnimeCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B9D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyright() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.copyright,
            color: Color(0xFF999999),
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 自律守护者',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '保留所有权利',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

}

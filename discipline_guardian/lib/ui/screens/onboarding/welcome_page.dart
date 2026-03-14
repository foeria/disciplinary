import 'package:flutter/material.dart';
import '../../widgets/anime_button.dart';

/// 引导页数据模型
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

/// 引导流程页面
class WelcomePage extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomePage({
    super.key,
    required this.onComplete,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: '自律守护者',
      description: '帮助您远离手机沉迷，\n培养健康的使用习惯',
      icon: Icons.shield_outlined,
      iconColor: Color(0xFFFF6B9D),
    ),
    OnboardingPage(
      title: '时间监控',
      description: '精确记录应用使用时间，\n了解自己的数字生活',
      icon: Icons.timer_outlined,
      iconColor: Color(0xFF7EB8DA),
    ),
    OnboardingPage(
      title: '智能锁定',
      description: '到达使用时限自动锁定，\n帮助您放下手机',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF9B8FD4),
    ),
    OnboardingPage(
      title: '知识问答解锁',
      description: '通过题库问答完成解锁，\n数学题也会作为题库内容出现',
      icon: Icons.key_outlined,
      iconColor: Color(0xFF5CB85C),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            // 引导页面
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // 指示器和按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 按钮
                  SizedBox(
                    width: double.infinity,
                    child: AnimeButton(
                      text: _currentPage == _pages.length - 1 ? '开始使用' : '下一步',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标容器
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: 48),
          // 标题
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 描述
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

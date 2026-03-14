import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

/// 主题页面
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  late ThemeType _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = AppTheme.currentTheme;
  }

  Future<void> _applyTheme() async {
    final appState = DisciplineGuardianApp.of(context);
    if (appState == null) {
      return;
    }
    await appState.applyTheme(_selectedTheme);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换为 ${AppTheme.getThemeName(_selectedTheme)}')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.gradientColorsFor(_selectedTheme);
    final primary = AppTheme.primaryColorFor(_selectedTheme);

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
          '主题设置',
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
              _buildPreview(primary, gradient),
              const SizedBox(height: 32),
              const Text(
                '选择主题',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AppTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final themeType = AppTheme.allThemes[index];
                  final isSelected = _selectedTheme == themeType;
                  return _buildThemeCard(
                    themeType,
                    AppTheme.getThemeName(themeType),
                    AppTheme.gradientColorsFor(themeType),
                    isSelected,
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AnimeButton(
                  text: '应用主题',
                  gradientColors: gradient,
                  onPressed: _applyTheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(Color primary, List<Color> gradient) {
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      borderColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '主按钮',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前选择：${AppTheme.getThemeName(_selectedTheme)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    ThemeType type,
    String name,
    List<Color> gradient,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? gradient[0] : Colors.transparent,
            width: 3,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? gradient[0] : const Color(0xFF333333),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF43A047),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

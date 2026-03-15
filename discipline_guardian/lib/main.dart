import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/events/app_events.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_model.dart';
import 'services/local_backend_service.dart';
import 'ui/screens/apps/apps_page.dart';
import 'ui/screens/home/home_page.dart';
import 'ui/screens/lock/lock_screen.dart';
import 'ui/screens/onboarding/complete_page.dart';
import 'ui/screens/onboarding/permission_page.dart';
import 'ui/screens/onboarding/welcome_page.dart';
import 'ui/screens/settings/settings_page.dart';
import 'ui/screens/stats/stats_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisciplineGuardianApp());
}

/// 自律守护者应用
class DisciplineGuardianApp extends StatefulWidget {
  const DisciplineGuardianApp({super.key});

  static DisciplineGuardianAppController? of(BuildContext context) {
    return context.findAncestorStateOfType<_DisciplineGuardianAppState>();
  }

  @override
  State<DisciplineGuardianApp> createState() => _DisciplineGuardianAppState();
}

abstract class DisciplineGuardianAppController {
  Future<void> applyTheme(ThemeType theme);
}

class _DisciplineGuardianAppState extends State<DisciplineGuardianApp>
    implements DisciplineGuardianAppController {
  final LocalBackendService _backendService = LocalBackendService();
  ThemeType _theme = ThemeType.pink;
  bool _isBootstrapping = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final themeName = await _backendService.getTheme();
    final onboardingCompleted = await _backendService.getOnboardingCompleted();
    final theme = AppTheme.fromStorageValue(themeName);
    AppTheme.setTheme(theme);

    if (!mounted) {
      return;
    }

    setState(() {
      _theme = theme;
      _onboardingCompleted = onboardingCompleted;
      _isBootstrapping = false;
    });
  }

  @override
  Future<void> applyTheme(ThemeType theme) async {
    await _backendService.setTheme(AppTheme.toStorageValue(theme));
    AppTheme.setTheme(theme);
    if (!mounted) {
      return;
    }
    setState(() {
      _theme = theme;
    });
  }

  Future<void> completeOnboarding() async {
    await _backendService.setOnboardingCompleted(true);
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自律守护者',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeDataFor(_theme),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: _isBootstrapping
          ? const _BootstrapScreen()
          : (_onboardingCompleted
                ? const MainNavigator()
                : OnboardingFlow(onComplete: completeOnboarding)),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onComplete,
  });

  final Future<void> Function() onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;

  void _nextStep() {
    if (!mounted) {
      return;
    }
    setState(() {
      _step += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return WelcomePage(onComplete: _nextStep);
      case 1:
        return PermissionPage(
          onGranted: _nextStep,
          onSkip: _nextStep,
        );
      default:
        return CompletePage(
          onComplete: () => unawaited(widget.onComplete()),
        );
    }
  }
}

/// 主导航器 - 底部导航栏
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final LocalBackendService _backendService = LocalBackendService();
  Timer? _monitorTimer;
  StreamSubscription<String>? _promptSignalSubscription;
  bool _monitoringInProgress = false;
  bool _rerunMonitorAfterCurrentPass = false;
  bool _isAutoLockVisible = false;
  final Map<String, DateTime> _unlockCooldownByPackage =
      <String, DateTime>{};
  static const Duration _unlockCooldownWindow = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _promptSignalSubscription = _backendService.watchPromptSignals().listen((_) {
      unawaited(_runMonitorCycle());
    });
    _runMonitorCycle();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _runMonitorCycle(),
    );
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _promptSignalSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runMonitorCycle();
    }
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      AppEvents.notifyHomeRefresh();
    } else if (index == 1) {
      AppEvents.notifyAppsRefresh();
    } else if (index == 2) {
      AppEvents.notifyStatsRefresh();
    }
    _runMonitorCycle();
  }

  Future<void> _runMonitorCycle() async {
    if (!mounted) {
      return;
    }
    if (_monitoringInProgress) {
      _rerunMonitorAfterCurrentPass = true;
      return;
    }

    _monitoringInProgress = true;
    try {
      final promptPackage = _isAutoLockVisible
          ? null
          : await _backendService.consumePromptPackage();

      final result = await _backendService.syncTodayUsageWithRules();
      final accessibilityGranted =
          await _backendService.isAccessibilityPermissionGranted();
      await _backendService.setNativeInterceptionEnabled(accessibilityGranted);
      await _backendService.syncNativeInterceptionRules();

      if (
        await _consumeAndPresentPendingPrompt(
          promptPackage: promptPackage,
          newlyLockedApps: result.newlyLockedApps,
        )
      ) {
        return;
      }

      if (!mounted || _isAutoLockVisible || result.newlyLockedApps.isEmpty) {
        return;
      }
    } catch (_) {
      // Ignore monitor cycle failures to avoid interrupting the main UI.
    } finally {
      _monitoringInProgress = false;
      if (_rerunMonitorAfterCurrentPass && mounted) {
        _rerunMonitorAfterCurrentPass = false;
        unawaited(_runMonitorCycle());
      }
    }
  }

  Future<bool> _consumeAndPresentPendingPrompt({
    required String? promptPackage,
    required List<AppModel> newlyLockedApps,
  }) async {
    if (_isAutoLockVisible || promptPackage == null || promptPackage.isEmpty) {
      return false;
    }

    if (_isPromptDebounced(promptPackage)) {
      await _backendService.resetPromptState(promptPackage);
      await _returnToHome();
      return true;
    }

    final promptApp =
        newlyLockedApps.cast<AppModel?>().firstWhere(
              (app) => app?.packageName == promptPackage,
              orElse: () => null,
            ) ??
        await _backendService.getLockedAppByPackageName(promptPackage);
    if (promptApp == null) {
      await _backendService.resetPromptState(promptPackage);
      await _returnToHome();
      return true;
    }

    await _presentAutoLockScreen(promptApp);
    return true;
  }

  bool _isPromptDebounced(String packageName) {
    final now = DateTime.now();
    final cooldownUntil = _unlockCooldownByPackage[packageName];
    if (cooldownUntil != null && now.isBefore(cooldownUntil)) {
      return true;
    }

    return false;
  }

  Future<void> _presentAutoLockScreen(AppModel app) async {
    if (!mounted) {
      return;
    }

    _isAutoLockVisible = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LockScreen(
          appName: app.appName,
          usedMinutes: app.usedMinutesToday,
          limitMinutes: app.dailyLimitMinutes,
          unlockMethod: UnlockMethod.question,
          onUnlockSuccess: () async {
            await _backendService.unlockApp(app.id);
            await _backendService.incrementUnlockQuestionCountAfterSuccess();
            await _backendService.syncNativeInterceptionRules();
            _unlockCooldownByPackage[app.packageName] =
                DateTime.now().add(_unlockCooldownWindow);
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop();
            await Future<void>.delayed(const Duration(milliseconds: 120));
            final launched =
                await _backendService.launchAppByPackage(app.packageName);
            if (!launched) {
              await _returnToHome();
            }
          },
          onExitRequested: () async {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop();
            await _returnToHome();
          },
        ),
      ),
    );
    _isAutoLockVisible = false;
  }

  Future<void> _returnToHome() async {
    final sentHome = await _backendService.openHomeScreen();
    if (!sentHome) {
      await _backendService.moveGuardianToBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onSwitchToTab: _switchTab),
          const AppsPage(),
          const StatsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps),
            label: '应用',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

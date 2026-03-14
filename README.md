# 自律守护者 (Discipline Guardian)

一款卡通动漫风格的自律养成类手机应用。核心功能是监控用户使用特定应用的时间，超时后自动锁定，需要通过预设的解锁方式（密码 / 知识问答 / 数学题 / 延迟等待）才能解除锁定。

---

## 环境要求

| 工具 | 最低版本 | 说明 |
|------|---------|------|
| Flutter SDK | 3.x | `flutter --version` 查看 |
| Dart SDK | 3.11+ | 随 Flutter 一起安装 |
| Android Studio | 2023+ | 含 Android SDK 34+ |
| Java (JDK) | 17 | Gradle 构建需要 |

> **Windows 用户**：确保 `flutter` 和 `dart` 已加入系统 `PATH`，可在终端运行 `flutter doctor` 一键检查所有依赖。

---

## 快速开始

### 1. 克隆项目

```bash
git clone <repo-url>
cd disciplinary
```

### 2. 安装依赖

```bash
cd discipline_guardian
flutter pub get
```

### 3. 检查环境

```bash
flutter doctor -v
```

确认输出中 **Android toolchain** 和 **Connected device** 均无 ✗。

---

## 启动 & 调试

### 查看可用设备

```bash
flutter devices
```

输出示例：

```
emulator-5554 • Android SDK built for x86 64 • android-x64 • Android 13 (API 33)
```

### 在模拟器 / 真机上运行（Debug 模式）

```bash
# 指定设备 ID 运行（推荐，避免多设备冲突）
flutter run -d emulator-5554

# 如果只有一台设备，可省略 -d 参数
flutter run
```

启动后，终端会输出日志，支持以下热键：

| 按键 | 功能 |
|------|------|
| `r` | 热重载（Hot Reload）—— 保留状态，刷新 UI |
| `R` | 热重启（Hot Restart）—— 重置状态，重启应用 |
| `p` | 显示 UI 布局辅助线框 |
| `o` | 切换 Android / iOS 外观（Widget 渲染平台） |
| `q` | 退出调试 |

### 在 VS Code 中调试

1. 打开 `discipline_guardian/` 文件夹
2. 按 `F5` 或点击 **运行 → 启动调试**
3. 选择目标设备后自动连接，支持断点调试

`.vscode/launch.json` 示例（如不存在可手动创建）：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "discipline_guardian (debug)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug"
    },
    {
      "name": "discipline_guardian (profile)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile"
    }
  ]
}
```

### 在 Android Studio 中调试

1. 打开 `discipline_guardian/` 目录（选择 **Open an existing project**）
2. 等待 Gradle 同步完成
3. 顶栏选择目标设备，点击绿色 **▶ Run** 按钮
4. 使用 **Logcat** 面板过滤日志，建议过滤 Tag：`flutter`

---

## 构建

### Debug APK（用于测试安装）

```bash
flutter build apk --debug
# 产物：build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK（正式发布）

```bash
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle（上传 Google Play）

```bash
flutter build appbundle --release
```

---

## 代码分析

```bash
# 静态分析（无警告才算合格）
flutter analyze

# 运行单元测试
flutter test
```

---

## 项目结构

```
discipline_guardian/
├── lib/
│   ├── main.dart           # 应用入口，IndexedStack 标签导航
│   ├── core/               # 主题、常量、工具类
│   ├── data/               # 数据模型 & 本地存储
│   ├── services/           # 业务服务（监控、锁定等）
│   └── ui/
│       └── screens/
│           ├── home/       # 首页（使用时长概览）
│           ├── apps/       # 应用管理
│           ├── stats/      # 统计图表
│           └── settings/   # 设置及子页面
├── android/                # Android 原生配置
├── ios/                    # iOS 原生配置
└── pubspec.yaml            # 依赖声明
```

---

## 常见问题

**Q: `flutter run` 提示找不到设备**

```bash
# 确认 Android 模拟器已启动
flutter emulators --launch <emulator_id>
# 或开启真机 USB 调试后重新插拔
```

**Q: Gradle 构建失败 / 超时**

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**Q: `flutter doctor` 报告 Android licenses 未接受**

```bash
flutter doctor --android-licenses
# 全部输入 y 接受
```


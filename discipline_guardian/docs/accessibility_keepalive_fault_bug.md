# 无障碍服务故障 Bug 记录

日期：2026-03-28

## 现象

- 主控应用正常启动时，无障碍拦截通常可用。
- 当主控应用被彻底从最近任务中划掉后，再次打开主控应用：
  - 系统设置中的无障碍服务有时会显示“发生故障”。
  - 受控应用无法继续稳定拦截。
- 如果不彻底退出主控，或者重新折腾权限，功能可能暂时恢复。

## 复现路径

1. 打开主控应用，确认无障碍权限已开启。
2. 确认至少有一个受控应用处于可拦截状态。
3. 将主控应用从最近任务中彻底划掉。
4. 重新打开主控应用。
5. 查看系统设置中的无障碍页面，或直接点击受控应用。

## 最终结论

这次问题的根因已经基本确认：

不是一百天计划本身，也不是无障碍拦截主链本身，而是后续新增的 Android 保活链路里的 `dataSync` 前台服务类型改动诱发了问题。

## 为什么会诱发这个问题

核心原因在于：`dataSync` 类型的前台保活服务介入了“主控被划掉后的进程与服务重启时序”，而这个时序刚好和无障碍服务重新绑定的时机重叠。

触发链路大致如下：

1. 用户把主控应用从最近任务中划掉。
2. Android 触发 `GuardianKeepAliveService.onTaskRemoved()`。
3. 保活服务调用 `scheduleRestart()`，尝试尽快重新拉起自身。
4. 如果服务被销毁，还会在 `onDestroy()` 中再次调度重启。
5. `GuardianKeepAliveReceiver` 收到重启广播后，又会尝试重新启动保活服务。
6. 这时应用进程、前台服务、主控 Activity、无障碍服务会同时参与一次重建或重新绑定。
7. 在加入 `dataSync` 前台服务类型后，这个重建过程更激进、更复杂，导致某些 ROM 上无障碍服务绑定状态异常，最终在系统设置里显示“发生故障”。

换句话说，不是无障碍服务本身不会拦截，而是它在“主控被划掉后重建”的这一刻，被额外新增的保活前台服务时序干扰了。

## 直接诱因

当时新增的几个点共同组成了这个诱因：

- `android.permission.FOREGROUND_SERVICE_DATA_SYNC`
- `GuardianKeepAliveService` 的 `android:foregroundServiceType="dataSync"`
- `ServiceCompat.startForeground(..., FOREGROUND_SERVICE_TYPE_DATA_SYNC)`

这些改动本意是增强保活，但在这个项目里，反而放大了“任务移除后立即重启服务”的生命周期扰动。

## 为什么不是一百天计划

一百天计划主要运行在业务层，负责：

- 计算计划是否激活
- 决定计划应用的有效限额
- 决定是否需要 100 题解锁

这些逻辑会影响“锁不锁、限额是多少、解锁题数是多少”，但它们不直接参与 Android 无障碍服务的系统绑定。

因此它可能影响业务结果，但不是这次“无障碍服务发生故障”的核心诱因。

## 这次确认有效的处理方向

保留无障碍相关代码和业务逻辑，只回退保活服务的 `dataSync` 前台服务类型改动：

- 删除 `android.permission.FOREGROUND_SERVICE_DATA_SYNC`
- 删除 `GuardianKeepAliveService` 的 `android:foregroundServiceType="dataSync"`
- 将 `GuardianKeepAliveService` 中的前台启动恢复为普通 `startForeground(...)`

## 当前策略

- 无障碍相关代码保留。
- 一百天计划逻辑保留。
- 基础保活能力保留。
- 不再使用 `dataSync` 类型前台服务。

## 涉及文件

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/discipline/discipline_guardian/GuardianKeepAliveService.kt`
- `android/app/src/main/kotlin/com/discipline/discipline_guardian/GuardianKeepAliveReceiver.kt`
- `android/app/src/main/kotlin/com/discipline/discipline_guardian/GuardAccessibilityService.kt`
- `android/app/src/main/kotlin/com/discipline/discipline_guardian/MainActivity.kt`

## 后续建议

1. 先保持当前稳定实现，不要重新启用 `dataSync` 前台服务类型。
2. 以后每次改保活链路，都重点回归“彻底划掉主控再重进”的路径。
3. 无障碍服务尽量只承担拦截职责，不要再把复杂生命周期调度继续叠加进去。

// v0.16 round 20 (OEM 后台引导)
//
// 设置页「通知与提醒」自检卡。
//
// 三件事：
// 1. 状态显示：当前已排队的待发通知数（0 = 没设上或被 OEM 杀掉）
// 2. 一键自测：点「测试通知」立即推一条，用户看到 = 通知工作正常
// 3. OEM 引导：小米/华为/OPPO/Vivo/魅族 后台限制各不相同，给一份
//    静态文字清单（避免新增 app_settings / android_intent_plus 包）
//
// 设计取舍：
// - 用 `kIsWeb` 判断平台兼容性，比 dart:io 的 Platform 更轻
// - 不跳转到系统设置（避免加包），只给文字 + 路径
// - widget 是 ConsumerStatefulWidget，因为要管理"测试中" busy 状态
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 通知自检卡
class NotificationStatusCard extends ConsumerStatefulWidget {
  const NotificationStatusCard({super.key});

  @override
  ConsumerState<NotificationStatusCard> createState() =>
      _NotificationStatusCardState();
}

class _NotificationStatusCardState
    extends ConsumerState<NotificationStatusCard> {
  int? _pending; // null = 未加载, -1 = 不支持
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 首次进入时刷新一次
    // v0.17 round 14 (Bug-4): 用 unawaited 包 _refresh(),
    // 让 fire-and-forget 意图自描述 (虽然 addPostFrameCallback callback 是 void)
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(notificationServiceProvider);
      final count = await service.pendingCount;
      if (!mounted) return;
      setState(() => _pending = count);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pending = -1);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fireTest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(notificationServiceProvider);
      await service.showNow(
        id: 99001, // 测试用 id,不会跟任何业务通知冲突（_refillBaseId 6000+）
        title: '🔔 通知自检',
        body: '看到这条 = 通知工作正常。如果没看到，看下面的国产手机设置',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已发送测试通知 — 几秒内应该能收到'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(context, action: '发送', error: e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDetails() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 通过 plugin 直接拿完整 list,只展示标题
      final plugin = FlutterLocalNotificationsPlugin();
      List<PendingNotificationRequest> pending = const [];
      try {
        pending = await plugin.pendingNotificationRequests();
      } catch (_) {
        // web 平台抛 PlatformException
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('已排队的通知'),
          content: SizedBox(
            width: double.maxFinite,
            child: pending.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppTokens.spacingMd),
                    child: Text('当前没有任何待发通知。\n'
                        '可能是没设提醒，或被系统后台清理了。'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (_, i) {
                      final p = pending[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(
                          p.title ?? '(无标题)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          p.body ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // web / desktop 平台提示
    if (kIsWeb) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: AppTokens.textHint),
          title: Text('通知功能仅在 Android / iOS 上可用'),
          subtitle: Text(
            '当前是 web 端，通知由浏览器控制。请在手机上打开 App 测试。',
            style: TextStyle(color: AppTokens.textHint),
          ),
        ),
      );
    }

    final pending = _pending;
    final statusText = pending == null
        ? '加载中…'
        : pending < 0
            ? '当前平台不支持查询'
            : pending == 0
                ? '⚠️ 没有待发通知 — 提醒可能没设上'
                : '✓ 已排队 $pending 条待发通知';

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: AppTokens.primary,
            ),
            title: const Text('通知与提醒'),
            // v0.17 round 14 (P2-3): AnimatedSize 让 statusText 切换时
            // 高度平滑过渡 (加载中 → 0 待发 → N 待发) 而不是突然跳变
            subtitle: AnimatedSize(
              duration: AppTokens.durNormal,
              curve: AppTokens.curveStandard,
              alignment: Alignment.topLeft,
              child: Text(statusText),
            ),
            trailing: IconButton(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _busy ? null : _refresh,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.send_outlined, color: AppTokens.primary),
            title: const Text('测试通知'),
            subtitle: const Text('点一下立即推一条，确认通知能正常弹出'),
            onTap: _busy ? null : _fireTest,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.list_alt, color: AppTokens.primary),
            title: const Text('查看已排队通知'),
            subtitle: const Text('展示当前所有待发的提醒'),
            onTap: _busy ? null : _showDetails,
          ),
          const Divider(height: 1),
          // OEM 引导 — 用 ExpansionTile 折叠，不抢主屏空间
          const _OemBackgroundHint(),
        ],
      ),
    );
  }
}

/// 国产手机后台限制引导（静态文字 + 折叠）
class _OemBackgroundHint extends StatelessWidget {
  const _OemBackgroundHint();

  @override
  Widget build(BuildContext context) {
    return Theme(
      // 去掉 ExpansionTile 默认的圆形图标背景，跟整体风格一致
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: const ExpansionTile(
        leading: Icon(Icons.phone_android, color: AppTokens.primary),
        title: Text('国产手机没收到通知?'),
        subtitle: Text(
          '小米/华为/OPPO/Vivo 默认会杀后台，点这里看怎么设',
          style: TextStyle(color: AppTokens.textSecondary, fontSize: 12),
        ),
        childrenPadding: EdgeInsets.fromLTRB(
          AppTokens.spacingMd,
          0,
          AppTokens.spacingMd,
          AppTokens.spacingMd,
        ),
        children: [
          _OemBrand(
            brand: '小米 / Redmi',
            steps: [
              '设置 → 应用 → 慢病管家 → 自启动 → 开启',
              '设置 → 应用 → 慢病管家 → 省电策略 → 无限制',
              '设置 → 通知 → 慢病管家 → 允许通知 + 锁屏通知',
            ],
          ),
          SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: '华为 / 荣耀',
            steps: [
              '设置 → 应用 → 慢病管家 → 电池 → 启动管理 → 允许自启动',
              '设置 → 应用 → 慢病管家 → 通知 → 全部开启',
              '手机管家 → 应用启动管理 → 关闭「自动管理」',
            ],
          ),
          SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: 'OPPO / realme / 一加',
            steps: [
              '设置 → 电池 → 耗电保护 → 慢病管家 → 允许后台运行',
              '设置 → 通知 → 慢病管家 → 全部开启',
              '「最近任务」界面上锁 App（下滑小锁图标）',
            ],
          ),
          SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: 'Vivo / iQOO',
            steps: [
              '设置 → 电池 → 后台高耗电 → 慢病管家 → 允许',
              '设置 → 通知 → 慢病管家 → 全部开启',
              '「最近任务」界面上锁 App',
            ],
          ),
          SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: '魅族',
            steps: [
              '设置 → 应用管理 → 慢病管家 → 权限管理 → 自启动 → 允许',
              '设置 → 通知管理 → 慢病管家 → 全部开启',
            ],
          ),
          SizedBox(height: AppTokens.spacingMd),
          Text(
            '通用建议：精确闹钟被某些 ROM 静默拒绝时,'
            '首次启动 App 时系统会弹「是否允许」,请选「允许」。',
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _OemBrand extends StatelessWidget {
  final String brand;
  final List<String> steps;
  const _OemBrand({required this.brand, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: AppTokens.divider,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brand,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < steps.length; i++) ...[
            Text(
              '${i + 1}. ${steps[i]}',
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

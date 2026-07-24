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
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

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
      final l10n = AppLocalizations.of(context);
      await service.showNow(
        id: 99001, // 测试用 id,不会跟任何业务通知冲突（_refillBaseId 6000+）
        title: l10n.notificationStatusCardTestTitle,
        body: l10n.notificationStatusCardTestBody,
      );
      if (!mounted) return;
      // v0.22 round 29 (emil-42): 走 AppSnackBar.info 集中器
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(context, l10n.notificationStatusCardTestSent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          action: AppLocalizations.of(context).notificationStatusCardActionSend,
          error: e,
        ),
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
      } catch (e, st) {
        // v0.23 (Round 37 P0): 走 swallowError, dev mode 能看到失败
        swallowError(
          where: 'notification_status_card._showDetails.pending',
          error: e,
          stack: st,
          note: 'web 平台不支持 pendingNotificationRequests,降级空列表',
        );
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.notificationStatusCardQueuedTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: pending.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    child: Text(l10n.notificationStatusCardEmpty),
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
                          p.title ?? l10n.notificationStatusCardNoTitle,
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
              child: Text(l10n.commonClose),
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
      final l10n = AppLocalizations.of(context);
      return Card(
        child: ListTile(
          leading:
              Icon(Icons.info_outline, color: AppTokens.textHintColor(context)),
          title: Text(l10n.notificationStatusCardWebTitle),
          subtitle: Text(
            l10n.notificationStatusCardWebSubtitle,
            style: TextStyle(color: AppTokens.textHintColor(context)),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final pending = _pending;
    final statusText = pending == null
        ? l10n.notificationStatusCardStatusLoading
        : pending < 0
            ? l10n.notificationStatusCardStatusUnsupported
            : pending == 0
                ? l10n.notificationStatusCardStatusNone
                : l10n.notificationStatusCardStatusCount(pending);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: AppTokens.primary,
            ),
            title: Text(l10n.notificationStatusCardTitle),
            // v0.17 round 14 (P2-3): AnimatedSize 让 statusText 切换时
            // 高度平滑过渡 (加载中 → 0 待发 → N 待发) 而不是突然跳变
            subtitle: AnimatedSize(
              // v0.21 Round 22 (P1-13 修复): wrap Motion.duration
              duration: Motion.duration(context, AppTokens.durNormal),
              curve: AppTokens.curveStandard,
              alignment: Alignment.topLeft,
              child: Text(statusText),
            ),
            trailing: IconButton(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingSpinner(size: 16),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _busy ? null : _refresh,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.send_outlined, color: AppTokens.primary),
            title: Text(l10n.notificationStatusCardTestButtonTitle),
            subtitle: Text(l10n.notificationStatusCardTestButtonSubtitle),
            onTap: _busy ? null : _fireTest,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.list_alt, color: AppTokens.primary),
            title: Text(l10n.notificationStatusCardViewButtonTitle),
            subtitle: Text(l10n.notificationStatusCardViewButtonSubtitle),
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
    final l10n = AppLocalizations.of(context);
    return Theme(
      // 去掉 ExpansionTile 默认的圆形图标背景，跟整体风格一致
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.phone_android, color: AppTokens.primary),
        title: Text(l10n.notificationStatusCardOemTitle),
        subtitle: Text(
          l10n.notificationStatusCardOemSubtitle,
          style: TextStyle(
              color: AppTokens.textSecondaryColor(context), fontSize: AppTokens.fontSizeCaptionSm,),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTokens.spacingMd,
          0,
          AppTokens.spacingMd,
          AppTokens.spacingMd,
        ),
        children: [
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandXiaomi,
            steps: [
              l10n.notificationStatusCardOemStepXiaomi1,
              l10n.notificationStatusCardOemStepXiaomi2,
              l10n.notificationStatusCardOemStepXiaomi3,
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandHuawei,
            steps: [
              l10n.notificationStatusCardOemStepHuawei1,
              l10n.notificationStatusCardOemStepHuawei2,
              l10n.notificationStatusCardOemStepHuawei3,
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandOppo,
            steps: [
              l10n.notificationStatusCardOemStepOppo1,
              l10n.notificationStatusCardOemStepOppo2,
              l10n.notificationStatusCardOemStepOppo3,
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandVivo,
            steps: [
              l10n.notificationStatusCardOemStepVivo1,
              l10n.notificationStatusCardOemStepVivo2,
              l10n.notificationStatusCardOemStepVivo3,
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandMeizu,
            steps: [
              l10n.notificationStatusCardOemStepMeizu1,
              l10n.notificationStatusCardOemStepMeizu2,
            ],
          ),
          // v0.22 round 33 (sp-zh T-11): 扩到 7 品牌, 覆盖企业用户(Knox) + 小众品牌
          // OPPO/Vivo 已含 realme/一加/iQOO, 实际还是 7 个 brand 行
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandSamsung,
            steps: [
              l10n.notificationStatusCardOemStepSamsung1,
              l10n.notificationStatusCardOemStepSamsung2,
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _OemBrand(
            brand: l10n.notificationStatusCardOemBrandOthers,
            steps: [
              l10n.notificationStatusCardOemStepOthers1,
              l10n.notificationStatusCardOemStepOthers2,
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text(
            l10n.notificationStatusCardOemGeneralTip,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
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
        color: AppTokens.dividerColor(context),
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
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

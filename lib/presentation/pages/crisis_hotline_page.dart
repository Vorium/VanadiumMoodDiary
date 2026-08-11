// v0.30 round 92 (audit-fixes / P0 #12): crisis_hotline_page
//
// 背景:
// - R75 已加 hotlineByRegion const Map (6 region: cn/us/hk/tw/sg/uk)
// - R83.5 partial 加 4 地区 ARB keys (crisisHotline{Cn,Tw,Hk,Mo}Label/Number/Desc)
// - R91 setup_legal_dialog _crisisHotlineSection 4 条用上
// - 主页 homeFabHotline FAB (R81 emil design-3) 走
//   AppSnackBar.showInfo(homeFabHotlineTodo) 占位 1.5 年
//
// R92 修法: 新建独立页 /crisis-hotline, homeFabHotline push 此页。复用
// R75 hotlineByRegion 数据 + R83.5 ARB keys + 1 个新 800-810-1117 通用中国
// 24h 免费 + 1 个 us 988 (R83.5 没加, R92 补) + 1 个 intl 通用 fallback。
//
// 4 层架构: presentation/pages/, 0 跨 page 引用 (crisis_hotline_page.dart
// 不引用任何 presentation/pages/{feature}/, 只用 presentation/widgets/ + core/ +
// domain/ + l10n/)。
//
// 频度: 极低 (用户遇到危机才点, rare), 走 emil rare 频度 — slide-up 路由 +
// AppTokens.durSlow 慢动画, 鼓励用户停下思考, 不催赶。
//
// i18n 集中: 5 region section title + 5 条 entry label/number/desc + 复制 snackbar
// 全部走 l10n。R92 删 2 个 homeFabHotline/TopTodo key (R81 占位 1.5 年后
// 真正修法落定, todo key 失去意义, R56e orphan check 强制删)。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_motion.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 单条热线 entry 数据 (label + number + 可选 desc)
@immutable
class _HotlineEntry {
  final String label;
  final String number;
  final String? desc;
  const _HotlineEntry(this.label, this.number, this.desc);
}

/// 地区分组的热线 entry 列表
@immutable
class _RegionGroup {
  final String title;
  final List<_HotlineEntry> entries;
  const _RegionGroup(this.title, this.entries);
}

/// v0.30 round 92: 紧急心理援助热线页
///
/// 5 地区 (大陆/台湾/香港/美国/国际) + 1 个 800-810-1117 全国 24h 免费
/// 顶部 banner 显示。i18n 集中 (3 语 zh/en/zh_Hant), 复用 R75 hotlineByRegion
/// const Map (cn/tw/hk/us 4 region) + 800-810-1117 + intl 提示。
class CrisisHotlinePage extends StatelessWidget {
  const CrisisHotlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = <_RegionGroup>[
      // 大陆: R75 cn[0] 400-161-9995 + 800-810-1117 + R75 cn[1] 010-82951332
      _RegionGroup(
        l10n.crisisHotlineRegionCn,
        [
          _HotlineEntry(
            l10n.crisisHotlineCnLabel,
            l10n.crisisHotlineCnNumber,
            l10n.crisisHotlineCnDesc,
          ),
          _HotlineEntry(
            l10n.crisisHotlineCn2Label,
            l10n.crisisHotlineCn2Number,
            l10n.crisisHotlineCn2Desc,
          ),
          _HotlineEntry(
            l10n.crisisHotlineCnBeijingLabel,
            l10n.crisisHotlineCnBeijingNumber,
            l10n.crisisHotlineCnBeijingDesc,
          ),
        ],
      ),
      // 台湾: R75 tw[0] 1995 + tw[1] 1925
      _RegionGroup(
        l10n.crisisHotlineRegionTw,
        [
          _HotlineEntry(
            l10n.crisisHotlineTw1995Label,
            l10n.crisisHotlineTw1995Number,
            l10n.crisisHotlineTw1995Desc,
          ),
          _HotlineEntry(
            l10n.crisisHotlineTwLabel,
            l10n.crisisHotlineTwNumber,
            l10n.crisisHotlineTwDesc,
          ),
        ],
      ),
      // 香港: R75 hk[0] 2389 2222
      _RegionGroup(
        l10n.crisisHotlineRegionHk,
        [
          _HotlineEntry(
            l10n.crisisHotlineHkLabel,
            l10n.crisisHotlineHkNumber,
            l10n.crisisHotlineHkDesc,
          ),
        ],
      ),
      // 美国: R75 us[0] 988 + us[1] 741741
      _RegionGroup(
        l10n.crisisHotlineRegionUs,
        [
          _HotlineEntry(
            l10n.crisisHotlineUsLabel,
            l10n.crisisHotlineUsNumber,
            l10n.crisisHotlineUsDesc,
          ),
          _HotlineEntry(
            l10n.crisisHotlineUsTextLineLabel,
            l10n.crisisHotlineUsTextLineNumber,
            l10n.crisisHotlineUsTextLineDesc,
          ),
        ],
      ),
      // 国际: fallback 提示
      _RegionGroup(
        l10n.crisisHotlineRegionIntl,
        [
          _HotlineEntry(
            l10n.crisisHotlineIntlLabel,
            l10n.crisisHotlineIntlNumber,
            l10n.crisisHotlineIntlDesc,
          ),
        ],
      ),
    ];

    return PageScaffold(
      title: l10n.crisisHotlineTitle,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
        children: [
          // 顶部说明 banner
          InfoBanner(
            icon: Icons.info_outline,
            text: l10n.crisisHotlineSubtitle,
            tone: InfoBannerTone.warning,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          // 5 地区分组
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingMd,
                vertical: AppTokens.spacingSm,
              ),
              child: SectionHeader(title: group.title),
            ),
            for (final entry in group.entries)
              AppListTile.carded(
                leading: Icon(
                  Icons.phone_in_talk_outlined,
                  color: AppTokens.tintedPrimaryDeep(context),
                ),
                title: Text(
                  entry.label,
                  style: AppTokens.textStyleLabelStrong(context),
                ),
                subtitle: Text(
                  '${entry.number}${entry.desc != null ? ' · ${entry.desc}' : ''}',
                  style: AppTokens.textStyleBody(context),
                ),
                // R97-P1-11 (2026-08-07): trailing 改 Row (拨打 + 复制 2 个
                // IconButton), 危机时刻用户 1 tap 即可拨打, 不再需要"复制
                // → 打开拨号 App → 粘贴 → 拨打"4 步。点 tile 主体仍走
                // _copyNumber (保留快捷复制)。
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
                    // PressFeedbackIconButton 集中器, iconSize → size
                    // (集中器参数名)。
                    PressFeedbackIconButton(
                      icon: Icons.phone_outlined,
                      size: AppTokens.iconSizeSmall,
                      color: AppTokens.tintedPrimaryDeep(context),
                      tooltip: l10n.crisisHotlineDialTooltip,
                      onPressed: () => _dialNumber(context, l10n, entry.number),
                    ),
                    PressFeedbackIconButton(
                      icon: Icons.copy_outlined,
                      size: AppTokens.iconSizeSmall,
                      color: AppTokens.textSecondaryColor(context),
                      tooltip: l10n.crisisHotlineCopyTooltip,
                      onPressed: () => _copyNumber(context, l10n, entry.number),
                    ),
                  ],
                ),
                onTap: () => _copyNumber(context, l10n, entry.number),
              ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
        ],
      ),
    );
  }

  /// 复制号码到剪贴板 + snackbar 提示
  ///
  /// v0.30 round 92: 危机时用户可能没空打开拨号, 复制号码让用户可用手机
  /// 其他 app (e.g. 通讯录 / 拨号) 拨打。3 语 i18n 走 l10n。
  void _copyNumber(BuildContext context, AppLocalizations l10n, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.crisisHotlineSnackbarCopied(number)),
        duration: AppMotion.snackBarDurationShort,
      ),
    );
  }

  /// R97-P1-11 (2026-08-07): 一键拨打危机热线 (tel: intent)
  ///
  /// 走 [url_launcher] 的 [launchUrl] + `tel:` scheme, 系统拨号 App 接管
  /// (Android Intent.ACTION_DIAL / iOS openURL:), 不需要 CALL_PHONE 权限。
  /// 失败 (e.g. 平台无拨号 App / 沙箱环境) 走 snackbar 提示用户手动拨打。
  ///
  /// 安全: tel: scheme 不直接拨号 (不挂 CALL_PHONE), 只填充拨号界面,
  /// 用户需再次按拨号键确认 — 防止误拨消耗话费 + 符合 Google Play
  /// Health/Sensitive Apps 政策推荐流程。
  Future<void> _dialNumber(
    BuildContext context,
    AppLocalizations l10n,
    String number,
  ) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // ignore: use_build_context_synchronously — 同步紧跟 canLaunchUrl,
      // widget 树稳定 (本页是无状态列表, 不会在 await 期间 dispose)。
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crisisHotlineDialFailed(number)),
          duration: AppMotion.snackBarDurationShort,
        ),
      );
    }
  }
}

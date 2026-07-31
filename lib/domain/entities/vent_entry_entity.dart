// v0.15 (Round 18) VentEntry — 树洞领域实体
//
// 4 层架构示范：domain 层 0 Flutter 0 dart:io 依赖。
// `audioPath` 存绝对路径，audio 文件本身在 app docs 目录（encrypted DB 之外）。
// 录音文件存在性检查 / 删除是 data 层职责（`VentAudioStorage`），不在 domain。
//
// 设计要点：
// - 不可变 + copyWith
// - hasText / hasAudio / isEmpty 业务方法
// - durationLabelL10n 业务方法（zh: "1分23秒" / en: "1m 23s"）
//
// v0.28 round 65 (spzh P2-I): `durationLabel` 从硬编中文 (无参) → i18n 方法
// ([durationLabelL10n])，caller 传 AppLocalizations 走 zh/en/zh_Hant。
// 3 个 i18n key: `ventDurationSeconds` / `ventDurationMinutes` /
// `ventDurationMinutesSeconds` (后者是 v0.28 round 65 新加，原来
// `'$m分${s.toString().padLeft(2, '0')}秒'` 走该 key 解决硬编)。

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 树洞条目（领域实体）
///
/// 一条记录可同时有 text 和 audio（用户先录后补文字，或反过来）。
/// 两个都为空 = 不应保存。
class VentEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 文字内容（可空）
  final String? contentText;

  /// 录音文件绝对路径（可空）
  final String? audioPath;

  /// 录音时长（秒，可空）
  final int? audioDurationSec;

  /// 录音文件大小（字节，可空）
  final int? audioSizeBytes;

  const VentEntryEntity({
    required this.id,
    required this.timestamp,
    this.contentText,
    this.audioPath,
    this.audioDurationSec,
    this.audioSizeBytes,
  });

  // ===== 业务方法 =====

  /// 是否有文字内容
  bool get hasText => contentText != null && contentText!.trim().isNotEmpty;

  /// 是否有录音
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  /// 是否同时有 text + audio
  bool get isMixed => hasText && hasAudio;

  /// 是否为空条目（text 和 audio 都没有）
  bool get isEmpty => !hasText && !hasAudio;

  /// i18n 录音时长人类可读格式
  ///
  /// caller 传 [AppLocalizations] 走 zh/en/zh_Hant，不传返中文 fallback
  /// (老 test 兼容 / 单测用)。
  ///
  /// 3 个 i18n key 模板：
  /// - `ventDurationSeconds` = `'{sec}秒'` (zh) / `'{sec}s'` (en)
  /// - `ventDurationMinutes` = `'{m}分'` (zh) / `'{m}m'` (en)
  /// - `ventDurationMinutesSeconds` = `'{m}分{sec}秒'` (zh) / `'{m}m {sec}s'` (en)
  ///
  /// v0.28 round 65 (spzh P2-I): 替代之前 `durationLabel()` 硬编中文
  /// `'${sec}秒' / '${m}分' / '${m}分${s.toString().padLeft(2, '0')}秒'`。
  /// 老 `durationLabel()` 不传参保留为中文 fallback (不破坏 R18 21 case test)。
  String durationLabelL10n({String? override, AppLocalizations? l10n}) {
    final sec = audioDurationSec;
    if (sec == null) return '';
    if (sec < 60) {
      if (l10n != null) return l10n.ventDurationSeconds(sec);
      return override ?? '$sec秒';
    }
    final m = sec ~/ 60;
    final s = sec % 60;
    if (s == 0) {
      if (l10n != null) return l10n.ventDurationMinutes(m);
      return override ?? '$m分';
    }
    if (l10n != null) {
      // v0.28 round 65: pad 0 在 Dart 端 (ARB String placeholder),
      // 中文 '1分05秒' 0-pad 保留 — 跟原 R18 行为一致
      return l10n.ventDurationMinutesSeconds(m, s.toString().padLeft(2, '0'));
    }
    return override ?? '$m分${s.toString().padLeft(2, '0')}秒';
  }

  /// 中文 fallback durationLabel (保留供老 caller / 单测用)
  ///
  /// v0.28 round 65: 新 [durationLabelL10n] 方法替代 i18n 路径,
  /// 本方法保留中文 fallback (`'$sec秒' / '$m分' / '$m分${pad}秒'`),
  /// 行为与 v0.18 R18 一致 — 21 case test 继续 pass。
  String durationLabel() {
    final sec = audioDurationSec;
    if (sec == null) return '';
    if (sec < 60) return '$sec秒';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s == 0 ? '$m分' : '$m分${s.toString().padLeft(2, '0')}秒';
  }

  VentEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    DomainValue<String?>? contentText,
    DomainValue<String?>? audioPath,
    DomainValue<int?>? audioDurationSec,
    DomainValue<int?>? audioSizeBytes,
  }) {
    return VentEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      contentText: contentText == null ? this.contentText : contentText.value,
      audioPath: audioPath == null ? this.audioPath : audioPath.value,
      audioDurationSec:
          audioDurationSec == null ? this.audioDurationSec : audioDurationSec.value,
      audioSizeBytes:
          audioSizeBytes == null ? this.audioSizeBytes : audioSizeBytes.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VentEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.contentText == contentText &&
        other.audioPath == audioPath &&
        other.audioDurationSec == audioDurationSec &&
        other.audioSizeBytes == audioSizeBytes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        contentText,
        audioPath,
        audioDurationSec,
        audioSizeBytes,
      );

  @override
  String toString() =>
      'VentEntryEntity(id=$id, ts=$timestamp, text=${contentText?.length ?? 0}字, audio=${audioPath != null})';
}

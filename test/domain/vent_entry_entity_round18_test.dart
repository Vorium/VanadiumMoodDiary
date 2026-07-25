// v0.15 (Round 18) VentEntryEntity 领域实体测试
//
// 验证：
// - hasText / hasAudio / isEmpty / isMixed 边界（空字符串、null）
// - durationLabel 输出（"23秒" / "1分05秒" / "1分"）
// - copyWith 各字段
// - == / hashCode 一致
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';

VentEntryEntity _e({
  int id = 1,
  DateTime? timestamp,
  String? contentText,
  String? audioPath,
  int? audioDurationSec,
  int? audioSizeBytes,
}) {
  return VentEntryEntity(
    id: id,
    timestamp: timestamp ?? DateTime(2026, 7, 15, 10, 30),
    contentText: contentText,
    audioPath: audioPath,
    audioDurationSec: audioDurationSec,
    audioSizeBytes: audioSizeBytes,
  );
}

void main() {
  group('VentEntryEntity 业务方法', () {
    test('空条目（text=null, audio=null）→ isEmpty=true, 其他 false', () {
      final e = _e();
      expect(e.hasText, false);
      expect(e.hasAudio, false);
      expect(e.isEmpty, true);
      expect(e.isMixed, false);
    });

    test('text 空字符串 → hasText=false（trim 后为空）', () {
      final e = _e(contentText: '   ');
      expect(e.hasText, false);
      expect(e.isEmpty, true);
    });

    test('text 有内容 → hasText=true', () {
      final e = _e(contentText: '今天有点累');
      expect(e.hasText, true);
      expect(e.isEmpty, false);
    });

    test('audio 路径有内容 → hasAudio=true', () {
      final e = _e(audioPath: '/data/user/0/com.example/vent_audio/abc.m4a');
      expect(e.hasAudio, true);
      expect(e.isEmpty, false);
    });

    test('audio 路径是空字符串 → hasAudio=false', () {
      final e = _e(audioPath: '');
      expect(e.hasAudio, false);
    });

    test('text + audio 同时有 → isMixed=true', () {
      final e = _e(
        contentText: '今天不太好',
        audioPath: '/data/.../voice.m4a',
      );
      expect(e.isMixed, true);
    });
  });

  group('durationLabel', () {
    test('null → 空字符串', () {
      final e = _e();
      expect(e.durationLabel(), '');
    });

    test('0 秒 → "0秒"', () {
      final e = _e(audioDurationSec: 0);
      expect(e.durationLabel(), '0秒');
    });

    test('23 秒 → "23秒"', () {
      final e = _e(audioDurationSec: 23);
      expect(e.durationLabel(), '23秒');
    });

    test('60 秒（整分）→ "1分"（不带秒数）', () {
      final e = _e(audioDurationSec: 60);
      expect(e.durationLabel(), '1分');
    });

    test('83 秒 → "1分23秒"', () {
      final e = _e(audioDurationSec: 83);
      expect(e.durationLabel(), '1分23秒');
    });

    test('65 秒 → "1分05秒"（秒数补 0）', () {
      final e = _e(audioDurationSec: 65);
      expect(e.durationLabel(), '1分05秒');
    });

    test('300 秒 → "5分"', () {
      final e = _e(audioDurationSec: 300);
      expect(e.durationLabel(), '5分');
    });
  });

  group('copyWith', () {
    final t1 = DateTime(2026, 7, 15, 10, 0);
    final t2 = DateTime(2026, 7, 15, 11, 0);

    test('不传任何字段 → 复制所有原字段', () {
      final e = _e(
        id: 7,
        timestamp: t1,
        contentText: '原文字',
        audioPath: '/old.m4a',
        audioDurationSec: 30,
        audioSizeBytes: 1024,
      );
      final c = e.copyWith();
      expect(c.id, 7);
      expect(c.timestamp, t1);
      expect(c.contentText, '原文字');
      expect(c.audioPath, '/old.m4a');
      expect(c.audioDurationSec, 30);
      expect(c.audioSizeBytes, 1024);
    });

    test('只改 id → 其他不动', () {
      final e = _e(timestamp: t1, contentText: 'old');
      final c = e.copyWith(id: 99);
      expect(c.id, 99);
      expect(c.timestamp, t1);
      expect(c.contentText, 'old');
    });

    test('改时间戳 → 其他不动', () {
      final e = _e(timestamp: t1, contentText: 'old');
      final c = e.copyWith(timestamp: t2);
      expect(c.timestamp, t2);
      expect(c.contentText, 'old');
    });

    test('改 audioPath → 其他不动', () {
      final e = _e(timestamp: t1, audioPath: '/a.m4a');
      final c = e.copyWith(audioPath: const DomainValue('/b.m4a'));
      expect(c.audioPath, '/b.m4a');
    });
  });

  group('相等性', () {
    test('字段全相同 → ==', () {
      final a = _e(contentText: 'x');
      final b = _e(contentText: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('id 不同 → !=', () {
      final a = _e(id: 1, contentText: 'x');
      final b = _e(id: 2, contentText: 'x');
      expect(a, isNot(b));
    });

    test('contentText 不同 → !=', () {
      final a = _e(contentText: 'x');
      final b = _e(contentText: 'y');
      expect(a, isNot(b));
    });
  });
}

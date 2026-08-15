// v0.14 (Round 12B) CheckIn UseCase 单元测试
//
// 2 个 use case × 2-4 case = 6 case
// 1.1.0 round 4b: TriggerReminderUseCase 随 ReminderChecker 整摘 (外联删除)
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/domain/usecases/check_in_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory check-in repo（不依赖 Drift / DB），纯 mock
class _FakeCheckInRepository implements CheckInRepository {
  final List<CheckInEntity> inserted = [];
  int _nextId = 1;

  @override
  Stream<List<CheckInEntity>> watchAll() => Stream.value(inserted);

  @override
  Stream<List<CheckInEntity>> watchAssessments() => Stream.value(const []);

  @override
  Stream<CheckInEntity?> watchToday() => Stream.value(null);

  @override
  Stream<List<CheckInEntity>> watchTodayAll() => Stream.value(const []);

  @override
  Future<int> checkIn({int? medicationId, DateTime? at}) async {
    final ci = CheckInEntity(
      id: _nextId++,
      timestamp: at ?? DateTime(2026, 7, 15),
      type: CheckInType.normal,
      medicationId: medicationId,
    );
    inserted.add(ci);
    return ci.id;
  }

  @override
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) async {
    final ci = CheckInEntity(
      id: _nextId++,
      timestamp: at ?? DateTime(2026, 7, 15),
      type: CheckInType.temp,
      note: note,
    );
    inserted.add(ci);
    return ci.id;
  }

  @override
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  }) async {
    return -1;
  }

  @override
  Stream<List<CheckInEntity>> watchNormalCheckIns() => Stream.value(
        inserted.where((c) => c.isNormal).toList(),
      );

  @override
  Future<CheckInEntity?> getLatestNormalCheckIn() async {
    final normals = inserted.where((c) => c.isNormal).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return normals.isEmpty ? null : normals.first;
  }

  @override
  Future<DateTime?> getLatestAssessmentTimestamp() async {
    final assessments = inserted
        .where((c) => c.type == CheckInType.phq9 || c.type == CheckInType.gad7)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return assessments.isEmpty ? null : assessments.first.timestamp;
  }
}

/// P0-10 fix: in-memory user profile repo,记录 updateLastCheckIn 调用。
class _FakeUserProfileRepository implements UserProfileRepository {
  final List<DateTime> updated = [];

  @override
  Stream<UserProfileEntity?> watch() => Stream.value(null);

  @override
  Future<UserProfileEntity?> get() async => null;

  @override
  Future<void> save({
    // v0.21 Round 23 (P1-24): userName 改 nullable
    String? userName,
    int checkInCycleHours = 48,
  }) async {}

  @override
  Future<void> updateLastCheckIn(DateTime time) async {
    updated.add(time);
  }

  // v0.21 Round 22 (P1-22): 3 个新 consent 方法 stub
  @override
  Future<void> recordConsent({
    required String userAgreementVersion,
    required String privacyPolicyVersion,
  }) async {}

  @override
  Future<void> withdrawConsent() async {}

  @override
  Future<void> resetConsent() async {}
}

void main() {
  group('RecordCheckInUseCase', () {
    test('调 repo.checkIn，medicationId 透传', () async {
      final repo = _FakeCheckInRepository();
      final profile = _FakeUserProfileRepository();
      final useCase = RecordCheckInUseCase(repo, profile);

      final id = await useCase(medicationId: 7);
      expect(id, 1);
      expect(repo.inserted.length, 1);
      expect(repo.inserted.first.type, CheckInType.normal);
      expect(repo.inserted.first.medicationId, 7);
    });

    test('不传 medicationId = null', () async {
      final repo = _FakeCheckInRepository();
      final profile = _FakeUserProfileRepository();
      final useCase = RecordCheckInUseCase(repo, profile);

      await useCase();
      expect(repo.inserted.first.medicationId, isNull);
    });

    test('at 注入时间（测试用）', () async {
      final repo = _FakeCheckInRepository();
      final profile = _FakeUserProfileRepository();
      final useCase = RecordCheckInUseCase(repo, profile);
      final fixed = DateTime(2026, 7, 15, 8, 0);

      await useCase(at: fixed);
      expect(repo.inserted.first.timestamp, fixed);
    });

    test('P0-10: check-in 后同步调 userProfileRepo.updateLastCheckIn', () async {
      final repo = _FakeCheckInRepository();
      final profile = _FakeUserProfileRepository();
      final useCase = RecordCheckInUseCase(repo, profile);
      final fixed = DateTime(2026, 7, 15, 9, 30);

      await useCase(at: fixed);
      expect(profile.updated, hasLength(1));
      expect(profile.updated.first, fixed);
    });
  });

  group('RecordTempMedicationUseCase', () {
    test('调 repo.addTempMedication，name/note 透传', () async {
      final repo = _FakeCheckInRepository();
      final useCase = RecordTempMedicationUseCase(repo);

      final id = await useCase(
        name: '布洛芬',
        note: '头痛',
      );
      expect(id, 1);
      expect(repo.inserted.length, 1);
      expect(repo.inserted.first.type, CheckInType.temp);
      expect(repo.inserted.first.note, '头痛');
    });
  });
}

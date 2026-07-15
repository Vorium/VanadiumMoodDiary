// v0.14 (Round 12B) CheckIn UseCase 单元测试
//
// 3 个 use case × 2-3 case = 7-9 case
import 'package:chroniccare/data/database/app_database.dart';
import 'package:chroniccare/data/repositories/check_in_repository_impl.dart';
import 'package:chroniccare/data/repositories/contact_repository_impl.dart';
import 'package:chroniccare/data/repositories/medication_repository_impl.dart';
import 'package:chroniccare/data/repositories/user_profile_repository.dart';
import 'package:chroniccare/data/services/reminder_scheduler.dart';
import 'package:chroniccare/data/services/sms_service.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/usecases/check_in_usecases.dart';
import 'package:drift/native.dart';
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
}

/// Stub ReminderService — 不发真实通知，只跑 checkAndSend 返回 stub 结果
class _StubReminderService extends ReminderService {
  _StubReminderService(this._result) : super(
    checkInRepo: CheckInRepositoryImpl(AppDatabase.forTesting(NativeDatabase.memory())),
    contactRepo: ContactRepositoryImpl(AppDatabase.forTesting(NativeDatabase.memory())),
    medicationRepo: MedicationRepositoryImpl(AppDatabase.forTesting(NativeDatabase.memory())),
    userProfileRepo: UserProfileRepository(AppDatabase.forTesting(NativeDatabase.memory())),
    smsService: SmsService(),
  );

  final ReminderResult _result;

  @override
  Future<ReminderResult> checkAndSend() async => _result;
}

void main() {
  group('RecordCheckInUseCase', () {
    test('调 repo.checkIn，medicationId 透传', () async {
      final repo = _FakeCheckInRepository();
      final useCase = RecordCheckInUseCase(repo);

      final id = await useCase(medicationId: 7);
      expect(id, 1);
      expect(repo.inserted.length, 1);
      expect(repo.inserted.first.type, CheckInType.normal);
      expect(repo.inserted.first.medicationId, 7);
    });

    test('不传 medicationId = null', () async {
      final repo = _FakeCheckInRepository();
      final useCase = RecordCheckInUseCase(repo);

      await useCase();
      expect(repo.inserted.first.medicationId, isNull);
    });

    test('at 注入时间（测试用）', () async {
      final repo = _FakeCheckInRepository();
      final useCase = RecordCheckInUseCase(repo);
      final fixed = DateTime(2026, 7, 15, 8, 0);

      await useCase(at: fixed);
      expect(repo.inserted.first.timestamp, fixed);
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

  group('TriggerReminderUseCase', () {
    test('level=none → 返回 false', () async {
      final stub = _StubReminderService(
        ReminderResult.empty(), // level = none
      );
      final useCase = TriggerReminderUseCase(stub);

      final result = await useCase();
      expect(result, isFalse);
    });

    test('level=medium → 返回 true', () async {
      final stub = _StubReminderService(
        const ReminderResult(level: ReminderLevel.medium, smsResults: []),
      );
      final useCase = TriggerReminderUseCase(stub);

      final result = await useCase();
      expect(result, isTrue);
    });
  });
}

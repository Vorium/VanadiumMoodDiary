import 'package:drift/drift.dart';

import 'connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

import 'tables/check_ins.dart';
import 'tables/contacts.dart';
import 'tables/medications.dart';
import 'tables/user_profiles.dart';

part 'app_database.g.dart';

/// 慢病管家数据库
@DriftDatabase(
  tables: [CheckIns, Medications, Contacts, UserProfiles],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // 启用外键
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============= CheckIns =============
  Stream<List<CheckIn>> watchAllCheckIns() {
    return (select(checkIns)
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<CheckIn?> watchTodayCheckIn() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(checkIns)
          ..where((t) =>
              t.timestamp.isBiggerOrEqualValue(startOfDay) &
              t.timestamp.isSmallerThanValue(endOfDay) &
              t.type.equals('normal'),
        )
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<int> insertCheckIn(CheckInsCompanion entry) {
    return into(checkIns).insert(entry);
  }

  // ============= Medications =============
  Stream<List<Medication>> watchMedications() {
    return (select(medications)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.startDate),
          ]))
        .watch();
  }

  Future<int> insertMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  Future<bool> updateMedication(Medication medication) {
    return update(medications).replace(medication);
  }

  Future<int> deleteMedication(int id) {
    return (delete(medications)..where((t) => t.id.equals(id))).go();
  }

  // ============= Contacts =============
  Stream<List<Contact>> watchContacts() {
    return (select(contacts)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  Future<int> insertContact(ContactsCompanion entry) {
    return into(contacts).insert(entry);
  }

  Future<bool> updateContact(Contact contact) {
    return update(contacts).replace(contact);
  }

  Future<int> deleteContact(int id) {
    return (delete(contacts)..where((t) => t.id.equals(id))).go();
  }

  // ============= UserProfile =============
  Stream<UserProfile?> watchUserProfile() {
    return (select(userProfiles)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<UserProfile?> getUserProfile() {
    return (select(userProfiles)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> upsertUserProfile(UserProfilesCompanion entry) async {
    await into(userProfiles).insertOnConflictUpdate(entry);
  }
}

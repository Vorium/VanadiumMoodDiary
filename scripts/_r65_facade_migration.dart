// v0.27 round 65 (spen P1-11): app_database 18 facade weituo qingli
// Dart script (no PS variable interpolation issue) — 1:1 caller 替换
// Run: dart run scripts/_r65_facade_migration.dart
import 'dart:io';

class Replacement {
  final String facade;
  final String dao;
  const Replacement(this.facade, this.dao);
}

const replacements = <Replacement>[
  Replacement('watchAllCheckIns', 'checkInDao.watchAll'),
  Replacement('watchAssessments', 'checkInDao.watchAssessments'),
  Replacement('watchTodayCheckIn', 'checkInDao.watchToday'),
  Replacement('watchNormalCheckIns', 'checkInDao.watchNormal'),
  Replacement('getLatestNormalCheckIn', 'checkInDao.getLatestNormal'),
  Replacement('getLatestAssessmentTimestamp',
      'checkInDao.getLatestAssessmentTimestamp'),
  Replacement('insertCheckIn', 'checkInDao.insert'),
  Replacement('watchMedications', 'medicationDao.watchActive'),
  Replacement('watchAllMedicationsIncludingInactive',
      'medicationDao.watchAllIncludingInactive'),
  Replacement('insertMedication', 'medicationDao.insert'),
  Replacement('updateMedication', 'medicationDao.update'),
  Replacement('deleteMedication', 'medicationDao.delete'),
  Replacement('watchContacts', 'contactDao.watchActive'),
  Replacement('insertContact', 'contactDao.insert'),
  Replacement('updateContact', 'contactDao.update'),
  Replacement('deleteContact', 'contactDao.delete'),
  Replacement('watchUserProfile', 'userProfileDao.watch'),
  Replacement('getUserProfile', 'userProfileDao.get'),
  Replacement('upsertUserProfile', 'userProfileDao.upsert'),
  Replacement('watchReportHistories', 'reportDao.watchAll'),
  Replacement('insertReportHistory', 'reportDao.insert'),
  Replacement('deleteReportHistory', 'reportDao.delete'),
  Replacement('clearAllReportHistories', 'reportDao.clearAll'),
  Replacement('getAllReportHistories', 'reportDao.getAll'),
  Replacement('watchMoodEntries', 'moodDao.watchAll'),
  Replacement('getAllMoodEntries', 'moodDao.getAll'),
  Replacement('watchTodayMoodEntries', 'moodDao.watchToday'),
  Replacement('insertMoodEntry', 'moodDao.insert'),
  Replacement('deleteMoodEntry', 'moodDao.delete'),
  Replacement('watchVentEntries', 'ventDao.watchAll'),
  Replacement('insertVentEntry', 'ventDao.insert'),
  Replacement('deleteVentEntry', 'ventDao.delete'),
];

void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('app_database.dart'))
      .map((f) => f.path)
      .toList();
  final testFiles = Directory('test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList();
  final files = [...libFiles, ...testFiles];

  var totalChanges = 0;
  for (final file in files) {
    var content = File(file).readAsStringSync();
    var fileChanges = 0;

    for (final r in replacements) {
      final pattern = RegExp(r'(_?db)\.' + r.facade + r'\(');
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        content = content.replaceAllMapped(
          pattern,
          (m) => '${m.group(1)}.${r.dao}(',
        );
        fileChanges += matches.length;
      }
    }

    if (fileChanges > 0) {
      File(file).writeAsStringSync(content);
      stdout.writeln('${file.split(Platform.pathSeparator).last}: '
          '$fileChanges changes');
      totalChanges += fileChanges;
    }
  }

  stdout.writeln('===== TOTAL: $totalChanges replacements =====');
}

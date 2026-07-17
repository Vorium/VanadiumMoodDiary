// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Chronic Care';

  @override
  String get appTagline => 'I took my meds today';

  @override
  String get homeCheckIn => 'I took my meds today';

  @override
  String get homeCheckedIn => 'Checked in today ✓';

  @override
  String homeStreak(int days) {
    return '$days-day streak';
  }

  @override
  String homeLastMed(String time) {
    return 'Last dose: $time';
  }

  @override
  String homeNextReminder(String time) {
    return 'Next reminder: $time';
  }

  @override
  String get homeStillOnline => '🌱 You\'re still online';

  @override
  String get homeTempMed => 'Take temp dose +';

  @override
  String get homeStreakBroken => 'Missing 1 is fine, tomorrow counts';

  @override
  String setupStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get setupHello => 'Hi, I\'m Chronic Care';

  @override
  String get setupIntro => '1 minute setup, then 1 tap per day';

  @override
  String get setupName => 'Your name';

  @override
  String get setupNameHint => 'Alex';

  @override
  String get setupContacts => 'Emergency contact emails (at least 1)';

  @override
  String get setupContactHint => 'mom@example.com';

  @override
  String get setupAddContact => '+ Add another contact';

  @override
  String get setupNext => 'Next →';

  @override
  String get setupMedName => 'Medication name';

  @override
  String get setupMedNameHint => 'Sertraline';

  @override
  String get setupMedFrequency => 'Daily frequency';

  @override
  String get setupMedTimes1 => '1x';

  @override
  String get setupMedTimes2 => '2x';

  @override
  String get setupMedTimes3 => '3x';

  @override
  String get setupMedSchedule => 'Dose times (optional)';

  @override
  String get setupStart => 'Start day 1';

  @override
  String get setupDoneTitle => 'All done!';

  @override
  String get setupDoneSubtitle => 'Your day 1 starts tomorrow';

  @override
  String get setupDailyRoutine => 'Daily routine:';

  @override
  String get setupReminder1 => '✓ 1 reminder per day';

  @override
  String get setupReminder2 => '✓ 1 tap = check in';

  @override
  String get setupReminder3 => '✓ 2 missed days → I\'ll alert your contact';

  @override
  String get setupPrivacy => 'Your data:';

  @override
  String get setupPrivacy1 => '• Encrypted on device';

  @override
  String get setupPrivacy2 => '• Never uploaded to cloud (except email)';

  @override
  String get setupPrivacy3 => '• Exportable anytime';

  @override
  String get settingsContacts => 'Emergency contacts';

  @override
  String get settingsMedication => 'Medications';

  @override
  String get settingsEmailPreview => 'Preview stop-reminder email';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDisclaimer => 'Disclaimer';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsMedReport => 'Medication report';

  @override
  String get settingsMedReportSubtitle =>
      'Pick a window (7/14/30 days) to show your doctor';

  @override
  String get settingsMedReportChooseTitle => 'Pick a time window';

  @override
  String get settingsMedReportChooseSubtitle =>
      'Aggregates your regular + temp medications in this window';

  @override
  String get settingsMedReportWindow7 => 'Last 7 days';

  @override
  String get settingsMedReportWindow14 => 'Last 14 days';

  @override
  String get settingsMedReportWindow30 => 'Last 30 days';

  @override
  String get settingsReportHistory => 'Report history';

  @override
  String get settingsReportHistorySubtitle => 'View past medication reports';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong, please retry';

  @override
  String snackbarErrorTemplate(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String get snackbarCopied => 'Copied to clipboard';

  @override
  String get snackbarNeedMicPermission => 'Microphone permission needed';

  @override
  String get snackbarEmptyVent => 'Write something or record a voice note';

  @override
  String get snackbarStopRecording => 'Please stop recording first';

  @override
  String get snackbarPhoneInvalid => 'Phone format invalid (11 digits)';
}

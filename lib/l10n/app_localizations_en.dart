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
  String get setupMedNameHint => 'e.g. as printed on the box (optional)';

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
  String get settingsTitle => 'Settings';

  @override
  String get settingsDataManagement => 'Data Management';

  @override
  String get settingsExportData => 'Export Data';

  @override
  String get settingsExportSubtitle =>
      'Generate JSON and save it somewhere safe';

  @override
  String get settingsImportData => 'Import Data';

  @override
  String get settingsImportSubtitle =>
      'Restore from JSON (overwrites existing data)';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsReminderCenter => 'Reminder Center';

  @override
  String get settingsReminderCenterSubtitle =>
      'Manage all reminders: daily check-in, medication times, refills, assessment, safety watch';

  @override
  String get settingsRefillManagement => 'Refill Management';

  @override
  String get settingsRefillManagementSubtitle =>
      'View refill status for all medications';

  @override
  String get settingsAssessment => 'Assessment';

  @override
  String get settingsAssessmentHistory => 'Assessment History';

  @override
  String get settingsAssessmentHistorySubtitle =>
      'View line charts and comparisons for all PHQ-9 / GAD-7 assessments';

  @override
  String get settingsAboutVersion => 'v0.1.0 · I took my meds today';

  @override
  String get settingsDisclaimerText =>
      'This app does not provide medical advice. All features are for reference only.';

  @override
  String get settingsExportDialogTitle => 'Export Data';

  @override
  String get settingsExportInstruction =>
      'Save the JSON below to a safe place:';

  @override
  String get settingsExportVentWarning =>
      'Note: Text from vent (private diary) will be exported, but audio recordings will not — audio is stored locally and becomes inaccessible after reinstall.';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsActionExport => 'Export';

  @override
  String get settingsActionGenerateReport => 'Generate report';

  @override
  String get settingsImportDialogTitle => 'Import Data';

  @override
  String get settingsImportWarning =>
      '⚠️ This will overwrite all existing data. Please confirm before continuing.';

  @override
  String get settingsImportHint => 'Paste your exported JSON here';

  @override
  String settingsImportSuccess(String summary) {
    return 'Import complete: $summary';
  }

  @override
  String get settingsActionImport => 'Import';

  @override
  String get settingsImportAndOverwrite => 'Import & Overwrite';

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
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonConfirmDelete => 'Delete this?';

  @override
  String commonLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get commonDeleteWarning => 'Cannot be restored after deletion';

  @override
  String get commonEmpty => 'Empty';

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
  String get snackbarPhoneInvalid => 'Phone format invalid (CN/HK/MO/TW/intl)';

  @override
  String get commonConfirmOk => 'OK';

  @override
  String get commonTakePhoto => 'Take photo';

  @override
  String get commonMedName => 'Medication';

  @override
  String get commonDoseUnit => 'tablet';

  @override
  String get commonSetup => 'Set up';

  @override
  String commonAutoCheckinFailed(String error) {
    return 'Auto check-in failed: $error';
  }

  @override
  String commonCheckinFailed(String error) {
    return 'Check-in failed: $error';
  }

  @override
  String get commonVentDeleteWarning =>
      'Once deleted, it\'s gone. Text and audio will be removed together.';

  @override
  String get medsListEmpty => 'No medications added yet';

  @override
  String get medsCalendarTitle => 'Medication Calendar';

  @override
  String get medsCalendarSubtitle =>
      'Doctor\'s adherence heatmap · 7/30/90 days';

  @override
  String get medsListNoActive => 'No active medications';

  @override
  String get medsListStoppedSection => 'Stopped';

  @override
  String get medsSnackUpdated => 'Updated';

  @override
  String get medsSnackUpdatedSoftStop => 'Updated · Soft-stopped';

  @override
  String get medsRefillPickDate => 'Pick refill date';

  @override
  String medsRefillSet(String date, int days) {
    return 'Refill set: $date, remind $days days before';
  }

  @override
  String get medsActionRefill => 'Set refill';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return 'Overdue by $days days · Remind $reminderDays days before';
  }

  @override
  String medsRefillUpcoming(String date, int days, int reminderDays) {
    return 'Refill: $date ($days days left) · Remind $reminderDays days before';
  }

  @override
  String get medsRefillDaysTitle => 'Remind how many days before?';

  @override
  String medsRefillDaysUnit(int days) {
    return '$days days';
  }

  @override
  String get medsRefillHint3 => 'Last push';

  @override
  String get medsRefillHint5 => 'Pretty tight';

  @override
  String get medsRefillHint7 => 'Recommended (default)';

  @override
  String get medsRefillHint14 => 'Two weeks to book';

  @override
  String get medsRefillHint30 => 'One-month cycle';

  @override
  String get notificationStatusCardTestTitle => '🔔 Notification Test';

  @override
  String get notificationStatusCardTestBody =>
      'If you see this, notifications work. If not, check the phone settings below';

  @override
  String get notificationStatusCardTestSent =>
      'Test notification sent — should arrive in a few seconds';

  @override
  String get notificationStatusCardActionSend => 'Send';

  @override
  String get notificationStatusCardQueuedTitle => 'Queued Notifications';

  @override
  String get notificationStatusCardEmpty =>
      'No pending notifications.\nReminders may not be set, or the system killed background tasks.';

  @override
  String get notificationStatusCardNoTitle => '(No title)';

  @override
  String get notificationStatusCardWebTitle =>
      'Notifications are only available on Android / iOS';

  @override
  String get notificationStatusCardWebSubtitle =>
      'You\'re on the web. Notifications are controlled by the browser. Please test on your phone.';

  @override
  String get notificationStatusCardStatusLoading => 'Loading…';

  @override
  String get notificationStatusCardStatusUnsupported =>
      'Unsupported on this platform';

  @override
  String get notificationStatusCardStatusNone =>
      '⚠️ No pending notifications — reminders may not be set';

  @override
  String notificationStatusCardStatusCount(int count) {
    return '✓ $count notification(s) queued';
  }

  @override
  String get notificationStatusCardTitle => 'Notifications & Reminders';

  @override
  String get notificationStatusCardTestButtonTitle => 'Test Notification';

  @override
  String get notificationStatusCardTestButtonSubtitle =>
      'Tap to send a test notification now';

  @override
  String get notificationStatusCardViewButtonTitle =>
      'View Queued Notifications';

  @override
  String get notificationStatusCardViewButtonSubtitle =>
      'Show all pending reminders';

  @override
  String get notificationStatusCardOemTitle => 'Not receiving notifications?';

  @override
  String get notificationStatusCardOemSubtitle =>
      'Xiaomi/Huawei/OPPO/Vivo kill background tasks by default. Tap to learn how to fix';

  @override
  String get notificationStatusCardOemBrandXiaomi => 'Xiaomi / Redmi';

  @override
  String get notificationStatusCardOemStepXiaomi1 =>
      'Settings → Apps → Chronic Care → Autostart → Enable';

  @override
  String get notificationStatusCardOemStepXiaomi2 =>
      'Settings → Apps → Chronic Care → Battery → No restrictions';

  @override
  String get notificationStatusCardOemStepXiaomi3 =>
      'Settings → Notifications → Chronic Care → Allow + Lock screen';

  @override
  String get notificationStatusCardOemBrandHuawei => 'Huawei / Honor';

  @override
  String get notificationStatusCardOemStepHuawei1 =>
      'Settings → Apps → Chronic Care → Battery → Launch → Allow auto-launch';

  @override
  String get notificationStatusCardOemStepHuawei2 =>
      'Settings → Apps → Chronic Care → Notifications → Enable all';

  @override
  String get notificationStatusCardOemStepHuawei3 =>
      'Phone Manager → App Launch → Disable \"Auto-management\"';

  @override
  String get notificationStatusCardOemBrandOppo => 'OPPO / realme / OnePlus';

  @override
  String get notificationStatusCardOemStepOppo1 =>
      'Settings → Battery → Power saving → Chronic Care → Allow background';

  @override
  String get notificationStatusCardOemStepOppo2 =>
      'Settings → Notifications → Chronic Care → Enable all';

  @override
  String get notificationStatusCardOemStepOppo3 =>
      'In Recent Tasks, lock the app (swipe down on the lock icon)';

  @override
  String get notificationStatusCardOemBrandVivo => 'Vivo / iQOO';

  @override
  String get notificationStatusCardOemStepVivo1 =>
      'Settings → Battery → High background power → Chronic Care → Allow';

  @override
  String get notificationStatusCardOemStepVivo2 =>
      'Settings → Notifications → Chronic Care → Enable all';

  @override
  String get notificationStatusCardOemStepVivo3 =>
      'In Recent Tasks, lock the app';

  @override
  String get notificationStatusCardOemBrandMeizu => 'Meizu';

  @override
  String get notificationStatusCardOemStepMeizu1 =>
      'Settings → App Management → Chronic Care → Permissions → Autostart → Allow';

  @override
  String get notificationStatusCardOemStepMeizu2 =>
      'Settings → Notification Management → Chronic Care → Enable all';

  @override
  String get notificationStatusCardOemGeneralTip =>
      'General tip: When exact alarms are silently blocked by some ROMs, the system will ask \"Allow?\" on first launch — please select \"Allow\".';

  @override
  String get reminderHubDescription =>
      'Manage all reminders in one place: daily check-in, medication times, refill dates, assessment, safety watch.';

  @override
  String get reminderHubDailyTitle => 'Daily Check-in Reminder';

  @override
  String get reminderHubDailyDesc =>
      'Pushes \"time to check in\" at 20:00 daily — missing once is fine';

  @override
  String get reminderHubDailyStatus => 'Enabled · Daily at 20:00';

  @override
  String get reminderHubDailyAction => 'Preview notification';

  @override
  String get reminderHubMedicationTitle => 'Medication Reminder';

  @override
  String get reminderHubStatusError => 'Error';

  @override
  String get reminderHubRefillTitle => 'Refill Reminder';

  @override
  String get reminderHubAssessmentTitle => 'Periodic Assessment Reminder';

  @override
  String reminderHubAssessmentDescEnabled(int days) {
    return 'Remind every $days days to take assessment (PHQ-9 / GAD-7)';
  }

  @override
  String get reminderHubAssessmentDescDisabled =>
      'Off · No assessment reminders';

  @override
  String reminderHubAssessmentStatusEnabled(int days) {
    return 'Enabled · Every $days days';
  }

  @override
  String get reminderHubStatusDisabled => 'Disabled';

  @override
  String get reminderHubConfigure => 'Configure';

  @override
  String get reminderHubSafetyTitle => 'Safety Watch (Safety Switch)';

  @override
  String get reminderHubSmsMockWarning =>
      'SMS channel not connected (using Mock). When safety watch triggers, only local notifications are sent — no real SMS to emergency contacts. Must integrate a real SMS provider before store launch.';

  @override
  String reminderHubSafetyDescEnabled(int threshold) {
    return '$threshold consecutive missed check-ins → auto SMS to emergency contacts + local push';
  }

  @override
  String get reminderHubSafetyDescDisabled =>
      'Off · Won\'t auto-notify emergency contacts';

  @override
  String reminderHubSafetyStatusEnabled(int threshold) {
    return 'Enabled · Threshold $threshold days';
  }

  @override
  String reminderHubMedicationDescActive(int count, int times) {
    return '$count active medications, reminders at $times time slots';
  }

  @override
  String get reminderHubMedicationDescInactive =>
      'No active medications · Auto-enabled after adding one';

  @override
  String reminderHubMedicationStatusActive(int count, int times) {
    return 'Enabled · $count meds / $times slots';
  }

  @override
  String get reminderHubStatusNotConfigured => 'Not configured';

  @override
  String get reminderHubManageMedication => 'Manage medications';

  @override
  String get reminderHubRefillDescNone =>
      'No refill dates set · Add in \"Medication Settings\"';

  @override
  String reminderHubRefillDescOverdue(int overdue, int inWindow) {
    return '$overdue overdue refills · $inWindow in reminder window';
  }

  @override
  String reminderHubRefillDescActive(int count) {
    return '$count medications with refill dates · Reminders sent when due';
  }

  @override
  String reminderHubRefillStatusOverdue(int count) {
    return '$count overdue';
  }

  @override
  String reminderHubRefillStatusInWindow(int count) {
    return 'Reminding $count';
  }

  @override
  String reminderHubRefillStatusActive(int count) {
    return 'Enabled · $count meds';
  }

  @override
  String get reminderHubManageRefill => 'Manage refills';

  @override
  String get reminderHubEnable => 'Enable';

  @override
  String get reminderHubAssessmentSubtitle =>
      'Get a psychological assessment reminder every N days';

  @override
  String get reminderHubInterval => 'Reminder interval';

  @override
  String reminderHubEveryNDays(int days) {
    return 'Every $days days';
  }

  @override
  String get reminderHubSafetyDescription =>
      'N consecutive missed check-ins → auto SMS to all enabled emergency contacts + local push';

  @override
  String get reminderHubTriggerThreshold =>
      'Trigger threshold (consecutive N days missed)';

  @override
  String reminderHubNDays(int days) {
    return '$days days';
  }
}

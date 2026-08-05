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
  String get setupName => 'Your name (optional)';

  @override
  String get setupNameHint => 'Alex';

  @override
  String get setupContacts => 'Emergency contact (optional)';

  @override
  String get setupAddContact => '+ Add another contact';

  @override
  String get setupContactConsent =>
      'If you add a contact, please notify them that the app may send them a safety message (required by law)';

  @override
  String get setupNext => 'Next →';

  @override
  String get setupMedNameHint => 'e.g. as printed on the box (optional)';

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
  String get setupPrivacy2 => '• Never uploaded to any server';

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
  String get settingsAboutVersion => 'v0.23.0 · I took my meds today';

  @override
  String get settingsDisclaimerText =>
      'This app does not provide medical advice. All features are for reference only.';

  @override
  String get settingsExportRiskTitle => 'Plaintext risk warning';

  @override
  String get settingsExportRiskBody =>
      'You are about to export data as a PLAINTEXT file containing your sensitive personal information (medication, check-ins, emergency contacts, vent text). Save it securely (encrypted USB / private cloud), never upload to public cloud or share with untrusted parties.';

  @override
  String get settingsExportRiskLiability =>
      'Once exported, the security and confidentiality of the file is your responsibility. ChronicCare no longer bears protection duty (PIPL §17 informed + user-confirmed).';

  @override
  String get settingsExportRiskAcknowledge =>
      'I understand the risks, continue';

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
  String get settingsClearAllData => 'Clear all data';

  @override
  String get settingsClearAllDataSubtitle =>
      'Delete all check-ins / meds / assessments / vent / contacts (irreversible)';

  @override
  String get settingsClearAllDataDialogTitle => 'Clear all data?';

  @override
  String get settingsClearAllDataDialogBody =>
      'The following data will be permanently deleted:\n• Check-in history\n• Medication and dose history\n• Assessment results\n• Mood journal\n• Vent (text + audio)\n• Emergency contacts\n\nAfter clearing, the app returns to first-time setup. We recommend exporting a JSON backup first.';

  @override
  String get settingsClearAllDataConfirm => 'I have backed up, clear it';

  @override
  String get settingsClearAllDataSuccess => 'All data cleared';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get lastStartupErrorBannerBody =>
      'Last startup error, please screenshot and report';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonConfirmDelete => 'Delete this?';

  @override
  String get commonOptionNotSelected => 'Not selected';

  @override
  String legalConsentWithdrawn(int current, int total) {
    return 'Withdrawn ($current/$total)';
  }

  @override
  String legalConsentReAgreed(int current, int total) {
    return 'Re-agreed ($current/$total)';
  }

  @override
  String commonLoadFailed(String error) {
    return 'Load failed: $error';
  }

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
  String get commonMedName => 'Medication';

  @override
  String get commonDoseUnit => 'tablet';

  @override
  String get commonSetup => 'Set up';

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
  String get medsListNoActiveHint =>
      'All medications have been stopped. Add a new one to start a new phase.';

  @override
  String get medsListAddAction => 'Add medication';

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
  String get notificationStatusCardOemBrandSamsung => 'Samsung (OneUI)';

  @override
  String get notificationStatusCardOemStepSamsung1 =>
      'Settings → Apps → Chronic Care → Notifications → Enable all';

  @override
  String get notificationStatusCardOemStepSamsung2 =>
      'Settings → Battery → Background usage limits → Chronic Care → Unrestricted';

  @override
  String get notificationStatusCardOemBrandOthers =>
      'Others (ZTE / Nubia / Red Magic / Lenovo / Samsung Knox)';

  @override
  String get notificationStatusCardOemStepOthers1 =>
      'Settings → Apps → Chronic Care → Notifications → Enable all';

  @override
  String get notificationStatusCardOemStepOthers2 =>
      'Settings → Battery → Background running → Allow';

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

  @override
  String setupContactNameLabel(int index) {
    return 'Contact $index name';
  }

  @override
  String get setupContactNameHint => 'Name (optional)';

  @override
  String setupContactPhoneLabel(int index) {
    return 'Emergency contact phone $index';
  }

  @override
  String get setupContactPhoneHint => '13800138000';

  @override
  String get ventListTitle => 'My Vent';

  @override
  String get legalVentWithdrawTitle => 'Withdraw Vent consent';

  @override
  String get legalVentWithdrawBody =>
      'Vent contains your most private content. After withdrawing consent, you can choose how to handle existing data:';

  @override
  String get legalVentWithdrawDelete => 'Delete now';

  @override
  String get legalVentWithdrawDeleteDesc =>
      'All Vent text + audio files permanently deleted, cannot be recovered';

  @override
  String get legalVentWithdrawSeal => 'Encrypt and seal';

  @override
  String get legalVentWithdrawSealDesc =>
      'Data stays locally but encrypted, hidden in UI, recoverable after re-consent';

  @override
  String legalVentWithdrawnDeleted(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count entries',
      one: 'Deleted 1 entry',
      zero: 'Deleted 0 entries',
    );
    return '$_temp0';
  }

  @override
  String get legalVentWithdrawnSealed =>
      'Encrypted and sealed, data preserved locally';

  @override
  String get legalVentDeleteRetry => 'Retry delete';

  @override
  String get ventSealedTitle => 'Encrypted & Sealed';

  @override
  String get ventSealedSubtitle =>
      'You withdrew Vent consent. All data is encrypted and hidden. Re-consent to restore.';

  @override
  String get ventSealedAction => 'Go to Legal & Privacy';

  @override
  String get ventListWriteTooltip => 'Write one';

  @override
  String get ventEmptyTitle => 'Vent is empty';

  @override
  String get ventEmptySubtitle =>
      'Say what\'s on your mind. Text or voice, whatever feels right.\nOnly you can see these words.';

  @override
  String get ventEmptyAction => 'Write the first line';

  @override
  String get ventVoiceLabel => '🎙️ Voice';

  @override
  String get ventDetailTitle => 'Vent';

  @override
  String get ventDetailNotFound => 'Not found';

  @override
  String get ventDetailPrivacy => '🔒 Private · Only you can see';

  @override
  String get ventToday => 'Today';

  @override
  String get ventYesterday => 'Yesterday';

  @override
  String get ventComposeTitle => 'Vent';

  @override
  String get ventComposeHint => 'How was your day...';

  @override
  String get ventRecordIdle => 'Tap to start recording';

  @override
  String get ventRecordActive => 'Recording... tap to stop';

  @override
  String get ventAudioLabel => 'Recording';

  @override
  String get ventAudioPlayTooltip => 'Play recording';

  @override
  String get ventAudioPauseTooltip => 'Pause recording';

  @override
  String get ventRerecord => 'Re-record';

  @override
  String ventDurationSeconds(int sec) {
    return '${sec}s';
  }

  @override
  String ventDurationMinutes(int m) {
    return '${m}m';
  }

  @override
  String ventDurationMinutesSeconds(int m, String sec) {
    return '${m}m ${sec}s';
  }

  @override
  String get moodDialogTitle => 'How are you today?';

  @override
  String get moodDimensionMood => 'Mood';

  @override
  String get moodDimensionMoodHint => '1=very bad 5=great';

  @override
  String get moodDimensionEnergy => 'Energy';

  @override
  String get moodDimensionEnergyHint => '1=very low 5=energized';

  @override
  String get moodDimensionSleep => 'Sleep';

  @override
  String get moodDimensionSleepHint => '1=very bad 5=great';

  @override
  String get moodDimensionAnxiety => 'Anxiety';

  @override
  String get moodDimensionAnxietyHint => '1=severe 5=calm';

  @override
  String get moodTagAnxiety => 'Anxious';

  @override
  String get moodTagDepression => 'Depressed';

  @override
  String get moodTagCalm => 'Calm';

  @override
  String get moodTagInsomnia => 'Insomnia';

  @override
  String get moodTagIrritable => 'Irritable';

  @override
  String get moodTagLowEnergy => 'Low energy';

  @override
  String get moodNoteLabel => 'Note (optional)';

  @override
  String get moodNoteHint => 'What happened today?';

  @override
  String get moodAudioRecordButton => 'Record voice';

  @override
  String moodAudioRecorded(String duration) {
    return 'Recorded $duration';
  }

  @override
  String get moodAudioRerecord => 'Re-record';

  @override
  String get moodAudioTranscriptLabel => 'Transcript';

  @override
  String get moodAudioTranscriptPartialHint =>
      '(only the first 60s recognized)';

  @override
  String get moodAudioSttListening => 'Recognizing…';

  @override
  String get moodAudioSttFailed => 'Recognition failed; audio saved only';

  @override
  String get moodAudioSttUnavailable =>
      'Speech-to-text not available on this device';

  @override
  String get moodAudioMaxReached => 'Reached 3-minute limit';

  @override
  String get moodAudioSavedWithPlay => 'Mood saved';

  @override
  String get moodAudioPlayAction => 'Play';

  @override
  String get moodAudioErrorStart => 'Failed to start recording';

  @override
  String get moodAudioErrorStop => 'Failed to stop recording';

  @override
  String get moodAudioErrorEncrypt => 'Failed to encrypt recording';

  @override
  String get moodAudioErrorPlay => 'Failed to play';

  @override
  String get medsTodaySchedule => 'Today\'s Medication Schedule';

  @override
  String get medsTotal => 'Total';

  @override
  String get medsRefillSetCount => 'Set';

  @override
  String get medsRefillReminding => 'Reminding';

  @override
  String get refillManageOverdue => 'Overdue';

  @override
  String get medsNoMedicationsAdded => 'No medications added yet';

  @override
  String get medsRefillEditHint =>
      'Tap any row to edit the refill date. Reminder window: N days before refill (N=reminderDays).';

  @override
  String get medsRefillStatusNotConfigured => 'Not set';

  @override
  String get medsRefillStatusSet => 'Set';

  @override
  String get medsRefillStatusReminding => 'Reminding';

  @override
  String get medsRefillStatusOverdue => 'Overdue';

  @override
  String medsRefillNotSetSubtitle(int days) {
    return 'No refill date set · Reminder window $days days';
  }

  @override
  String medsRefillExpiredDays(int days) {
    return 'Overdue by $days days';
  }

  @override
  String get medsRefillToday => 'Today';

  @override
  String medsRefillRemainingDays(int days) {
    return '$days days left';
  }

  @override
  String medsRefillSubtitleTemplate(
      String date, String suffix, int reminderDays) {
    return '$date $suffix · Remind $reminderDays days before';
  }

  @override
  String get assessmentLoadingBack => 'Returning...';

  @override
  String assessmentAnsweredProgress(int answered, int total) {
    return 'Answered $answered / $total';
  }

  @override
  String get assessmentSubmit => 'Submit & View Results';

  @override
  String assessmentQuestionLabel(int index, String text, String selected) {
    return 'Question $index: $text, 4 options, current: $selected';
  }

  @override
  String assessmentScoreTotal(int max) {
    return 'Total score (0-$max)';
  }

  @override
  String get assessmentRecommendUrgent =>
      'Strongly recommend contacting a doctor or therapist as soon as possible.';

  @override
  String get assessmentRecommend =>
      'Consider consulting your doctor for further evaluation.';

  @override
  String get assessmentDisclaimer =>
      '⚠️ This assessment is for reference only and cannot replace professional diagnosis.\nIf you feel distressed, please consult a doctor.';

  @override
  String get assessmentBack => 'Back';

  @override
  String get assessmentRetake => 'Take Again';

  @override
  String get homeHeaderDefaultTitle => 'Chronic Care';

  @override
  String homeHeaderKeepGoing(String name) {
    return '$name is still going strong';
  }

  @override
  String get homeTooltipTrend => 'View trend';

  @override
  String get homeTooltipAssessmentHistory => 'Assessment history';

  @override
  String get homeStreakRestart => 'Start fresh today 🌱';

  @override
  String get homeStreakDay1 => 'Day 1, taking the first step 🌱';

  @override
  String homeStreakDays(int days) {
    return '$days-day streak, keep going 🌿';
  }

  @override
  String homeStreakGreat(int days) {
    return '$days-day streak 🌳';
  }

  @override
  String homeStreakAmazing(int days) {
    return '$days-day streak 🌲';
  }

  @override
  String homeStreakMaster(int days) {
    return '$days days 🏔️';
  }

  @override
  String get navCheckIn => 'Check in';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAppName => 'Chronic Care';

  @override
  String errorPageNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String get errorPageHint =>
      'This address may have expired or the link is incorrect.';

  @override
  String get errorPageBackHome => 'Back to home';

  @override
  String assessmentReminderEnabled(int days) {
    return 'Enabled: psychological assessment reminder every $days days';
  }

  @override
  String assessmentReminderChanged(int days) {
    return 'Changed to: reminder every $days days';
  }

  @override
  String assessmentReminderSubtitleEnabled(int days) {
    return 'Remind me to take a psychological assessment every $days days';
  }

  @override
  String get assessmentReminderHelpText =>
      'After completing an assessment, the next reminder will be recalculated from today.\nAssessment results are only visible to you.';

  @override
  String get assessmentReminderHintAcute =>
      'High-frequency monitoring (for acute phase)';

  @override
  String get assessmentReminderHintCommon =>
      'Recommended (standard in psychiatry)';

  @override
  String get assessmentReminderHintStable => 'Stable phase / Monthly review';

  @override
  String get assessmentReminderHintMaintenance => 'Maintenance phase';

  @override
  String get assessmentReminderHintLongTerm => 'Long-term follow-up';

  @override
  String get assessmentHistoryTrend => 'Historical Trend';

  @override
  String assessmentAverageScore(String score) {
    return 'Average $score';
  }

  @override
  String assessmentTotalRecords(int count) {
    return '$count times';
  }

  @override
  String assessmentScoreRange(int min, int max) {
    return 'Min $min / Max $max';
  }

  @override
  String get assessmentComparePrevious => 'Compare with Last';

  @override
  String get assessmentFirstAssessmentHint =>
      'This is your first assessment. Comparison will be shown after your next assessment.';

  @override
  String get assessmentPrevious => 'Last';

  @override
  String get assessmentCurrent => 'This time';

  @override
  String assessmentDaysSincePrevious(int days) {
    return '$days days since last';
  }

  @override
  String get assessmentHistoryEmpty => 'No assessment records yet';

  @override
  String get assessmentHistoryEmptyHint =>
      'Records will appear here after completing a psychological assessment';

  @override
  String get assessmentHistoryStartFirst => 'Start First Assessment';

  @override
  String get assessmentHistoryTotalAssessments => 'Total Assessments';

  @override
  String get assessmentHistoryTimes => 'times';

  @override
  String get assessmentHistoryLatestPhq9 => 'Latest PHQ-9';

  @override
  String get assessmentHistoryLatestGad7 => 'Latest GAD-7';

  @override
  String get assessmentHistoryNotDone => 'Not done';

  @override
  String get assessmentChartNoData => 'No data yet';

  @override
  String get assessmentChartNeedMore =>
      'Only 1 assessment — need at least 2 to show trend';

  @override
  String assessmentChartRecordCount(int count) {
    return '$count assessments';
  }

  @override
  String assessmentChartTotalScore(int score, int max) {
    return 'Total $score/$max';
  }

  @override
  String get assessmentHistoryFullRecord => 'Full Record';

  @override
  String get assessmentSeverityNormal => 'Minimal';

  @override
  String get assessmentSeverityMild => 'Mild';

  @override
  String get assessmentSeverityModerate => 'Moderate';

  @override
  String get assessmentSeverityModeratelySevere => 'Moderately Severe';

  @override
  String get assessmentSeveritySevere => 'Severe';

  @override
  String get assessmentSeverityUnknown => 'Unknown';

  @override
  String get assessmentScalePhq9 => 'PHQ-9 Depression Screening';

  @override
  String get assessmentScaleGad7 => 'GAD-7 Anxiety Screening';

  @override
  String get setupConsentRequired =>
      'Please read and agree to the legal documents first';

  @override
  String get setupValidationNameRequired => 'Please enter your name';

  @override
  String get setupValidationPhoneInvalid => 'Invalid phone number format';

  @override
  String get setupValidationPhoneDuplicate =>
      'Emergency contact phone numbers cannot be duplicated';

  @override
  String get setupPresetTitle => '📋 Choose a Preset';

  @override
  String get setupPresetDescription =>
      'Presets fill in medication names + times. You can modify them. Always follow your doctor\'s instructions.';

  @override
  String setupPresetLoaded(String name, int count) {
    return 'Loaded: $name ($count medications). Please verify names and dosages.';
  }

  @override
  String get setupMedWhatDoYouTake => 'What medications do you take?';

  @override
  String get setupMedMultiDrugHint =>
      '(Add multiple medications, each with its own time and dosage; skipping won\'t affect check-in)';

  @override
  String get setupMedEmptyHint =>
      'No medications added yet. You can skip — check-in doesn\'t require medication info.';

  @override
  String get setupMedAddDrug => '+ Add Medication';

  @override
  String get setupMedLoadPreset => '📋 Load Preset (4 common patterns)';

  @override
  String get setupBack => '← Back';

  @override
  String setupMedDrugNumber(int number) {
    return 'Medication $number';
  }

  @override
  String get setupMedDeleteDrug => 'Delete this medication';

  @override
  String get setupMedDosage => 'Dosage';

  @override
  String get setupMedUnit => 'Unit';

  @override
  String get setupMedTimeHint => 'Dose times (tap + to add)';

  @override
  String get setupMedAddTime => 'Add time';

  @override
  String get setupMedTimeOptional =>
      '(No time set = no reminder scheduled, record only)';

  @override
  String get setupConsentTitle => 'Please Read Before Use';

  @override
  String get setupConsentDescription =>
      'To comply with PIPL, this app requires your explicit consent before processing your sensitive health data. Please review and agree to the following 3 documents.';

  @override
  String get setupConsentUserAgreement =>
      'I have read and agree to the User Agreement';

  @override
  String get setupConsentPrivacyPolicy =>
      'I have read and agree to the Privacy Policy';

  @override
  String get setupConsentSensitiveData =>
      'I have read and agree to the Sensitive Data Consent';

  @override
  String get setupConsentStart => 'Start Setup';

  @override
  String get setupConsentWithdrawHint =>
      'Tip: You can withdraw consent anytime in Settings → Legal & Privacy. Some features will be unavailable after withdrawal.';

  @override
  String get setupWelcomeContactHint =>
      '(Optional — you can add later in Settings)';

  @override
  String get setupLegalUserAgreement => 'User Agreement';

  @override
  String get setupLegalPrivacyPolicy => 'Privacy Policy';

  @override
  String get setupLegalSensitiveData => 'Sensitive Data Consent';

  @override
  String get setupLegalLoadFailed =>
      'Failed to load. Please check your network or reopen the app.';

  @override
  String get setupConsentView => 'View';

  @override
  String get settingsLegalAndPrivacy => 'Legal & privacy';

  @override
  String get settingsLegalAndPrivacySubtitle =>
      'View agreement, privacy policy, withdraw consent';

  @override
  String get legalPageTitle => 'Legal & privacy';

  @override
  String get legalPageDocuments => 'Legal documents';

  @override
  String get legalPageWithdrawTitle => 'Withdraw consent';

  @override
  String get legalPageWithdrawDescription =>
      'After withdrawing, the related feature is immediately disabled (data is kept, can be re-enabled).';

  @override
  String get legalPageWithdrawSafety => 'Withdraw safety notification consent';

  @override
  String get legalPageWithdrawSafetySubtitle =>
      'Stop sending SMS/email to emergency contacts when you miss check-ins';

  @override
  String get legalPageWithdrawVent => 'Withdraw vent (sensitive) consent';

  @override
  String get legalPageWithdrawVentSubtitle =>
      'Stop storing new vent text/audio (existing data kept, delete manually)';

  @override
  String get legalPageWithdrawAnalytics =>
      'Withdraw assessment/mood analytics consent';

  @override
  String get legalPageWithdrawAnalyticsSubtitle =>
      'Stop including assessments/mood in trend analysis (data kept, charts skip)';

  @override
  String legalPageConsentRecorded(Object time) {
    return 'Withdrawn at: $time';
  }

  @override
  String get legalPageConsentNever => 'Never withdrawn';

  @override
  String get emailPreviewTitle => 'Notification Preview';

  @override
  String get emailPreviewSetupRequired =>
      'Please complete the initial setup first';

  @override
  String get emailPreviewDescription =>
      'This is a preview of the safety notification you\'ll receive:';

  @override
  String get emailPreviewNoContact => '(No contacts)';

  @override
  String get emailPreviewDisclaimer =>
      '💡 This is only a preview. Actual SMS is sent automatically after 2 missed check-ins (mock in v0.6, real SMS provider in v1.0+).';

  @override
  String get reportHistoryEmpty =>
      'No report history yet\nReports will be recorded automatically after generation';

  @override
  String reportHistoryItemTitle(String date, int days) {
    return '$date · Last $days days';
  }

  @override
  String reportHistoryItemPatient(String name) {
    return 'Patient: $name';
  }

  @override
  String get reportHistoryItemNotSet => 'Not set';

  @override
  String get reportHistoryDeleteTitle => 'Delete this report?';

  @override
  String get reportHistoryDeleteContent =>
      'Cannot be restored after deletion, but can be regenerated.';

  @override
  String get homeCelebrationDay1 => 'Recorded! Day 1 🌱';

  @override
  String homeCelebrationStreakShort(int days) {
    return 'Recorded! $days-day streak 🌿';
  }

  @override
  String homeCelebrationStreakMedium(int days) {
    return 'Recorded! $days-day streak 🌳';
  }

  @override
  String homeCelebrationStreakLong(int days) {
    return 'Recorded! $days-day streak 🌲';
  }

  @override
  String homeCelebrationStreakMaster(int days) {
    return 'Recorded! $days days 🏔️';
  }

  @override
  String homeAutofireCelebration(String name) {
    return 'Checked in: $name ✅';
  }

  @override
  String get homeAutofireFallbackName => 'this med';

  @override
  String homeMedHint(int id) {
    return '💊 Ready to check in medication #$id';
  }

  @override
  String get homeSafetyAlertSuffix =>
      '(please check in or contact family soon)';

  @override
  String safetyAlertBodySent(String date) {
    return 'Last check-in: $date. Auto-notified emergency contacts. Please confirm safety.';
  }

  @override
  String safetyAlertBodyMocked(String date) {
    return 'Last check-in: $date. Lost-contact detection triggered, but currently in dev mode — emergency contacts were **NOT** actually notified.';
  }

  @override
  String safetyAlertBodyFailed(String date) {
    return 'Last check-in: $date. Lost-contact detection triggered, but notification failed. Please check network.';
  }

  @override
  String safetyAlertTitle(String name, int days) {
    return '⚠️ $name hasn\'t checked in for $days days';
  }

  @override
  String get safetyAlertNeverCheckIn => 'No check-ins yet';

  @override
  String get homeSnoozeTitle => '⏰ Time to check in (in 5 min)';

  @override
  String get notifChannelMedicationName => 'Medication reminder';

  @override
  String get notifChannelMedicationDesc =>
      'Reminds you to check in when it\'s time';

  @override
  String get notifChannelSafetyName => 'Safety alert';

  @override
  String get notifChannelSafetyDesc =>
      'Alerts when you haven\'t checked in for a long time';

  @override
  String get homeSnoozeBody => 'You snoozed earlier — time to tap and check in';

  @override
  String get homeSnoozeConfirmed => 'OK, will remind you again in 5 min 👌';

  @override
  String get homeSnoozeButton => '⏰ Remind again in 5 min';

  @override
  String get homeVentButton => 'Vent 🌲';

  @override
  String get homeNotifBannerText =>
      'Reminders not set — you may miss check-ins. Please enable notifications in system settings.';

  @override
  String get homeNotifBannerDismiss => 'Got it';

  @override
  String themeTooltip(String mode) {
    return 'Theme: $mode (tap to switch)';
  }

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get trendTitle => 'My Trend';

  @override
  String get trendLast30Days => 'Last 30 Days';

  @override
  String get trendLast6Months => 'Last 6 Months';

  @override
  String get trendAssessmentHistory => 'Assessment History';

  @override
  String get trendMoodHistory => 'Mood History';

  @override
  String get trendViewList => 'List';

  @override
  String get trendViewCalendar => 'Calendar';

  @override
  String get trendWithdrawnTitle => 'Trend analysis paused';

  @override
  String get trendWithdrawnSubtitle =>
      'You withdrew consent for \"Trend analysis\" (PIPL §14). Your data is not deleted — re-enable anytime to restore the charts.';

  @override
  String get trendWithdrawnAction => 'Re-enable';

  @override
  String get trendWeekdayMon => 'Mo';

  @override
  String get trendWeekdayTue => 'Tu';

  @override
  String get trendWeekdayWed => 'We';

  @override
  String get trendWeekdayThu => 'Th';

  @override
  String get trendWeekdayFri => 'Fr';

  @override
  String get trendWeekdaySat => 'Sa';

  @override
  String get trendWeekdaySun => 'Su';

  @override
  String get trendPrevMonth => 'Previous month';

  @override
  String get trendNextMonth => 'Next month';

  @override
  String trendMonthYear(int year, int month) {
    return '$month/$year';
  }

  @override
  String get trendCheckedIn => 'Checked in';

  @override
  String get trendNotCheckedIn => 'Not checked in';

  @override
  String trendEventCount(int count) {
    return '$count events';
  }

  @override
  String trendMoodEntriesSame(int count, String emoji) {
    return '$count mood entries · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, String lowEmoji, String highEmoji) {
    return 'Mood $count entries · $lowEmoji→$highEmoji';
  }

  @override
  String get trendNoRecords => 'No records for this day';

  @override
  String get trendStatCurrentStreak => 'Current Streak';

  @override
  String get trendStatLongestStreak => 'Longest Streak';

  @override
  String get trendStatTotalCheckIns => 'Total Check-ins';

  @override
  String get trendStatTotalDays => 'Total Days';

  @override
  String trendStatDaysValue(int count) {
    return '$count days';
  }

  @override
  String trendMonthLabel(int month) {
    return '$month';
  }

  @override
  String get trendNoAssessments => 'No assessment records yet';

  @override
  String get trendNoAssessmentsHint =>
      'Complete an assessment and the chart will appear here';

  @override
  String get trendNoMoodEntries => 'No mood entries yet';

  @override
  String get trendNoMoodEntriesHint =>
      'Tap \"Log Mood\" on the home page to start tracking';

  @override
  String get trendCbtReratedChartTitle => 'Rerating effect';

  @override
  String get trendCbtReratedEmptyTitle => 'No 5/7-column CBT data yet';

  @override
  String get trendCbtReratedEmptyHint =>
      'Fill in a 5/7-column CBT thought record first to see your rerating effect';

  @override
  String get contactEmptyList => 'No contacts yet — add one';

  @override
  String get contactAddAction => 'Add contact';

  @override
  String get contactAddTitle => 'Add Emergency Contact';

  @override
  String get contactConsentTitle => 'Informed Consent';

  @override
  String contactConsentBody(int threshold) {
    return 'You are about to save this contact\'s phone number in the local database. If you don\'t check in for $threshold consecutive days, the app will automatically notify this contact via SMS.\n\n**Per PIPL Article 29** (sensitive personal information requires separate consent), please confirm you have informed the contact of the above purpose and obtained their explicit consent.';
  }

  @override
  String get contactConsentAgree => 'I have informed and obtained consent';

  @override
  String get contactConsentReject => 'Decline for now';

  @override
  String get contactConsentVersion => 'v1 · 2026-07-31';

  @override
  String get dataExportConsentTitle => 'Data Export Consent';

  @override
  String dataExportConsentBody(
      String purpose, String dataCategories, String retention) {
    return 'You are about to export all data from the local database.\n\n**Purpose**: $purpose\n**Data scope**: $dataCategories\n**Retention**: $retention\n\n**Per PIPL Article 13** (data portability + standalone consent), please confirm you understand the above purpose and consent to this export.';
  }

  @override
  String get dataExportConsentConfirm => 'I understand and consent to export';

  @override
  String get dataExportConsentVersion => 'v1 · 2026-08-15';

  @override
  String get contactDefaultName => 'Contact';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactPhoneLabel => 'Phone';

  @override
  String get commonActionDelete => 'Delete';

  @override
  String get commonActionSave => 'Save';

  @override
  String get editMedDialogTitle => 'Edit Medication';

  @override
  String get editMedValidationNameRequired => 'Please enter medication name';

  @override
  String get editMedValidationDosageInvalid => 'Dosage must be greater than 0';

  @override
  String get editMedValidationUnitInvalid => 'Unit must be mg or tablet';

  @override
  String editMedSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get editMedStatusActive => 'In use';

  @override
  String get editMedStatusStopped => 'Stopped';

  @override
  String editMedStoppedDate(String date) {
    return '$date stopped';
  }

  @override
  String get editMedNameHint => 'Name as printed on the box (optional)';

  @override
  String get editMedDosageLabel => 'Dosage';

  @override
  String get editMedUnitLabel => 'Unit';

  @override
  String get editMedTimeSectionLabel => 'Dose times (tap + to add)';

  @override
  String get editMedAddTime => 'Add time';

  @override
  String get editMedNoTimeHint => '(No time set = no reminders, record only)';

  @override
  String get editMedStopAction => 'Stop this medication';

  @override
  String get editMedResumeAction => 'Re-enable';

  @override
  String get editMedStopHint =>
      'Soft stop: keeps all history, no more reminders';

  @override
  String get editMedResumeHint =>
      'Resume: clear stop date, resume daily reminders';

  @override
  String get medReportCopyHint =>
      'Select all to copy, generate PDF, or share with your doctor';

  @override
  String get medReportPdfLabel => 'PDF';

  @override
  String get medReportShareLabel => 'Share';

  @override
  String get medReportPdfLoading => 'Generating PDF...';

  @override
  String get medReportShareSubject => 'Chronic Care · Medication Report';

  @override
  String get tempMedDialogTitle => 'Add Temporary Medication';

  @override
  String get tempMedLinkLabel => 'Link to regular medication (optional)';

  @override
  String get tempMedLinkHint => 'None = one-time event';

  @override
  String get tempMedNoLink => 'No link';

  @override
  String get tempMedNameHint => 'e.g. Ibuprofen';

  @override
  String get tempMedReasonLabel => 'Reason';

  @override
  String get tempMedReasonHint => 'e.g. cold';

  @override
  String get medsCalendarHeatmapDesc =>
      'Adherence heatmap by medication. Darker = closer to expected daily doses.';

  @override
  String get medsCalendarWindow7 => '7 days';

  @override
  String get medsCalendarWindow30 => '30 days';

  @override
  String get medsCalendarWindow90 => '90 days';

  @override
  String medsCalendarLoadCheckinFailed(String error) {
    return 'Failed to load check-ins: $error';
  }

  @override
  String medsCalendarLoadMedFailed(String error) {
    return 'Failed to load medications: $error';
  }

  @override
  String get medsCalendarNoActive => 'No active medications yet';

  @override
  String get medsCalendarNoSchedule =>
      'Active medications have no dose times set, cannot generate adherence calendar';

  @override
  String get medsCalendarNoScheduleHint =>
      'After you add dose times on the medication page, the adherence calendar will appear here.';

  @override
  String get medsCalendarNoActiveAction => 'Add medication';

  @override
  String get medsCalendarNoScheduleAction => 'Add schedule';

  @override
  String get medsCalendarLegendLabel => 'Adherence:';

  @override
  String get medsCalendarLegendMissed => 'Missed';

  @override
  String get window7Subtitle => 'Within a week (good for weekly visits)';

  @override
  String get window14Subtitle => 'Within two weeks (recommended)';

  @override
  String get window30Subtitle => 'Within a month (good for monthly reviews)';

  @override
  String get snackbarActionSave => 'Save';

  @override
  String get snackbarActionShare => 'Share';

  @override
  String get snackbarActionGeneratePdf => 'Generate PDF';

  @override
  String get snackbarActionPlay => 'Play';

  @override
  String get snackbarActionEncryptRecording => 'Encrypt recording';

  @override
  String get snackbarActionRecord => 'Record';

  @override
  String get snackbarActionStartRecording => 'Start recording';

  @override
  String get snackbarActionCheckin => 'Check-in';

  @override
  String get snackbarActionSnooze => 'Snooze';

  @override
  String get snackbarActionAutoCheckin => 'Auto check-in';

  @override
  String get snackbarActionFinishSetup => 'Finish setup';

  @override
  String get snackbarActionUndo => 'Undo';

  @override
  String get ventEntryDeleted => 'Vent entry deleted';

  @override
  String get contactDeleted => 'Contact deleted';

  @override
  String get medicationDeleted => 'Medication deleted';

  @override
  String get moodTodayLabel => 'Mood: ';

  @override
  String get moodRecordButton => 'Log mood ✏️';

  @override
  String medReportFileName(String date) {
    return 'Med Report_$date';
  }

  @override
  String get migrationPromptTitle => 'Upgrading to v0.9';

  @override
  String get migrationPromptDetectedOld =>
      'Old version data detected on this device.';

  @override
  String get migrationPromptChangesTitle => 'This upgrade will:';

  @override
  String get migrationPromptChangeEncrypt =>
      '• Enable database encryption (protects your privacy)';

  @override
  String get migrationPromptChangeClear => '• Clear all old check-in records';

  @override
  String get migrationPromptChangeWarning =>
      '(The old version had no \"Export data\" feature, so the original data cannot be recovered)';

  @override
  String get migrationPromptRecommendExport =>
      'Recommendation: First complete \"Export data\" in the old version, then upgrade.';

  @override
  String get migrationPromptDirectContinue =>
      'If the old version is already uninstalled, you can tap \"Continue upgrade\" directly.';

  @override
  String get migrationPromptCancel => 'Cancel';

  @override
  String get migrationPromptContinue => 'Continue upgrade';

  @override
  String get migrationAbortedTitle => 'Upgrade cancelled';

  @override
  String get migrationAbortedBody =>
      'Please complete \"Export data\" in the old version first,\nthen tap the button below to continue the upgrade.';

  @override
  String get migrationAbortedRetry => 'Already backed up, continue';

  @override
  String get migrationFailedTitle => 'Failed to start';

  @override
  String get migrationFailedBody =>
      'Unable to initialize local data.\nPlease try:\n1) Restart the app\n2) Uninstall and reinstall\nIf the problem persists, please contact us.';

  @override
  String get migrationFailedReassure =>
      'Don\'t worry, your data is encrypted. We\'ll resolve this soon.';

  @override
  String get moodRatingSemantics => 'Mood rating, 1 to 5 scale, 5 is best';

  @override
  String moodRatingButtonSemantics(Object score, String selected) {
    String _temp0 = intl.Intl.selectLogic(
      selected,
      {
        'true': ', selected',
        'other': '',
      },
    );
    return '$score out of 5$_temp0';
  }

  @override
  String medicationTimeWindowSemantics(Object days) {
    return 'Time window $days days, 7/30/90 single select';
  }

  @override
  String get assessmentSaveFailed =>
      'Result shown but save failed. Please try again later.';

  @override
  String setupContactFallbackName(int index) {
    return 'Contact $index';
  }

  @override
  String get setupConsentRejected =>
      'Consent for this contact was rejected, not saved. Refill and continue.';

  @override
  String emailBodyI18n(String name, int days) {
    return 'I\'m $name. I haven\'t checked in on the app for $days days.\nCould you remind me to take my medication on time when convenient, to avoid relapse?';
  }

  @override
  String get emailFooterI18n =>
      'This is an automated notification sent by the Chronic Care app.\nThis notification contains no medical advice.\nTo stop receiving these, please update your preferences in the app settings.';

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => 'tablet';

  @override
  String get safetyCheckResultDisabled => 'Safety watch is disabled';

  @override
  String safetyCheckResultOk(int days) {
    return 'OK (last check-in $days days ago)';
  }

  @override
  String get safetyCheckResultNoData => 'New user, no check-ins yet';

  @override
  String safetyCheckResultAlertedToday(int days) {
    return 'Alert already sent today (last check-in $days days ago)';
  }

  @override
  String get safetyCheckResultDndSuppressed => 'DND window, alert skipped';

  @override
  String get safetyCheckResultNoContacts =>
      'No emergency contacts, alert not sent';

  @override
  String safetyCheckResultAlertedMocked(int mocked) {
    return '**Dev mode**, contacts not actually notified (mock: $mocked)';
  }

  @override
  String safetyCheckResultAlerted(int days, int notified, int failed) {
    return 'Alerted: $days days since last check-in, $notified contact(s) notified ($failed failed)';
  }

  @override
  String safetyCheckResultError(String message) {
    return 'Error: $message';
  }

  @override
  String get settingsIapUpgradeTitle => 'Upgrade to Pro';

  @override
  String get settingsIapUpgradeSubtitle =>
      '¥8 one-time purchase · unlock all premium features';

  @override
  String get settingsIapProOwnedTitle => 'You\'re on Pro';

  @override
  String get settingsIapProOwnedSubtitle =>
      'Thanks for the support · all premium features unlocked';

  @override
  String get iapPurchaseSuccess => 'Upgrade successful! Welcome to Pro.';

  @override
  String get iapPurchaseFailed =>
      'Purchase not completed. Please try again later.';

  @override
  String get phoneRegionCn => 'Mainland China';

  @override
  String get phoneRegionHk => 'Hong Kong, China';

  @override
  String get phoneRegionMo => 'Macao, China';

  @override
  String get phoneRegionTw => 'Taiwan, China';

  @override
  String get phoneRegionIntl => 'International';

  @override
  String get presetMedSsriMorningTitle => 'Single med · SSRI morning';

  @override
  String get presetMedSsriMorningDesc =>
      '1 medication, taken daily at 8 AM (for SSRI / SNRI class)';

  @override
  String get presetMedMoodStabilizerTwiceTitle =>
      'Mood stabilizer · morning & evening';

  @override
  String get presetMedMoodStabilizerTwiceDesc =>
      '1 medication, daily at 8 AM and 8 PM';

  @override
  String get presetMedComboSsriBedtimeTitle =>
      'Combo · morning antidepressant + bedtime sleep aid';

  @override
  String get presetMedComboSsriBedtimeDesc =>
      '2 meds: SSRI at 8 AM + sleep aid at 9 PM';

  @override
  String get presetMedComboAntipsychoticFullTitle =>
      'Severe · morning / noon / evening';

  @override
  String get presetMedComboAntipsychoticFullDesc =>
      '2 meds: 8 AM / 1 PM / 8 PM, full-day coverage';

  @override
  String get presetMedSsriName => 'SSRI antidepressant';

  @override
  String get presetMedSsriHint =>
      'Common SSRI / SNRI antidepressants (follow your doctor\'s prescription)';

  @override
  String get presetMedMoodStabilizerName => 'Mood stabilizer';

  @override
  String get presetMedMoodStabilizerHint =>
      'Common mood stabilizers (follow your doctor\'s prescription)';

  @override
  String get presetMedSleepAidName => 'Sleep aid';

  @override
  String get presetMedSleepAidHint =>
      'Common benzodiazepines / sleep aids (follow your doctor\'s prescription)';

  @override
  String get presetMedAntipsychoticName => 'Antipsychotic';

  @override
  String get presetMedAntipsychoticHint =>
      'Common atypical antipsychotics (follow your doctor\'s prescription)';

  @override
  String get presetMedSedativeAnxiolyticName => 'Sedative / anxiolytic adjunct';

  @override
  String get presetMedSedativeAnxiolyticHint =>
      'Common sedative / anxiolytic adjuncts (follow your doctor\'s prescription)';

  @override
  String get checkInTypeDaily => 'Daily check-in';

  @override
  String get checkInTypeTemp => 'Temp dose';

  @override
  String get checkInTypePhq9 => 'PHQ-9 assessment';

  @override
  String get checkInTypeGad7 => 'GAD-7 assessment';

  @override
  String dayDetailCheckInWith(String name) {
    return 'Check-in · $name';
  }

  @override
  String get dayDetailDailyCheckIn => 'Daily check-in';

  @override
  String dayDetailTempWith(String name) {
    return 'Temp · $name';
  }

  @override
  String get dayDetailTempMed => 'Temp dose';

  @override
  String get dayDetailPhq9 => 'PHQ-9 Depression Screening';

  @override
  String get dayDetailGad7 => 'GAD-7 Anxiety Screening';

  @override
  String get scaleHotlineCn => 'National 24h Psychological Aid Hotline';

  @override
  String get scaleHotlineCn2 => 'Beijing Suicide Research & Prevention Center';

  @override
  String get scaleHotlineUs => '988 Suicide & Crisis Lifeline (US)';

  @override
  String get scaleHotlineUs2 => 'Crisis Text Line (text HOME to 741741)';

  @override
  String get scaleHotlineHk =>
      'Samaritans Befrienders Hong Kong (24h multilingual)';

  @override
  String get scaleHotlineTw => 'Lifeline Taiwan (24h)';

  @override
  String get scaleHotlineTw2 => '1925 Mental Health Counseling Line';

  @override
  String get scaleHotlineSg => 'Samaritans of Singapore (24h)';

  @override
  String get scaleHotlineUk => 'Samaritans UK & ROI (24h free)';

  @override
  String get scaleHotlineIntl =>
      'International · contact local emergency or mental health services';

  @override
  String get scaleCrisisTitle => 'We care about you';

  @override
  String get scaleCrisisMessage =>
      'You mentioned thoughts of harming yourself.\nRemember: seeking help is brave, not weak.';

  @override
  String get phq9Item0 => 'Little interest or pleasure in doing things';

  @override
  String get phq9Item1 => 'Feeling down, depressed, or hopeless';

  @override
  String get phq9Item2 =>
      'Trouble falling or staying asleep, or sleeping too much';

  @override
  String get phq9Item3 => 'Feeling tired or having little energy';

  @override
  String get phq9Item4 => 'Poor appetite or overeating';

  @override
  String get phq9Item5 =>
      'Feeling bad about yourself — or that you are a failure or have let yourself or your family down';

  @override
  String get phq9Item6 =>
      'Trouble concentrating on things, such as reading the newspaper or watching television';

  @override
  String get phq9Item7 =>
      'Moving or speaking so slowly that other people could have noticed? Or the opposite — being so fidgety or restless that you have been moving around a lot more than usual';

  @override
  String get phq9Item8 =>
      'Thoughts that you would be better off dead, or of hurting yourself in some way';

  @override
  String get phq9Option0 => 'Not at all';

  @override
  String get phq9Option1 => 'Several days';

  @override
  String get phq9Option2 => 'More than half the days';

  @override
  String get phq9Option3 => 'Nearly every day';

  @override
  String get phq9SeverityLabel0 => 'None';

  @override
  String get phq9SeverityLabel1 => 'Mild';

  @override
  String get phq9SeverityLabel2 => 'Moderate';

  @override
  String get phq9SeverityLabel3 => 'Moderately severe';

  @override
  String get phq9SeverityLabel4 => 'Severe';

  @override
  String get phq9SeveritySummary0 => 'Minimal or no depression';

  @override
  String get phq9SeveritySummary1 => 'Mild depression';

  @override
  String get phq9SeveritySummary2 => 'Moderate depression';

  @override
  String get phq9SeveritySummary3 => 'Moderately severe depression';

  @override
  String get phq9SeveritySummary4 => 'Severe depression';

  @override
  String get phq9Instruction =>
      'Over the last 2 weeks, how often have you been bothered by the following problems?';

  @override
  String get phq9ShortDescription =>
      'Depression screening over the last 2 weeks';

  @override
  String get gad7Item0 => 'Feeling nervous, anxious or on edge';

  @override
  String get gad7Item1 => 'Not being able to stop or control worrying';

  @override
  String get gad7Item2 => 'Worrying too much about different things';

  @override
  String get gad7Item3 => 'Trouble relaxing';

  @override
  String get gad7Item4 => 'Being so restless that it is hard to sit still';

  @override
  String get gad7Item5 => 'Becoming easily annoyed or irritable';

  @override
  String get gad7Item6 => 'Feeling afraid as if something awful might happen';

  @override
  String get gad7SeverityLabel0 => 'None';

  @override
  String get gad7SeverityLabel1 => 'Mild';

  @override
  String get gad7SeverityLabel2 => 'Moderate';

  @override
  String get gad7SeverityLabel3 => 'Severe';

  @override
  String get gad7SeveritySummary0 => 'Minimal or no anxiety';

  @override
  String get gad7SeveritySummary1 => 'Mild anxiety';

  @override
  String get gad7SeveritySummary2 => 'Moderate anxiety';

  @override
  String get gad7SeveritySummary3 => 'Severe anxiety';

  @override
  String get gad7Instruction =>
      'Over the last 2 weeks, how often have you been bothered by the following problems?';

  @override
  String get gad7ShortDescription => 'Anxiety screening over the last 2 weeks';

  @override
  String get homeQuickMoodTitle => 'How are you today?';

  @override
  String get homeFabAssessment => 'Mood test';

  @override
  String get homeFabVent => 'Mood vent';

  @override
  String get homeFabHotline => 'Hotline';

  @override
  String get homeFabTop => 'Back to top';

  @override
  String get homeFabHotlineTodo => 'Hotline entry coming soon';

  @override
  String get homeFabTopTodo => 'Scroll-to-top coming soon';

  @override
  String get trendChip30Day => 'Last 30 days';

  @override
  String get assessmentChipCurrent => 'This week';

  @override
  String get crisisHotlineCnLabel =>
      'National 24-hour psychological assistance hotline';

  @override
  String get crisisHotlineCnNumber => '400-161-9995';

  @override
  String get crisisHotlineCnDesc => 'Mainland China 24h toll-free';

  @override
  String get crisisHotlineTwLabel => '1925 Mental Health Hotline (24h)';

  @override
  String get crisisHotlineTwNumber => '1925';

  @override
  String get crisisHotlineTwDesc => 'Taiwan 24h psychological counseling';

  @override
  String get crisisHotlineHkLabel => 'Samaritan Befrienders Hong Kong (24h)';

  @override
  String get crisisHotlineHkNumber => '2389 2222';

  @override
  String get crisisHotlineHkDesc => 'Hong Kong 24h multilingual';

  @override
  String get crisisHotlineMoLabel => 'Caritas Life Hotline (24h)';

  @override
  String get crisisHotlineMoNumber => '2826 1122';

  @override
  String get crisisHotlineMoDesc => 'Macau 24h';

  @override
  String get setupLegalAgeAttestation =>
      'I solemnly declare that I am at least 18 years of age. If I am between 14 and 18 years of age, I confirm that I have obtained consent from my legal guardian and accept all legal consequences of any false statement.';

  @override
  String get moodCbtLevelLabel3 => '3-column';

  @override
  String get moodCbtLevelLabel5 => '5-column';

  @override
  String get moodCbtLevelLabel7 => '7-column';

  @override
  String get moodCbtExpandExplain => 'What is a CBT thought record?';

  @override
  String get moodCbtSectionSituation => 'Situation';

  @override
  String get moodCbtSectionAutomaticThought => 'Automatic Thought';

  @override
  String get moodCbtSectionEvidenceFor => 'Evidence For';

  @override
  String get moodCbtSectionEvidenceAgainst => 'Evidence Against';

  @override
  String get moodCbtSectionAlternative => 'Alternative Thought';

  @override
  String get moodCbtSectionRerated => 'Re-rated';

  @override
  String get moodCbtSectionCoreBelief => 'Core Belief';

  @override
  String get moodCbtSectionBehavior => 'Behavioral Response';

  @override
  String get moodCbtExplainerBody =>
      'CBT (Cognitive Behavioral Therapy) thought records help you identify and reframe negative automatic thoughts.\nThe standard 5-column format: first record the situation and thoughts, then weigh evidence for/against, and write a more balanced alternative.';

  @override
  String get moodCbtFieldHintSituation =>
      'What event triggered this thought? Where, when, with whom?';

  @override
  String get moodCbtFieldHintAutomaticThought =>
      'What thought, image, or belief flashed through your mind?';

  @override
  String get moodCbtFieldHintEvidenceFor => 'What supports this thought?';

  @override
  String get moodCbtFieldHintEvidenceAgainst =>
      'What doesn\'t support this thought?';

  @override
  String get moodCbtFieldHintAlternative =>
      'If your best friend were in this situation, what would you tell them?';

  @override
  String get moodCbtFieldHintCoreBelief =>
      'What deeper belief lies behind this thought? (e.g. \"I\'m not good enough\")';

  @override
  String get moodCbtFieldHintBehavior => 'What will you do next?';

  @override
  String get moodCbtPromptTitle => 'Guiding questions';

  @override
  String moodCbtStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String moodCbtReratedComparison(int newScore, int oldScore) {
    return 'Re-rated: $newScore (was $oldScore)';
  }

  @override
  String get settingsCbtLevel => 'Thought record level';

  @override
  String get settingsCbtLevelDescription =>
      'Choose the thought record template for each mood log';

  @override
  String get settingsCbtLevel3Desc => 'Beginner, 1-2 minutes to complete';

  @override
  String get settingsCbtLevel5Desc =>
      'Standard Beck thought record with cognitive reframing';

  @override
  String get settingsCbtLevel7Desc =>
      'Deep version with core belief and behavioral response';

  @override
  String get moodCbtScoreReratedLabel => 'Re-rated score';

  @override
  String get moodCbtChipBadge5 => 'CBT 5-column';

  @override
  String get moodCbtChipBadge7 => 'CBT 7-column';

  @override
  String get moodCbtThreeScoreTitle => 'How do you feel right now?';

  @override
  String get moodCbtThreeSituationTitle => 'What happened?';

  @override
  String get moodCbtThreeAutoTitle => 'What thought flashed through your mind?';

  @override
  String get moodCbtPrevStep => 'Back';

  @override
  String get moodCbtNextStep => 'Next';

  @override
  String get moodCbtComplete => 'Done';

  @override
  String get moodCbtStep2Header => 'Emotion + Evidence';

  @override
  String get moodCbtConfirm => 'Confirm';

  @override
  String get moodCbtConfirmEmpty => '(empty)';

  @override
  String get moodCbtAutoThoughtPrompt0 =>
      'If your best friend were in this situation, what would you tell them?';

  @override
  String get moodCbtAutoThoughtPrompt1 =>
      'What\'s the worst/best/most realistic outcome?';

  @override
  String get moodCbtAutoThoughtPrompt2 =>
      'Will you still think this way a year from now?';

  @override
  String get moodCbtAlternativePrompt0 =>
      'Will you still think this way a year from now?';

  @override
  String get moodCbtAlternativePrompt1 => 'What\'s the most realistic outcome?';

  @override
  String get moodCbtBehaviorPrompt0 => 'Take 5 deep breaths';

  @override
  String get moodCbtBehaviorPrompt1 => 'Talk to someone you trust';

  @override
  String get moodCbtBehaviorPrompt2 => 'Try 10 minutes of mindfulness';

  @override
  String get moodListFilterDate => 'Date';

  @override
  String get moodListFilterScore => 'Score';

  @override
  String get moodListFilterCbt => 'CBT level';

  @override
  String get moodListSortBy => 'Sort by';

  @override
  String get moodListSortTimestamp => 'Newest first';

  @override
  String get moodListSortScoreAsc => 'Score ascending';

  @override
  String get moodListSortScoreDesc => 'Score descending';
}

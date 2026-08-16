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
  String homeLastMed(Object time) {
    return 'Last dose: $time';
  }

  @override
  String homeNextReminder(Object time) {
    return 'Next reminder: $time';
  }

  @override
  String get homeStillOnline => '🌱 You\'re still online';

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
  String get setupReminder3 =>
      '✓ 2 missed days → reminders escalate, please check in';

  @override
  String get setupPrivacy => 'Your data:';

  @override
  String get setupPrivacy1 => '• Encrypted on device';

  @override
  String get setupPrivacy2 => '• Never uploaded to any server';

  @override
  String get setupPrivacy3 => '• Exportable anytime';

  @override
  String get settingsMedication => 'Medications';

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
      'Manage all reminders: daily check-in, medication times, refills, assessment';

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
  String settingsAboutVersion(String version) {
    return 'v$version · I took my meds today';
  }

  @override
  String get settingsDisclaimerText =>
      'This app does not provide medical advice. All features are for reference only.';

  @override
  String get settingsExportRiskTitle => 'Plaintext risk warning';

  @override
  String get settingsExportRiskBody =>
      'You are about to export data as a PLAINTEXT file containing your sensitive personal information (medication, check-ins, vent text). Save it securely (encrypted USB / private cloud), never upload to public cloud or share with untrusted parties.';

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
  String settingsImportSuccess(Object summary) {
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
      'The following data will be permanently deleted:\n• Check-in history\n• Medication and dose history\n• Assessment results\n• Mood journal\n• Vent (text + audio)\n\nAfter clearing, the app returns to first-time setup. We recommend exporting a JSON backup first.';

  @override
  String get settingsClearAllDataConfirm => 'I have backed up, clear it';

  @override
  String get settingsClearAllDataSuccess => 'All data cleared';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLoading => 'Loading……';

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
  String commonLoadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String snackbarErrorTemplate(Object action, Object error) {
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
  String medsRefillSet(Object date, int days) {
    return 'Refill set: $date, remind $days days before';
  }

  @override
  String get medsActionRefill => 'Set refill';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return 'Overdue by $days days · Remind $reminderDays days before';
  }

  @override
  String medsRefillUpcoming(Object date, int days, int reminderDays) {
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
  String get notificationStatusCardPermissionDeniedTitle =>
      'Notifications are off';

  @override
  String get notificationStatusCardPermissionDeniedBody =>
      'Medication reminders can\'t be delivered. Please allow notifications in system settings, or tap the button below.';

  @override
  String get notificationStatusCardPermissionGoSettings => 'Open Settings';

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
  String get notificationStatusCardStatusLoading => 'Loading……';

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
      'Manage all reminders in one place: daily check-in, medication times, refill dates, assessment.';

  @override
  String get reminderHubDailyTitle => 'Daily Check-in Reminder';

  @override
  String get reminderHubDailyDesc =>
      'Pushes \"time to check in\" at 20:00 daily — missing once is fine';

  @override
  String get reminderHubDailyStatus => 'Enabled · Daily at 20:00';

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
  String reminderHubNDays(int days) {
    return '$days days';
  }

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
  String get ventReportTooltip => 'Report or feedback';

  @override
  String get ventReportDialogTitle => 'Private vent notice';

  @override
  String get ventReportDialogBody =>
      'Vent content is stored only on your device and is never uploaded to any server. No other user can see it.\n\nIf you find inappropriate content within the App itself or want to send feedback, please go to the \"Legal & Privacy\" page to contact the developer.';

  @override
  String get ventReportDialogAction => 'Go to Legal & Privacy';

  @override
  String get ventReportDialogClose => 'Close';

  @override
  String get ventToday => 'Today';

  @override
  String get ventYesterday => 'Yesterday';

  @override
  String get ventComposeTitle => 'Vent';

  @override
  String get ventComposeHint => 'How was your day……';

  @override
  String get ventTagSectionTitle => 'Tags';

  @override
  String get ventTagCustomHint => 'Custom tag…';

  @override
  String get ventTagFilterAll => 'All';

  @override
  String get ventTagFilterEmpty => 'No entries with this tag';

  @override
  String get ventRecordIdle => 'Tap to start recording';

  @override
  String get ventAudioLabel => 'Recording';

  @override
  String get ventAudioPlayTooltip => 'Play recording';

  @override
  String get audioRecordPauseTooltip => 'Pause recording';

  @override
  String get audioRecordResumeTooltip => 'Resume recording';

  @override
  String get audioRecordStopTooltip => 'Stop recording';

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
  String ventDurationMinutesSeconds(int m, Object sec) {
    return '${m}m ${sec}s';
  }

  @override
  String get moodDialogTitle => 'How are you today?';

  @override
  String get moodScoreSectionTitle => 'Mood Rating';

  @override
  String get moodRecordSectionTitle => 'Record Details';

  @override
  String get moodDialogPeriodLabel => 'Period';

  @override
  String get moodPeriodMorning => 'Morning';

  @override
  String get moodPeriodNoon => 'Noon';

  @override
  String get moodPeriodEvening => 'Evening';

  @override
  String get moodPeriodNight => 'Night';

  @override
  String get moodPeriodUnspecified => 'Unspecified';

  @override
  String get moodListFilterPeriod => 'Period';

  @override
  String get moodPeriodChartTitle => 'Mood 4-period trend (last 30 days)';

  @override
  String get moodDimensionMood => 'Mood';

  @override
  String get moodDimensionEnergy => 'Energy';

  @override
  String get moodDimensionSleep => 'Sleep';

  @override
  String get moodDimensionAnxiety => 'Anxiety';

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
  String get moodStatusPhraseTitle => 'Status phrase';

  @override
  String get moodStatusPhraseHint => 'Or type how you feel right now…';

  @override
  String get moodStatusPhraseShowAll => 'All';

  @override
  String get moodAudioRecordButton => 'Record voice';

  @override
  String moodAudioRecorded(Object duration) {
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
  String get moodAudioSttListening => 'Recognizing……';

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
  String get refillManageMedsList => 'Medication List';

  @override
  String get refillManageSummary => 'Refill Summary';

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
      Object date, Object suffix, int reminderDays) {
    return '$date $suffix · Remind $reminderDays days before';
  }

  @override
  String get assessmentLoadingBack => 'Returning……';

  @override
  String assessmentAnsweredProgress(int answered, int total) {
    return 'Answered $answered / $total';
  }

  @override
  String get assessmentSubmit => 'Submit & View Results';

  @override
  String assessmentQuestionLabel(int index, Object text, Object selected) {
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
  String homeHeaderKeepGoing(Object name) {
    return '$name is still going strong';
  }

  @override
  String get ventSwipeHint => 'Swipe left or long-press to delete';

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
  String get navMood => 'Mood';

  @override
  String get navVent => 'Vent';

  @override
  String get navTrend => 'Trends';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAppName => 'Chronic Care';

  @override
  String errorPageNotFound(Object path) {
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
  String assessmentAverageScore(Object score) {
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
  String get setupPresetTitle => '📋 Choose a Preset';

  @override
  String get setupPresetDescription =>
      'Presets fill in medication names + times. You can modify them. Always follow your doctor\'s instructions.';

  @override
  String setupPresetLoaded(Object name, int count) {
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
  String get reportHistoryEmpty =>
      'No report history yet\nReports will be recorded automatically after generation';

  @override
  String reportHistoryItemTitle(Object date, int days) {
    return '$date · Last $days days';
  }

  @override
  String reportHistoryItemPatient(Object name) {
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
  String homeAutofireCelebration(Object name) {
    return 'Checked in: $name ✅';
  }

  @override
  String get homeAutofireFallbackName => 'this med';

  @override
  String homeMedHint(String name) {
    return '💊 Ready to check in medication $name';
  }

  @override
  String get homeSnoozeTitle => '⏰ Time to check in (in 5 min)';

  @override
  String get notifChannelMedicationName => 'Medication reminder';

  @override
  String get notifChannelMedicationDesc =>
      'Reminds you to check in when it\'s time';

  @override
  String get homeNotifBannerText =>
      'Reminders not set — you may miss check-ins. Please enable notifications in system settings.';

  @override
  String get homeNotifBannerDismiss => 'Got it';

  @override
  String themeTooltip(Object mode) {
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
  String trendMoodEntriesSame(int count, Object emoji) {
    return '$count mood entries · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, Object lowEmoji, Object highEmoji) {
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
  String get contactConsentReject => 'Decline for now';

  @override
  String get dataExportConsentTitle => 'Data Export Consent';

  @override
  String dataExportConsentBody(
      Object purpose, Object dataCategories, Object retention) {
    return 'You are about to export all data from the local database.\n\n**Purpose**: $purpose\n**Data scope**: $dataCategories\n**Retention**: $retention\n\n**Per PIPL Article 13** (data portability + standalone consent), please confirm you understand the above purpose and consent to this export.';
  }

  @override
  String get dataExportConsentConfirm => 'I understand and consent to export';

  @override
  String get dataExportConsentVersion => 'v1 · 2026-08-15';

  @override
  String get consentDialogGenericTitle => 'Informed Consent';

  @override
  String get consentDialogGenericAgree => 'I understand and consent';

  @override
  String get consentDialogGenericReject => 'Decline for now';

  @override
  String get consentDialogGenericVersion => 'v1 · 2026-08-15';

  @override
  String get editMedDialogTitle => 'Edit Medication';

  @override
  String get editMedValidationNameRequired => 'Please enter medication name';

  @override
  String get editMedValidationDosageInvalid => 'Dosage must be greater than 0';

  @override
  String get editMedValidationUnitInvalid => 'Unit must be mg or tablet';

  @override
  String editMedSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get editMedStatusActive => 'In use';

  @override
  String get editMedStatusStopped => 'Stopped';

  @override
  String editMedStoppedDate(Object date) {
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
  String get medReportPdfLoading => 'Generating PDF……';

  @override
  String get medReportShareSubject => 'Chronic Care · Medication Report';

  @override
  String get tempMedNoLink => 'No link';

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
  String get medsCalendarWindowTitle => 'Time Window';

  @override
  String medsCalendarLoadCheckinFailed(Object error) {
    return 'Failed to load check-ins: $error';
  }

  @override
  String medsCalendarLoadMedFailed(Object error) {
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
  String get medsCalendarLegendTitle => 'Legend';

  @override
  String get medsCalendarLegendMissed => 'Missed';

  @override
  String medsCalendarDayDetailTitle(String date) {
    return 'Check-ins on $date';
  }

  @override
  String get medsCalendarDayDetailEmpty => 'No check-ins yet on this day';

  @override
  String get medCalendarBackfillConfirm => 'Confirm';

  @override
  String medCalendarBackfillSuccess(Object date) {
    return 'Check-in added for $date';
  }

  @override
  String get medsCalendarDayDetailAddLog => 'Add check-in';

  @override
  String get medsCalendarDayDetailAddLogHint => 'Add a missing dose for today';

  @override
  String medsCalendarDayDetailLogItem(String time, String name) {
    return '$time · $name';
  }

  @override
  String get medsCalendarLegendPartial => '< 50%';

  @override
  String get medsCalendarLegendAlmost => '< 100%';

  @override
  String get medsCalendarLegendFull => '100%';

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
  String get snackbarActionCheckin => 'Check-in';

  @override
  String get snackbarActionAutoCheckin => 'Auto check-in';

  @override
  String get snackbarActionFinishSetup => 'Finish setup';

  @override
  String get snackbarActionUndo => 'Undo';

  @override
  String get ventEntryDeleted => 'Vent entry deleted';

  @override
  String get medicationDeleted => 'Medication deleted';

  @override
  String get moodLabel1 => 'Very bad';

  @override
  String get moodLabel2 => 'Bad';

  @override
  String get moodLabel3 => 'Fair';

  @override
  String get moodLabel4 => 'Good';

  @override
  String get moodLabel5 => 'Very good';

  @override
  String medReportFileName(Object date) {
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
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => 'tablet';

  @override
  String get safetyCheckResultDisabled => 'Safety watch is disabled';

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
  String dayDetailCheckInWith(Object name) {
    return 'Check-in · $name';
  }

  @override
  String get dayDetailDailyCheckIn => 'Daily check-in';

  @override
  String dayDetailTempWith(Object name) {
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
  String get homeFabVent => 'Mood vent';

  @override
  String get homeMoodHeroTitle => 'Today\'s Mood';

  @override
  String get homeMoodHeroRecord => 'Log mood';

  @override
  String get homeMoodHeroReview => 'Review';

  @override
  String get homeMoodHeroViewAll => 'View all';

  @override
  String get homeMoodHeroNoData => 'No mood logged yet today';

  @override
  String homeMoodHeroLastRecorded(String time) {
    return 'Last logged $time';
  }

  @override
  String get homeVentHeroTitle => 'Vent';

  @override
  String get homeVentHeroWrite => 'Write';

  @override
  String get homeVentHeroNoData =>
      'Nothing here yet. Write your first thought.';

  @override
  String get homeActionMedication => 'Meds';

  @override
  String get homeActionAssessment => 'Scales';

  @override
  String get homeActionMoodReview => 'Mood review';

  @override
  String get homeActionDailyTracking => 'Daily tracking';

  @override
  String get homeFabHotline => 'Hotline';

  @override
  String get homeFabTop => 'Back to top';

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
  String get crisisHotlineTitle => 'Crisis & Mental Health Hotlines';

  @override
  String get crisisHotlineSubtitle =>
      'If you or someone you know is in crisis, please call one of the hotlines below';

  @override
  String get crisisHotlineCn2Label =>
      'China National 24h Toll-free Mental Health Hotline';

  @override
  String get crisisHotlineCn2Number => '800-810-1117';

  @override
  String get crisisHotlineCn2Desc => 'Mainland China 24h toll-free';

  @override
  String get crisisHotlineUsLabel => '988 Suicide & Crisis Lifeline';

  @override
  String get crisisHotlineUsNumber => '988';

  @override
  String get crisisHotlineUsDesc => 'US/Canada 24h English/Spanish';

  @override
  String get crisisHotlineIntlLabel => 'International';

  @override
  String get crisisHotlineIntlDesc =>
      'Please contact local emergency services or mental health organization';

  @override
  String get crisisHotlineIntlNumber => '112 / 911';

  @override
  String get crisisHotlineRegionCn => 'Mainland China';

  @override
  String get crisisHotlineRegionTw => 'Taiwan';

  @override
  String get crisisHotlineRegionHk => 'Hong Kong';

  @override
  String get crisisHotlineRegionUs => 'USA / Canada';

  @override
  String get crisisHotlineRegionIntl => 'International';

  @override
  String get crisisHotlineCnBeijingLabel =>
      'Beijing Suicide Research & Prevention Center';

  @override
  String get crisisHotlineCnBeijingNumber => '010-82951332';

  @override
  String get crisisHotlineCnBeijingDesc => 'Beijing 24h';

  @override
  String get crisisHotlineTw1995Label => 'Taiwan Lifeline (24h)';

  @override
  String get crisisHotlineTw1995Number => '1995';

  @override
  String get crisisHotlineTw1995Desc => 'Taiwan 24h';

  @override
  String get crisisHotlineUsTextLineLabel => 'Crisis Text Line (text HOME)';

  @override
  String get crisisHotlineUsTextLineNumber => '741741';

  @override
  String get crisisHotlineUsTextLineDesc => 'US 24h text';

  @override
  String crisisHotlineSnackbarCopied(Object number) {
    return 'Copied: $number';
  }

  @override
  String get crisisHotlineDialTooltip => 'Dial';

  @override
  String get crisisHotlineCopyTooltip => 'Copy number';

  @override
  String crisisHotlineDialFailed(Object number) {
    return 'Unable to launch dialer, please call manually: $number';
  }

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

  @override
  String get moodListPageTitle => 'Mood history';

  @override
  String get moodListSearchHint => 'Search note……';

  @override
  String get moodListEmpty => 'No mood entries yet';

  @override
  String get moodListNoMatch => 'No matching entries';

  @override
  String moodListEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get moodReviewTitle => 'Mood review';

  @override
  String get moodReviewWeek => 'Week';

  @override
  String get moodReviewMonth => 'Month';

  @override
  String get moodReviewEntriesCount => 'Days recorded';

  @override
  String get moodReviewAvgScore => 'Avg. mood';

  @override
  String get moodReviewDelta => 'Change vs. previous';

  @override
  String get moodReviewDeltaNoData => 'No previous data';

  @override
  String get moodReviewTopTags => 'Top tags';

  @override
  String get moodReviewTopFactors => 'Top factors';

  @override
  String get moodReviewPeriod => 'Time of day';

  @override
  String get moodReviewCbtCount => 'CBT entries';

  @override
  String get moodReviewViewTrend => 'View trend chart';

  @override
  String get cbtExportPdfEmpty => 'No 5/7-column CBT data available to export';

  @override
  String get cbtExportPdfButton => 'Export CBT thought record PDF';

  @override
  String get cbtExportPdfDialogTitle => 'Pick a date range to generate the PDF';

  @override
  String cbtExportPdfSuccess(int count) {
    return 'Exported $count CBT thought record(s)';
  }

  @override
  String get cbtExportPdfFailed => 'PDF export failed, please try again';

  @override
  String get assessmentCenterTitle => 'Assessment Center';

  @override
  String assessmentCenterLastScore(int score) {
    return 'Last score: $score';
  }

  @override
  String assessmentCenterLastTime(Object time) {
    return 'Taken on $time';
  }

  @override
  String get assessmentCenterNoData => 'No entries yet';

  @override
  String get assessmentCenterStartButton => 'Start assessment';

  @override
  String get assessmentCenterMultiLineTitle => 'All scales trend';

  @override
  String get assessmentCenterNotAvailable => 'Pending legal/clinical review';

  @override
  String get assessmentCenterComingSoon => 'Coming soon';

  @override
  String get isiName => 'ISI Insomnia Severity Index';

  @override
  String get isiShortDescription =>
      'Morin 1993 Insomnia Severity Index (7 items)';

  @override
  String get isiInstruction =>
      'Over the past 2 weeks, how severe has your sleep problem been?';

  @override
  String get isiOption0 => 'None';

  @override
  String get isiOption1 => 'Mild';

  @override
  String get isiOption2 => 'Moderate';

  @override
  String get isiOption3 => 'Severe';

  @override
  String get isiOption4 => 'Very severe';

  @override
  String get isiSeverityLabel0 => 'No insomnia';

  @override
  String get isiSeverityLabel1 => 'Subthreshold insomnia';

  @override
  String get isiSeverityLabel2 => 'Moderate insomnia';

  @override
  String get isiSeverityLabel3 => 'Severe insomnia';

  @override
  String get isiSeveritySummary0 => 'No clinical insomnia';

  @override
  String get isiSeveritySummary1 => 'Subclinical insomnia, consider monitoring';

  @override
  String get isiSeveritySummary2 =>
      'Moderate insomnia, consider seeing a doctor';

  @override
  String get isiSeveritySummary3 =>
      'Severe insomnia, strongly consider seeing a doctor';

  @override
  String get pssName => 'PSS Perceived Stress Scale';

  @override
  String get pssShortDescription =>
      'Cohen 1983 Perceived Stress Scale (10 items, 4 reverse-scored)';

  @override
  String get pssInstruction =>
      'In the last month, how often have you felt the following?';

  @override
  String get pssOption0 => 'Never';

  @override
  String get pssOption1 => 'Almost never';

  @override
  String get pssOption2 => 'Sometimes';

  @override
  String get pssOption3 => 'Fairly often';

  @override
  String get pssOption4 => 'Very often';

  @override
  String get pssSeverityLabel0 => 'Low stress';

  @override
  String get pssSeverityLabel1 => 'Moderate stress';

  @override
  String get pssSeverityLabel2 => 'High stress';

  @override
  String get pssSeveritySummary0 => 'Low stress';

  @override
  String get pssSeveritySummary1 => 'Moderate stress';

  @override
  String get pssSeveritySummary2 =>
      'High stress, consider monitoring and seeking support';

  @override
  String get whodasName => 'WHODAS 2.0 Disability Assessment';

  @override
  String get whodasShortDescription =>
      'WHO generic disability assessment, 12-item short version';

  @override
  String get whodasInstruction =>
      'Over the past 30 days, how much difficulty did you have in the following activities?';

  @override
  String get whodasOption0 => 'None';

  @override
  String get whodasOption1 => 'Mild';

  @override
  String get whodasOption2 => 'Moderate';

  @override
  String get whodasOption3 => 'Severe';

  @override
  String get whodasOption4 => 'Extreme';

  @override
  String get whodasSeverityLabel0 => 'No disability';

  @override
  String get whodasSeverityLabel1 => 'Mild disability';

  @override
  String get whodasSeverityLabel2 => 'Moderate disability';

  @override
  String get whodasSeverityLabel3 => 'Severe disability';

  @override
  String get whodasSeverityLabel4 => 'Extreme disability';

  @override
  String get whodasSeveritySummary0 => 'No disability';

  @override
  String get whodasSeveritySummary1 => 'Mild disability';

  @override
  String get whodasSeveritySummary2 =>
      'Moderate disability, consider medical evaluation';

  @override
  String get whodasSeveritySummary3 =>
      'Severe disability, consider seeing a doctor';

  @override
  String get whodasSeveritySummary4 =>
      'Extreme disability, strongly consider seeing a doctor';

  @override
  String get level2DepressionName => 'DSM-5 Level 2 Depression Severity';

  @override
  String get level2DepressionShortDescription =>
      'Adult depression severity, 8 items (DSM-5 PROMIS short)';

  @override
  String get level2DepressionInstruction =>
      'Over the past 7 days, how often were you bothered by the following feelings?';

  @override
  String get level2DepressionOption0 => 'Never';

  @override
  String get level2DepressionOption1 => 'Several days';

  @override
  String get level2DepressionOption2 => 'More than half the days';

  @override
  String get level2DepressionOption3 => 'Nearly every day';

  @override
  String get level2DepressionSeverityLabel0 => 'No depression';

  @override
  String get level2DepressionSeverityLabel1 => 'Mild depression';

  @override
  String get level2DepressionSeverityLabel2 => 'Moderate depression';

  @override
  String get level2DepressionSeverityLabel3 => 'Severe depression';

  @override
  String get level2DepressionSeveritySummary0 => 'No depression tendency';

  @override
  String get level2DepressionSeveritySummary1 => 'Mild depression tendency';

  @override
  String get level2DepressionSeveritySummary2 =>
      'Moderate depression, consider seeing a doctor';

  @override
  String get level2DepressionSeveritySummary3 =>
      'Severe depression, strongly consider seeing a doctor';

  @override
  String get level2AnxietyName => 'DSM-5 Level 2 Anxiety Severity';

  @override
  String get level2AnxietyShortDescription =>
      'Adult anxiety severity, 7 items (DSM-5 PROMIS short)';

  @override
  String get level2AnxietyInstruction =>
      'Over the past 7 days, how often were you bothered by the following feelings?';

  @override
  String get level2AnxietyOption0 => 'Never';

  @override
  String get level2AnxietyOption1 => 'Several days';

  @override
  String get level2AnxietyOption2 => 'More than half the days';

  @override
  String get level2AnxietyOption3 => 'Nearly every day';

  @override
  String get level2AnxietySeverityLabel0 => 'No anxiety';

  @override
  String get level2AnxietySeverityLabel1 => 'Mild anxiety';

  @override
  String get level2AnxietySeverityLabel2 => 'Moderate anxiety';

  @override
  String get level2AnxietySeverityLabel3 => 'Severe anxiety';

  @override
  String get level2AnxietySeveritySummary0 => 'No anxiety tendency';

  @override
  String get level2AnxietySeveritySummary1 => 'Mild anxiety tendency';

  @override
  String get level2AnxietySeveritySummary2 =>
      'Moderate anxiety, consider seeing a doctor';

  @override
  String get level2AnxietySeveritySummary3 =>
      'Severe anxiety, strongly consider seeing a doctor';

  @override
  String get level2ManiaName => 'DSM-5 Level 2 Mania Severity';

  @override
  String get level2ManiaShortDescription =>
      'Adult mania severity, 5 items (DSM-5 PROMIS short)';

  @override
  String get level2ManiaInstruction =>
      'Over the past 7 days, how often did you experience the following?';

  @override
  String get level2ManiaOption0 => 'Never';

  @override
  String get level2ManiaOption1 => 'Several days';

  @override
  String get level2ManiaOption2 => 'More than half the days';

  @override
  String get level2ManiaOption3 => 'Nearly every day';

  @override
  String get level2ManiaSeverityLabel0 => 'No mania';

  @override
  String get level2ManiaSeverityLabel1 => 'Mild mania';

  @override
  String get level2ManiaSeverityLabel2 => 'Moderate mania';

  @override
  String get level2ManiaSeverityLabel3 => 'Severe mania';

  @override
  String get level2ManiaSeveritySummary0 => 'No mania tendency';

  @override
  String get level2ManiaSeveritySummary1 => 'Mild mania tendency';

  @override
  String get level2ManiaSeveritySummary2 =>
      'Moderate mania, consider seeing a doctor';

  @override
  String get level2ManiaSeveritySummary3 =>
      'Severe mania, strongly consider seeing a doctor';

  @override
  String get asrmName => 'ASRM Altman Self-Rating Mania Scale';

  @override
  String get asrmShortDescription =>
      'Altman 1997 Self-Rating Mania Scale (5 items)';

  @override
  String get asrmInstruction =>
      'Over the past week, to what extent have you experienced (or felt) the following?';

  @override
  String get asrmOption0 => 'Not at all';

  @override
  String get asrmOption1 => 'Mild';

  @override
  String get asrmOption2 => 'Moderate';

  @override
  String get asrmOption3 => 'Marked';

  @override
  String get asrmOption4 => 'Severe';

  @override
  String get asrmSeverityLabel0 => 'No symptoms';

  @override
  String get asrmSeverityLabel1 => 'Mild';

  @override
  String get asrmSeverityLabel2 => 'Moderate';

  @override
  String get asrmSeverityLabel3 => 'Severe';

  @override
  String get asrmSeverityLabel4 => 'Extreme';

  @override
  String get asrmSeveritySummary0 => 'No symptoms';

  @override
  String get asrmSeveritySummary1 => 'Mild mania tendency';

  @override
  String get asrmSeveritySummary2 => 'Moderate mania, consider seeing a doctor';

  @override
  String get asrmSeveritySummary3 => 'Severe mania, consider seeing a doctor';

  @override
  String get asrmSeveritySummary4 =>
      'Extreme mania, strongly consider seeing a doctor';

  @override
  String get level2PsychosisName => 'DSM-5 Level 2 Psychotic Symptoms';

  @override
  String get level2PsychosisShortDescription =>
      'Adult psychotic symptoms, 8 items (DSM-5 short)';

  @override
  String get level2PsychosisInstruction =>
      'Over the past 7 days, how often did you experience the following?';

  @override
  String get level2PsychosisOption0 => 'Never';

  @override
  String get level2PsychosisOption1 => 'Rarely';

  @override
  String get level2PsychosisOption2 => 'Sometimes';

  @override
  String get level2PsychosisOption3 => 'Often';

  @override
  String get level2PsychosisSeverityLabel0 => 'No symptoms';

  @override
  String get level2PsychosisSeverityLabel1 => 'Mild';

  @override
  String get level2PsychosisSeverityLabel2 => 'Moderate';

  @override
  String get level2PsychosisSeverityLabel3 => 'Severe';

  @override
  String get level2PsychosisSeveritySummary0 => 'No psychotic symptoms';

  @override
  String get level2PsychosisSeveritySummary1 => 'Mild psychotic symptoms';

  @override
  String get level2PsychosisSeveritySummary2 =>
      'Moderate psychotic symptoms, consider seeing a doctor';

  @override
  String get level2PsychosisSeveritySummary3 =>
      'Severe psychotic symptoms, strongly consider seeing a doctor';

  @override
  String get dailyTrackingTitle => 'Daily Tracking';

  @override
  String get dailyTrackingFab => 'Daily Tracking';

  @override
  String get dailyTrackingMultiChartTitle => 'Last 30 days, 4 metrics';

  @override
  String get chartMetricWeight => 'Weight';

  @override
  String get chartMetricSleep => 'Sleep';

  @override
  String get chartMetricMood => 'Mood';

  @override
  String get chartMetricStress => 'Stress';

  @override
  String dailyTrackingLastTime(Object time) {
    return '$time record';
  }

  @override
  String get dailyTrackingRecord => 'Record';

  @override
  String get moodDiaryName => 'Mood Diary';

  @override
  String get moodDiaryShortDesc => 'Mood by 4 periods + score, trend analysis';

  @override
  String moodDiaryScore(int score) {
    return 'Mood $score/5';
  }

  @override
  String moodDiaryLast(Object time, Object score, Object period) {
    return '$time · $score ($period)';
  }

  @override
  String get anxietyAgitationName => 'Anxiety & Agitation';

  @override
  String get anxietyAgitationShortDesc =>
      'Anxiety + agitation 2-dim, 5-point scale';

  @override
  String get anxietyAgitationHint =>
      'Anxiety reverse 1=severe 5=calm; agitation forward 1=calm 5=extreme';

  @override
  String get anxietyAgitationAddButton => 'Add assessment';

  @override
  String get anxietyAgitationNoData => 'No anxiety/agitation entries yet';

  @override
  String anxietyAgitationAnxietyScore(int score) {
    return 'Anxiety $score';
  }

  @override
  String anxietyAgitationAgitationScore(int score) {
    return 'Agitation $score';
  }

  @override
  String anxietyAgitationLast(int anxiety, int agitation) {
    return 'Anxiety $anxiety / Agitation $agitation';
  }

  @override
  String get sleepName => 'Sleep';

  @override
  String get sleepShortDesc => 'Bedtime + duration + regularity';

  @override
  String get sleepHint =>
      'Record nightly bedtime + wake, auto cross-midnight duration';

  @override
  String get sleepAddButton => 'Add sleep entry';

  @override
  String get sleepNoData => 'No sleep entries yet';

  @override
  String sleepBedtime(Object time) {
    return 'Bedtime $time';
  }

  @override
  String sleepWakeTime(Object time) {
    return 'Wake $time';
  }

  @override
  String sleepLast(Object duration, int regularity) {
    return '$duration · regularity $regularity/5';
  }

  @override
  String get socialRhythmName => 'Social Rhythm';

  @override
  String get socialRhythmShortDesc =>
      'Wake + first meal + last meal + durations';

  @override
  String get socialRhythmHint =>
      'Record daily routines, helps doctors judge rhythm stability';

  @override
  String get socialRhythmAddButton => 'Add social rhythm';

  @override
  String get socialRhythmNoData => 'No social rhythm entries yet';

  @override
  String socialRhythmWakeTime(Object time) {
    return 'Wake $time';
  }

  @override
  String socialRhythmFirstMeal(Object time) {
    return 'First meal $time';
  }

  @override
  String socialRhythmLastMeal(Object time) {
    return 'Last meal $time';
  }

  @override
  String socialRhythmLast(Object wake, int social, int work) {
    return 'Wake $wake · social ${social}h · work ${work}h';
  }

  @override
  String get stressEventName => 'Stress Events';

  @override
  String get stressEventShortDesc => 'Event type + intensity score';

  @override
  String get stressEventHint =>
      'Record stressful life events, helps doctors identify triggers';

  @override
  String get stressEventAddButton => 'Add stress event';

  @override
  String get stressEventNoData => 'No stress events yet';

  @override
  String get stressEventEventType => 'Event type';

  @override
  String get stressEventIntensity => 'Intensity';

  @override
  String stressEventLast(int intensity) {
    return 'Intensity $intensity/5';
  }

  @override
  String get treatmentName => 'Treatment';

  @override
  String get treatmentShortDesc =>
      'Medication / consultation / physiotherapy, link to meds';

  @override
  String get treatmentHint =>
      'Treatment entries can link to medication, write UI v0.31+';

  @override
  String get treatmentNoData => 'No treatment entries yet';

  @override
  String get treatmentAddButton => 'Add';

  @override
  String get treatmentAddTitle => 'Add Treatment Record';

  @override
  String get treatmentDate => 'Date';

  @override
  String get treatmentCategory => 'Category';

  @override
  String get treatmentCategoryMedicationAdjustment => 'Medication adjustment';

  @override
  String get treatmentCategoryConsultation => 'Consultation';

  @override
  String get treatmentCategoryHospitalization => 'Hospitalization';

  @override
  String get treatmentCategoryOther => 'Other';

  @override
  String get treatmentProvider => 'Provider / Doctor';

  @override
  String get treatmentProviderHint => 'e.g. Dr. Smith / Mayo Clinic';

  @override
  String get treatmentProviderRequired => 'Please enter provider / doctor';

  @override
  String get treatmentNote => 'Note';

  @override
  String get treatmentNoteHint => 'Optional, brief summary';

  @override
  String get treatmentType => 'Treatment type';

  @override
  String treatmentLast(Object type, Object description) {
    return '$type · $description';
  }

  @override
  String get weightName => 'Weight';

  @override
  String get weightShortDesc => 'Weight + BMI (requires profile.height)';

  @override
  String get weightHint =>
      'Record daily weight, helps doctors judge physical state';

  @override
  String get weightAddButton => 'Add weight entry';

  @override
  String get weightNoData => 'No weight entries yet';

  @override
  String weightWeight(Object kg) {
    return 'Weight $kg kg';
  }

  @override
  String weightBmi(Object bmi) {
    return 'BMI $bmi';
  }

  @override
  String weightLast(Object kg, Object bmi) {
    return '$kg kg · BMI $bmi';
  }

  @override
  String get periodMorning => 'AM';

  @override
  String get periodNoon => 'Noon';

  @override
  String get periodEvening => 'PM';

  @override
  String get periodNight => 'Night';

  @override
  String get periodUnspecified => 'Unspecified';

  @override
  String get stressEventTypeWork => 'Work';

  @override
  String get stressEventTypeRelationship => 'Relationship';

  @override
  String get stressEventTypeHealth => 'Health';

  @override
  String get stressEventTypeFinancial => 'Financial';

  @override
  String get stressEventTypeOther => 'Other';

  @override
  String get regularityVeryIrregular => 'Very irregular';

  @override
  String get regularityIrregular => 'Irregular';

  @override
  String get regularityNormal => 'Average';

  @override
  String get regularityRegular => 'Regular';

  @override
  String get regularityVeryRegular => 'Very regular';

  @override
  String get cardStatusNoData => 'No entries yet';

  @override
  String get sleepBedtimeTitle => 'Bedtime';

  @override
  String get sleepWakeTimeTitle => 'Wake time';

  @override
  String get socialRhythmWakeTimeTitle => 'Wake time';

  @override
  String get socialRhythmFirstMealTitle => 'First meal time';

  @override
  String get socialRhythmLastMealTitle => 'Last meal time';

  @override
  String get cardStatusToday => 'Today';

  @override
  String get sleepRegularityTitle => 'Regularity';

  @override
  String get anxietyAgitationAnxietyLabel => 'Anxiety Score';

  @override
  String get anxietyAgitationAgitationLabel => 'Agitation Score';

  @override
  String get moodListPeriodAll => 'All';

  @override
  String get migrationFailedInitData => 'Unable to initialize local data';

  @override
  String get migrationFailedActionHint =>
      'Try restarting the app, or uninstall and reinstall';

  @override
  String migrationFailedFooter(String error) {
    return 'Technical info: $error';
  }

  @override
  String get migrationFailedRetryButton => 'Retry';

  @override
  String get migrationFailedCloseButton => 'Close';

  @override
  String get migrationStartingHint => 'Starting up, please wait……';

  @override
  String get migrationNavContextNull =>
      'Startup context not ready, please try again later';

  @override
  String get migrationFailedErrorPrefix => 'Error';

  @override
  String get dailyTrackingNoteLabel => 'Note';

  @override
  String get dailyTrackingNoteHint => 'Optional';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String timeAgoHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String get weightNoBmi => 'No BMI';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get weightKgHint => 'e.g. 60.5';

  @override
  String get weightBmiNeedHeight => 'N/A (height required)';

  @override
  String socialRhythmMinutesSummary(
      Object social, Object work, Object exercise) {
    return 'Social ${social}min · Work ${work}min · Exercise ${exercise}min';
  }

  @override
  String get socialRhythmSocialMinLabel => 'Social time (minutes)';

  @override
  String get socialRhythmWorkMinLabel => 'Work time (minutes)';

  @override
  String get socialRhythmExerciseMinLabel => 'Exercise time (minutes)';

  @override
  String get anxietyAgitationAnxietyScaleHint => '1=severe 5=calm';

  @override
  String get anxietyAgitationAgitationScaleHint => '1=calm 5=very agitated';

  @override
  String sleepRegularityScore(int score) {
    return 'Regularity $score/5';
  }

  @override
  String sleepDurationLabel(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String stressIntensityScore(int intensity) {
    return 'Intensity $intensity/5';
  }

  @override
  String moodCbtColumns(int count) {
    return '$count columns';
  }

  @override
  String medReportTitleWindow(int days) {
    return 'Medication Report (last $days days)';
  }

  @override
  String get setupCrisisHotlineTitle => '🆘 Crisis Intervention Hotline (24h)';

  @override
  String get consentWithdrawVentBody =>
      'Vent (private journal) will be disabled. New vent entries will be rejected; existing entries are kept.';

  @override
  String get consentWithdrawAnalyticsBody =>
      'Assessment / mood analytics charts will no longer be shown. Existing data is kept and restored when re-enabled.';

  @override
  String get dataExportPurposeBackup => 'Local backup / cross-device migration';

  @override
  String get dataExportDataCategories =>
      'Medication records, check-ins, mood diary, vent text (audio not exported)';

  @override
  String get dataExportRetentionClipboard =>
      'Clipboard + user saves to encrypted storage themselves';

  @override
  String get medPageTitle => 'Medications';

  @override
  String get medAddTooltip => 'Add medication';

  @override
  String get medTodaySchedule => 'Today\'s Schedule';

  @override
  String get medMyMedications => 'My Medications';

  @override
  String get medQuickActions => 'Quick Actions';

  @override
  String get medSlotMorning => 'Morning';

  @override
  String get medSlotAfternoon => 'Afternoon';

  @override
  String get medSlotEvening => 'Evening';

  @override
  String get medSlotBedtime => 'Bedtime';

  @override
  String get medEmptyTitle => 'No medications yet';

  @override
  String get medEmptySubtitle => 'Tap + to add your first medication';

  @override
  String get medNoScheduleToday => 'No medications scheduled today';

  @override
  String get medAddTitle => 'Add Medication';

  @override
  String get medAddStep1Title => 'Medication Info';

  @override
  String get medAddConfirm => 'Confirm';

  @override
  String get medAddColor => 'Color';

  @override
  String get medAddTime => 'Medication Times';

  @override
  String get medAddBasicInfo => 'Basic Info';

  @override
  String get medAddStep2Title => 'Dosage & Schedule';

  @override
  String get medAddStep3Title => 'Confirm';

  @override
  String get medAddNameLabel => 'Medication name';

  @override
  String get medAddNameHint => 'e.g., Sertraline';

  @override
  String get medAddFormLabel => 'Form';

  @override
  String get medAddDosageLabel => 'Dose per time';

  @override
  String get medAddTimeLabel => 'Schedule';

  @override
  String get medAddTimeAdd => 'Add time';

  @override
  String get medAddColorLabel => 'Color (optional, for visual ID)';

  @override
  String get medAddConfirmName => 'Name';

  @override
  String get medAddConfirmForm => 'Form';

  @override
  String get medAddConfirmDosage => 'Dosage';

  @override
  String get medAddConfirmTime => 'Time';

  @override
  String get medAddPrev => 'Back';

  @override
  String get medAddNext => 'Next';

  @override
  String get medAddSave => 'Save';

  @override
  String medAddColorN(Object n) {
    return 'Medication color $n';
  }

  @override
  String get medFormTablet => 'Tablet';

  @override
  String get medFormCapsule => 'Capsule';

  @override
  String get medFormLiquid => 'Liquid';

  @override
  String get medFormPatch => 'Patch';

  @override
  String get medFormInjection => 'Injection';

  @override
  String get medFormOther => 'Other';

  @override
  String get medDetailTitle => 'Medication Detail';

  @override
  String get medNotFound => 'Medication not found';

  @override
  String get moodInfluenceTitle => 'Influence Factors';

  @override
  String get moodInfluenceSubtitle =>
      'What influenced your mood? (select multiple)';

  @override
  String get moodInfluenceRelationships => 'Relationships';

  @override
  String get moodInfluenceHealth => 'Health';

  @override
  String get moodInfluenceActivities => 'Activities';

  @override
  String get moodInfluenceMindfulness => 'Mindfulness';

  @override
  String get moodInfluenceWeather => 'Weather';

  @override
  String get moodInfluenceOther => 'Other';

  @override
  String get influenceFactorFamily => 'Family';

  @override
  String get influenceFactorFriend => 'Friends';

  @override
  String get influenceFactorPartner => 'Partner';

  @override
  String get influenceFactorChild => 'Children';

  @override
  String get influenceFactorColleague => 'Colleagues';

  @override
  String get influenceFactorExercise => 'Exercise';

  @override
  String get influenceFactorSick => 'Illness';

  @override
  String get influenceFactorGoodSleep => 'Good sleep';

  @override
  String get influenceFactorHealthyDiet => 'Healthy diet';

  @override
  String get influenceFactorWork => 'Work';

  @override
  String get influenceFactorHobby => 'Hobby';

  @override
  String get influenceFactorTravel => 'Travel';

  @override
  String get influenceFactorCommute => 'Commute';

  @override
  String get influenceFactorShopping => 'Shopping';

  @override
  String get influenceFactorGaming => 'Gaming';

  @override
  String get influenceFactorReading => 'Reading';

  @override
  String get influenceFactorEntertainment => 'Entertainment';

  @override
  String get influenceFactorMeditation => 'Meditation';

  @override
  String get influenceFactorBreathing => 'Breathing exercises';

  @override
  String get influenceFactorJournaling => 'Journaling';

  @override
  String get influenceFactorYoga => 'Yoga';

  @override
  String get influenceFactorSunny => 'Sunny';

  @override
  String get influenceFactorCloudy => 'Cloudy';

  @override
  String get influenceFactorRainy => 'Rainy';

  @override
  String get influenceFactorSnowy => 'Snowy';

  @override
  String get influenceFactorWindy => 'Windy';

  @override
  String get moodDetailTitle => 'Mood Detail';

  @override
  String get moodDetailFactors => 'Influence Factors';

  @override
  String get moodDetailMoodState => 'Mood State';

  @override
  String get moodDetailCbtRecord => 'CBT Thought Record';

  @override
  String get moodEntryNotFound => 'Mood entry not found';

  @override
  String get moodTrendTitle => 'Mood Trends';

  @override
  String get moodTrendWeek => 'Last 7 Days';

  @override
  String get moodTrendDistribution => 'Score Distribution';

  @override
  String get moodTrendNoData => 'No data yet';

  @override
  String get moodDeleteTooltip => 'Delete';

  @override
  String get moodDeleteConfirm =>
      'Are you sure you want to delete this record?';

  @override
  String get moodFactorAnalysis => 'Factor Analysis';

  @override
  String get moodModeMomentary => 'Right Now';

  @override
  String get moodModeDaily => 'Overall Today';

  @override
  String get moodTrendDistTitle => 'Score Distribution';

  @override
  String get moodTrendCbtTitle => 'CBT Re-rating Effect';

  @override
  String get moodTrendCbtHint => 'Positive = improved, Negative = worse';

  @override
  String get moodTrendCbtEmpty => 'No CBT re-rating data yet';

  @override
  String moodTrendSemanticsLine(Object days) {
    return 'Mood trend line chart, last $days days';
  }

  @override
  String moodTrendSemanticsDist(Object count, Object score) {
    return 'Mood score distribution chart, most common $score out of 5, $count records';
  }

  @override
  String moodTrendSemanticsCbt(Object count) {
    return 'CBT re-rating chart, $count re-rating records';
  }

  @override
  String get medDetailActive => 'Active';

  @override
  String get medDetailStopped => 'Stopped';

  @override
  String get medDetailAdherence => 'Adherence';

  @override
  String get medDetailLast30 => 'Last 30 days';

  @override
  String get medDetailDays => 'Days taken';

  @override
  String get medDetailLast30Record => 'Last 30 days';

  @override
  String get medDetailEdit => 'Edit';

  @override
  String get medDetailSettings => 'Settings';

  @override
  String get medDetailHistory => 'Medication History';

  @override
  String get medDetailBasicInfo => 'Basic Info';

  @override
  String get medDetailRefill => 'Refill';

  @override
  String get moodCbtSituation => 'Situation';

  @override
  String get moodCbtAutoThought => 'Automatic Thought';

  @override
  String get moodCbtEvidenceFor => 'Evidence For';

  @override
  String get moodCbtEvidenceAgainst => 'Evidence Against';

  @override
  String get moodCbtAltThought => 'Alternative Thought';

  @override
  String get moodCbtRerated => 'Re-rated Score';

  @override
  String get moodCbtCoreBelief => 'Core Belief';

  @override
  String get moodCbtBehavior => 'Behavioral Response';

  @override
  String get moodDeleted => 'Deleted';

  @override
  String get moodPeriodAfternoon => 'Afternoon';

  @override
  String get settingsProfileTitle => 'Profile';

  @override
  String get settingsProfileSubtitle => 'Health records, medical info';

  @override
  String get todaySummaryCheckIn => 'Check-in';

  @override
  String get todaySummaryMeds => 'Meds';

  @override
  String get todaySummaryMood => 'Mood';

  @override
  String get todaySummaryStreak => 'Streak';

  @override
  String get setupConsentMedicalDisclaimer =>
      'I have read and understand the Medical Disclaimer: this app does not provide medical advice, diagnosis, or treatment';

  @override
  String get trackingCustomize => 'Customize Trackers';

  @override
  String get trackingUnknownItem => 'Unknown item';

  @override
  String get trackingPin => 'Pin to Top';

  @override
  String get trackingUnpin => 'Unpin';

  @override
  String get trackingHide => 'Hide This Item';

  @override
  String get trackingPinned => 'Pinned';

  @override
  String get trackingCategoryEmotional => 'Emotional State';

  @override
  String get trackingCategoryPhysical => 'Physical Metrics';

  @override
  String get trackingCategoryBehavioral => 'Behavioral Rhythm';

  @override
  String get trackingCategoryMedical => 'Medical Records';

  @override
  String todayTrackingSummary(int tracked, int total) {
    return 'Tracked $tracked/$total today';
  }

  @override
  String moodRecordingLabel(String duration) {
    return 'Recording $duration';
  }

  @override
  String get medicationNameRequired => 'Please enter medication name';

  @override
  String medicationAdded(String name) {
    return 'Added $name';
  }

  @override
  String get medicationStatusInUse => 'Active';

  @override
  String get medicationStatusStopped => 'Stopped';

  @override
  String factorAnalysisCount(int count) {
    return '$count entries';
  }

  @override
  String get setupConsentAgreeAll =>
      'I have read and agree to all the above agreements';

  @override
  String get assessmentComparisonImproved => 'Improved';

  @override
  String get assessmentComparisonWorsened => 'Worsened';

  @override
  String get assessmentComparisonUnchanged => 'Unchanged';

  @override
  String get assessmentComparisonFirst => 'First assessment';

  @override
  String assessmentDeltaSame(int delta) {
    return 'Same as last time ($delta)';
  }

  @override
  String assessmentDeltaHigher(int delta) {
    return '$delta points higher than last time';
  }

  @override
  String assessmentDeltaLower(int delta) {
    return '$delta points lower than last time';
  }

  @override
  String assessmentSeverityRank(int rank) {
    return 'Level $rank';
  }

  @override
  String get checkInTypeAssessment => 'Psychological assessment';

  @override
  String dayDetailTotalScore(int total) {
    return 'Total $total';
  }

  @override
  String get dayDetailScaleAssessment => 'Psychological assessment';

  @override
  String get medTodayPending => 'Pending';

  @override
  String get medTodayTaken => 'Taken';

  @override
  String get medTodayRefill => 'Refill';

  @override
  String get homeQuickActionView => 'View';

  @override
  String get homeQuickActionRecord => 'Log';

  @override
  String get homeQuickActionStart => 'Start';

  @override
  String get homeTodayMetrics => 'Today';

  @override
  String get ventTagFamily => 'Family';

  @override
  String get ventTagWork => 'Work';

  @override
  String get ventTagStudy => 'Study';

  @override
  String get ventTagRelationship => 'Relationship';

  @override
  String get ventTagFriends => 'Friends';

  @override
  String get ventTagHealth => 'Health';

  @override
  String get ventTagMood => 'Mood';

  @override
  String get ventTagOther => 'Other';

  @override
  String get statusPhraseLow1 => 'A little sad';

  @override
  String get statusPhraseLow2 => 'Feeling really down';

  @override
  String get statusPhraseLow3 => 'Feel like crying';

  @override
  String get statusPhraseLow4 => 'No energy';

  @override
  String get statusPhraseTired1 => 'Tired but calm';

  @override
  String get statusPhraseTired2 => 'So tired';

  @override
  String get statusPhraseTired3 => 'Drained';

  @override
  String get statusPhraseTired4 => 'Just want to lie down';

  @override
  String get statusPhraseCalm1 => 'Calm';

  @override
  String get statusPhraseCalm2 => 'At ease';

  @override
  String get statusPhraseCalm3 => 'Mellow';

  @override
  String get statusPhraseCalm4 => 'Nothing special';

  @override
  String get statusPhrasePositive1 => 'Feeling healed';

  @override
  String get statusPhrasePositive2 => 'Feeling good';

  @override
  String get statusPhrasePositive3 => 'Full of energy';

  @override
  String get statusPhrasePositive4 => 'Hopeful';

  @override
  String get statusPhrasePositive5 => 'Very happy';

  @override
  String get moodReviewEncouragementEmpty =>
      'Haven\'t recorded your mood this week — start now';

  @override
  String get moodReviewEncouragementLow =>
      'It\'s been a rough time — take care of yourself';

  @override
  String get moodReviewEncouragementMid =>
      'Moods have been up and down — venting may help';

  @override
  String get moodReviewEncouragementHigh => 'You\'re doing well — keep it up';

  @override
  String get moodReviewEncouragementNoAvg =>
      'Keep logging to better understand your emotions';

  @override
  String importSummaryMedication(int n) {
    return '$n medications';
  }

  @override
  String importSummaryCheckIn(int n) {
    return '$n check-ins';
  }

  @override
  String importSummaryReport(int n) {
    return '$n reports';
  }

  @override
  String importSummaryMood(int n) {
    return '$n moods';
  }

  @override
  String importSummaryVent(int n) {
    return '$n vents';
  }

  @override
  String get cbtExportPdfMoodLabel => 'Mood';

  @override
  String get cbtExportPdfOriginalScoreLabel => 'original';

  @override
  String get psychoTipsTitle => 'Self-care tips';

  @override
  String get psychoTipBreathTitle => 'Mindful breathing';

  @override
  String get psychoTipBreathSummary =>
      'Anchor yourself in the present by focusing on your breath';

  @override
  String get psychoTipBreathStep1 =>
      'Sit somewhere comfortable and gently close your eyes';

  @override
  String get psychoTipBreathStep2 =>
      'Breathe in for 4 seconds, feeling the air fill your body';

  @override
  String get psychoTipBreathStep3 => 'Hold your breath for 2 seconds';

  @override
  String get psychoTipBreathStep4 =>
      'Exhale slowly for 6 seconds, relaxing your shoulders and body';

  @override
  String get psychoTipBreathStep5 =>
      'Repeat for 3-5 minutes, keeping your attention on your breath';

  @override
  String get psychoTipNameTitle => 'Name the emotion';

  @override
  String get psychoTipNameSummary => 'Naming an emotion reduces its intensity';

  @override
  String get psychoTipNameStep1 => 'Pause and notice how your body is reacting';

  @override
  String get psychoTipNameStep2 =>
      'Ask yourself: what emotion am I feeling right now';

  @override
  String get psychoTipNameStep3 =>
      'Describe it in one word, like \"irritated\", \"sad\" or \"anxious\"';

  @override
  String get psychoTipNameStep4 => 'Say it or write it down: \"I feel…\"';

  @override
  String get psychoTipNameStep5 =>
      'Watch how the emotion shifts, without judging it';

  @override
  String get psychoTipCbtTitle => 'Cognitive reframing';

  @override
  String get psychoTipCbtSummary =>
      'Identify and adjust unhelpful automatic thoughts — pairs well with CBT records';

  @override
  String get psychoTipCbtStep1 =>
      'Write down the specific situation that triggered the feeling';

  @override
  String get psychoTipCbtStep2 =>
      'Record the automatic thought that came to mind';

  @override
  String get psychoTipCbtStep3 =>
      'List the evidence for and against this thought';

  @override
  String get psychoTipCbtStep4 =>
      'Write a more balanced, fact-based alternative thought';

  @override
  String get psychoTipCbtStep5 =>
      'Practice with a 5-column CBT record in your mood diary';

  @override
  String get psychoTipGroundTitle => '5-4-3-2-1 grounding';

  @override
  String get psychoTipGroundSummary =>
      'Use your five senses to return to the present and step back from anxiety';

  @override
  String get psychoTipGroundStep1 => 'Name 5 things you can see';

  @override
  String get psychoTipGroundStep2 => 'Notice 4 things you can touch';

  @override
  String get psychoTipGroundStep3 => 'Listen for 3 sounds you can hear';

  @override
  String get psychoTipGroundStep4 => 'Notice 2 smells around you';

  @override
  String get psychoTipGroundStep5 => 'Feel 1 taste in your mouth';

  @override
  String get psychoTipPmrTitle => 'Progressive muscle relaxation';

  @override
  String get psychoTipPmrSummary =>
      'Release physical tension by tensing and relaxing muscle groups';

  @override
  String get psychoTipPmrStep1 => 'Sit or lie down in a comfortable position';

  @override
  String get psychoTipPmrStep2 =>
      'Starting with your toes, tense them tightly for 5 seconds';

  @override
  String get psychoTipPmrStep3 =>
      'Release and enjoy the relaxed feeling for about 10 seconds';

  @override
  String get psychoTipPmrStep4 =>
      'Move upward: calves, thighs, belly, arms, shoulders';

  @override
  String get psychoTipPmrStep5 =>
      'Finish by relaxing your face and scalp for a full-body scan';

  @override
  String get ventAgreementTitle => 'Tree hole guidelines';

  @override
  String get ventAgreementBody =>
      'Your tree hole is a private space that belongs only to you. Please remember:\n· Everything you share stays on this device, encrypted and private\n· Vent content is never used in any analysis, recommendations or notifications\n· Be gentle with yourself and honor every feeling\n· If you feel intense distress or think of harming yourself, please use the crisis hotline for help';

  @override
  String get ventAgreementConfirm => 'Got it';

  @override
  String get worryTimelineTitle => 'Worry timeline';

  @override
  String get worryArchiveTitle => 'Memories';

  @override
  String get worrySectionTitle => 'Worries';

  @override
  String get worrySectionArchiveAction => 'Memories';

  @override
  String worryEntryCount(Object count) {
    return '$count entries';
  }

  @override
  String get worryContinueAction => 'Keep writing';

  @override
  String get worryResolveAction => 'Let it go';

  @override
  String get worryReopenAction => 'It\'s back';

  @override
  String get worryResolveConfirmTitle => 'Let go of this worry?';

  @override
  String get worryResolveConfirmBody =>
      'It will be kept in Memories. You can reopen it anytime.';

  @override
  String get worryResolveConfirmOk => 'Let it go';

  @override
  String get worryResolveDone => '🎉 You let go of a worry';

  @override
  String get worryReopenDone => 'Reopened — write whenever you need';

  @override
  String get worryRenameTitle => 'Rename worry';

  @override
  String get worryRenameAction => 'Rename';

  @override
  String get worryNewOption => 'New worry';

  @override
  String get worryNoWorry => 'No linked worry';

  @override
  String get worryDefaultTitle => 'Unnamed worry';

  @override
  String get worryFieldLabel => 'Linked worry';

  @override
  String get worryFieldHint =>
      'Choose or create a worry to add this mood to its timeline';

  @override
  String get worryTimelineEmpty =>
      'This worry has no entries yet. Start with \"Keep writing\".';

  @override
  String get worryArchiveEmpty =>
      'No worries let go yet. Turning moods into worry timelines makes growth last.';

  @override
  String worryArchiveCount(Object count) {
    return '$count worries let go';
  }

  @override
  String worryOpenCount(Object count) {
    return '$count in progress';
  }

  @override
  String get worryStatusOpen => 'In progress';

  @override
  String get worryStatusResolved => 'Let go';

  @override
  String get worryThreadNotFound =>
      'This worry is no longer available — it may have been deleted.';

  @override
  String get dbResetPromptTitle => 'Can\'t open local database';

  @override
  String get dbResetPromptBody =>
      'The encrypted local data doesn\'t match its key (often caused by a backup restore that recovered data but not the key). You can tap \"Retry\" first to see if your data comes back; if it still can\'t open, you can reset local data and start over.';

  @override
  String get dbResetPromptReset => 'Reset local data';

  @override
  String get dbResetPromptConfirm =>
      'Resetting will delete all local records and cannot be undone. Confirm reset?';

  @override
  String moodTrendSemanticsAvg(Object average) {
    return 'average $average out of 5';
  }
}

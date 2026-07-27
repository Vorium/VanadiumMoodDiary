v0.26 R57 P0 收尾 todo

- P0 #1 隐私政策 §3 用户姓名 → 用户昵称 (trivial 0.1h) — 已完成(实际是 R22 已改)
- P0 #2 app_zh.arb 半角/... → 全角／…… — 6 行半角/待修 + 14 半角…已修
- P0 #3 core/l10n/strings.dart 21 处硬编中文加 override 模式 — 中等 0.5-1d
- P0 #4 PHQ-9 + GAD-7 i18n 化 — 中等 1d (需改 presentation，超出范围)
- P0 #5 medication_report_pdf.dart Colors.white/black — 已完成(用 PdfColors 正确)
- P1 #6 app_zh_Hant.arb 1 处 你→您
- P1 #7 user_agreement.md + sensitive_data_consent.md v0.22 → v0.24
- P1 #8 safety_watch SMS 模板 — 已迁到 safety_alert_dispatcher (非允许文件)
- P1 #9 同 P0 #3
- P1 #10-13 视时间

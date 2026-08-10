# R108 P0 #11-#13 subagent C — task breakdown

## Fix #11a keystore (R108 增量)
- [x] 复用 R72 `generate_release_keystore.ps1` (PowerShell)
- [ ] 写 bash 版本 `scripts/generate_android_keystore.sh` (Mac/Linux dev)
- [ ] 写 setup doc `R108-android-keystore-setup.md`
- [ ] 写 lock-in test `test/scripts/keystore_script_round108_test.py`

## Fix #11b Data Safety Form (R108 增量)
- [x] 复用 R72 `generate_data_safety_form.py` (覆盖 5 大类)
- [ ] 验证 v0.30 状态仍准确 (R107 cleanup 加 v0.30 标记 + lock-in)
- [ ] 写 setup doc `R108-android-data-safety-form.md`
- [ ] 写 lock-in test `test/scripts/data_safety_form_round108_test.py`

## Fix #11c Health Apps Questionnaire (R108 新增)
- [ ] 写 `scripts/generate_health_apps_questionnaire.py`
- [ ] 写 setup doc `R108-android-health-apps-questionnaire.md`
- [ ] 写 lock-in test `test/scripts/health_apps_questionnaire_round108_test.py`

## Fix #12 截图脚本
- [ ] 写 `scripts/generate_ios_screenshots.sh` (Mac only)
- [ ] 写 `scripts/generate_android_screenshots.sh`
- [ ] 写 setup doc `R108-screenshots-automation.md`
- [ ] 写 lock-in test `test/scripts/screenshots_scripts_round108_test.py`

## Fix #13 域名 + 邮箱
- [ ] 写 `docs/audit/2026-08-10-cleanup/R108-domain-registration-guide.md` (详细)
- [ ] 写 `scripts/register_domain.sh` 占位
- [ ] 写 4 HTML 模板 `scripts/templates/*.html.tmpl`
- [ ] 写 lock-in test `test/scripts/domain_check_round108_test.py`

## 最终报告
- [ ] 写 `R108-p0-11to13-report.md`
- [ ] 跑守门员 verify (check_arb_keys / check_changelog / check_no_pua)
- [ ] 验证 12 URL 文件占位正确

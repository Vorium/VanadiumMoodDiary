import re, sys

files = [
    r'lib\presentation\pages\daily_tracking\widgets\weight_widgets.dart',
    r'lib\presentation\pages\daily_tracking\widgets\social_rhythm_widgets.dart',
    r'lib\presentation\pages\daily_tracking\widgets\anxiety_agitation_widgets.dart',
    r'lib\presentation\pages\daily_tracking\widgets\sleep_widgets.dart',
    r'lib\presentation\pages\daily_tracking\widgets\stress_event_widgets.dart',
    r'lib\presentation\pages\mood_list\widgets\mood_list_item.dart',
    r'lib\presentation\pages\mood_list\widgets\mood_list_filter_bar.dart',
    r'lib\presentation\pages\settings\widgets\cbt_section.dart',
    r'lib\presentation\widgets\consent_dialog.dart',
    r'lib\presentation\widgets\medication_report_dialog.dart',
    r'lib\presentation\pages\medication\medication_calendar_page.dart',
    r'lib\presentation\pages\setup\setup_legal_dialog.dart',
    r'lib\presentation\pages\settings\widgets\data_management_section\widgets\export_tile.dart',
]
root = r'd:\Batch\chroniccare'
pat = re.compile(r"'[^']*[\u4e00-\u9fff][^']*'|\"[^\"]*[\u4e00-\u9fff][^\"]*\"")
import os
out = open(r'd:\Batch\chroniccare\reports\r100\hardcoded_list.txt', 'w', encoding='utf-8')
for rel in files:
    p = os.path.join(root, rel)
    for i, line in enumerate(open(p, encoding='utf-8'), 1):
        s = line.strip()
        if s.startswith('//') or s.startswith('*') or s.startswith('///'):
            continue
        for m in pat.finditer(line):
            txt = m.group(0)
            out.write(f'{rel}:{i}: {txt}\n')
out.close()

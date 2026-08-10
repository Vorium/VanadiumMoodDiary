# v0.30 R100 (P1#15 / N-1): repo 根临时垃圾文件 → .mavis-trash/r100-root-junk/
#
# 只动 repo 根 untracked 垃圾 (_*.py / _*.tmp / _trash_* / test_*.txt / analyze* /
# CRLF''' / LF''' 等)。不碰 tracked 文件 / .qoder / coverage / reports / scripts /
# .gradle-8.14-all.zip / chroniccare.iml。
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DEST = os.path.join(ROOT, '.mavis-trash', 'r100-root-junk')
os.makedirs(DEST, exist_ok=True)

# git status --porcelain 报的 untracked 垃圾 (repo 根)
NAMES = [
    "CRLF'''", "LF'''",
    '_audit_output.txt', '_audit_v2.txt', '_audit_v3.txt',
    '_c1.py', '_c2.py', '_d.py', '_dc.py', '_f.py', '_ft.py',
    '_g.py', '_h.py', '_lf.py',
    '_o1.tmp', '_o2.tmp', '_o3.tmp', '_o4.tmp', '_o5.tmp', '_o6.tmp',
    '_p.py', '_pr2.py', '_pr2_tmp.nul', '_pr3.py', '_ps2.txt', '_r2.py',
    '_t1.txt', '_t2.txt',
    '_trash_final.txt', '_trash_fixup.txt', '_trash_r96c.txt',
    '_trash_t30.txt', '_trash_t31a.txt', '_trash_t31b.txt', '_trash_t32.txt',
    '_trash_t53.txt', '_trash_t54.txt', '_trash_t55.txt',
    '_trash_translate.py', '_trash_translate2.py',
    'analyze.txt', 'analyze2.py', 'analyze_arb.py', 'analyze_test.py',
    'check_options.py',
    'find_fails2.py', 'find_fails4.py',
    'plan.txt', 'tail.txt', 'tail2.txt',
    'test_4groups.txt', 'test_4groups_v2.txt', 'test_7sec.txt',
    'test_7sec_v2.txt', 'test_all.txt', 'test_all_final.txt',
    'test_all_v2.txt', 'test_all_v3.txt', 'test_all_v4.txt',
    'test_all_v5.txt', 'test_all_v6.txt', 'test_all_v7.txt',
    'test_all_v8.txt', 'test_all_v9.txt',
    'test_c1.txt', 'test_case1.txt', 'test_case1_v2.txt',
    'test_contact.txt', 'test_contact_v2.txt', 'test_contact_v3.txt',
    'test_export.txt', 'test_fails.txt', 'test_meds_err.txt',
    'test_one.txt', 'test_round45.txt', 'test_round45_v2.txt',
    'test_settings.txt', 'test_settings_v2.txt', 'test_settings_v3.txt',
    'test_settings_v4.txt', 'test_settings_v5.txt', 'test_vent48.txt',
    # 目录树可见但已 gitignore 的同款垃圾
    '_dif.tmp', '_e.py', '_upd.py', 'flutter_01.log',
    '_r95_full_run.log', '_r95_int1.log', '_r95_int4.log',
    '_r95_int5.log', '_r95_int_test.log', '_r95_subspec6_full.log',
]

lines = []
moved = 0
for name in NAMES:
    src = os.path.join(ROOT, name)
    if not os.path.exists(src):
        lines.append('SKIP (missing): ' + name)
        continue
    dst = os.path.join(DEST, name)
    n = 1
    while os.path.exists(dst):
        dst = os.path.join(DEST, name + '.dup' + str(n))
        n += 1
    shutil.move(src, dst)
    lines.append('MOVED: ' + name)
    moved += 1

out = os.path.join(os.path.dirname(__file__), 'trash_move_result.txt')
with open(out, 'w', encoding='utf-8') as f:
    f.write('moved=%d\n' % moved)
    f.write('\n'.join(lines) + '\n')

"""Convert app_zh_Hant.arb from simplified to traditional using OpenCC s2tw.

Strategy:
- Parse ARB as text (preserve structure, indentation, key ordering)
- For each "key": "value" line, convert only the value
- Keep @@locale, @key, key, placeholders, English/numbers/punctuation intact
- Re-emit in same format
"""
import opencc
import re
import sys

CONVERTER = opencc.OpenCC('s2tw')

SRC = r'lib/l10n/app_zh_Hant.arb'
OUT = r'lib/l10n/app_zh_Hant.arb.tmp'


def is_simplified(s: str) -> bool:
    """Heuristic: does the string contain any char that is a known simplified-only form?"""
    # Tiny set of diagnostic simplified chars we expect zh_Hant to have.
    # If s has none, it doesn't need conversion.
    SIMPLIFIED = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词请谢报员岁岁时刻钟天慢病管家情绪焦虑抑郁睡眠疲惫紧张评估答卷分级组给简复关联网路图档档')
    return any(c in SIMPLIFIED for c in s)


def convert_line(line: str) -> str:
    """Convert one ARB value line, preserving key and structure."""
    # Match: "  "key": "value", (optional trailing comment)
    m = re.match(r'^(  )"([^"]+)":\s*"(.*)"(,?)(.*)$', line.rstrip('\n'))
    if not m:
        # metadata or non-value line; pass through
        return line
    indent, key, value, trailing_comma, rest = m.groups()
    if not is_simplified(value):
        return line  # already fine
    new_value = CONVERTER.convert(value)
    # Preserve original quoting
    return f'{indent}"{key}": "{new_value}"{trailing_comma}{rest}\n'


def main():
    with open(SRC, encoding='utf-8') as f:
        text = f.read()
    new_lines = [convert_line(l) for l in text.splitlines(keepends=True)]
    new_text = ''.join(new_lines)
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print(f'Wrote {OUT}')


if __name__ == '__main__':
    main()

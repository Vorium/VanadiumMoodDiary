"""Test OpenCC s2tw on sample ARB content."""
import opencc

converter = opencc.OpenCC('s2tw')

# 测试用例
test_cases = [
    '今天是星期三,您吃了吗?',
    '您常吃什么药?',
    '这是您将收到的失联通知预览:',
    '识别中……',
    '已答 {answered} ／ {total}',
    '「{days} 天」后提醒',
    '设置',
    '您已经连续打卡 {streak} 天',
    '数据库加密保护您的隐私',
    '您吃了吗?你好',
    '我是一名医生,这是我的诊所',
    '抑郁、焦虑、失眠、疲劳',
    '请填写您的手机号',
    '我的家人:慢病管家',
    '您好,我是慢病管家',
]

print('=== s2tw 测试 ===')
for t in test_cases:
    out = converter.convert(t)
    print(f'  {t!r}')
    print(f'  -> {out!r}')
    print()

# 测试 key 不会变 (英文字符)
key_test = '"moodDialogTitle": "今天怎么样？"'
print('=== ARB key 不变测试 ===')
print(f'  in:  {key_test!r}')
print(f'  out: {converter.convert(key_test)!r}')

# 测试 metadata (@ 开头)
meta_test = '  "@@locale": "zh_Hant",'
print(f'  in:  {meta_test!r}')
print(f'  out: {converter.convert(meta_test)!r}')

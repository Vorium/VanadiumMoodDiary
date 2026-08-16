// 规则 3 标记: canonical zh fallback, 显示层走 l10n preset_content_l10n.dart
// lib/domain/logic/psychology_tips_library.dart
/// 心理技巧知识库（v1.1.0）— 本地正念 / 情绪调节技巧内容
///
/// 纯静态内容 (0 Flutter / 0 DB / 0 采集), 供"心理技巧"页展示。
/// canonical zh 文本存 domain, 显示层按 locale 走 ARB
/// (`localizedPsychologyTip`, preset_content_l10n.dart)。
///
/// 内容来源: 论文《基于Flutter的记录情绪日记APP软件设计与实现》"学习心理
/// 技巧"用例 + 正念 / 认知行为疗法 (CBT) 常用自助技巧, 本地优先不联网。
class PsychologyTip {
  const PsychologyTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
  });

  /// 稳定 id, 用于显示层 ARB 映射 (不可改, 改会断 l10n switch 锁测试)
  final String id;

  /// canonical zh 标题 (显示层按 locale 走 ARB)
  final String title;

  /// 一句话摘要 (canonical zh)
  final String summary;

  /// 操作步骤 (canonical zh, 顺序有意义)
  final List<String> steps;
}

/// 心理技巧库 — 静态技巧列表
class PsychologyTipsLibrary {
  PsychologyTipsLibrary._();

  static const List<PsychologyTip> all = [
    PsychologyTip(
      id: 'mindfulBreathing',
      title: '正念呼吸', // 走 ARB (显示层 localizedPsychologyTip)
      summary: '通过关注呼吸回到当下，缓解焦虑与紧张',
      steps: [
        '找个舒适的位置坐下，轻轻闭上眼睛',
        '深吸气 4 秒，感受空气充满身体',
        '屏住呼吸 2 秒',
        '缓缓呼气 6 秒，让肩膀和身体放松',
        '重复 3-5 分钟，让注意力回到呼吸上',
      ],
    ),
    PsychologyTip(
      id: 'nameEmotion',
      title: '情绪命名', // 走 ARB (显示层 localizedPsychologyTip)
      summary: '给情绪贴上名字，能有效降低它的强度',
      steps: [
        '停下来，感受此刻身体有哪些反应',
        '在心里问自己：我现在的情绪是什么',
        '用一个词描述它，比如「烦躁」「难过」「紧张」',
        '说出来或写下来：「我感到……」',
        '观察情绪的变化，不去评判它',
      ],
    ),
    PsychologyTip(
      id: 'cognitiveReframing',
      title: '认知重构', // 走 ARB (显示层 localizedPsychologyTip)
      summary: '识别并调整不合理的自动思维，可搭配 CBT 思维记录',
      steps: [
        '记录引发情绪的具体情境',
        '写下脑海中冒出的自动思维',
        '列出支持与反对这个想法的证据',
        '写出更平衡、更符合事实的替代想法',
        '在情绪日记中使用 5 栏 CBT 记录练习',
      ],
    ),
    PsychologyTip(
      id: 'grounding54321',
      title: '5-4-3-2-1 感官接地', // 走 ARB (显示层 localizedPsychologyTip)
      summary: '用五种感官觉察当下，把注意力从焦虑中拉回来',
      steps: [
        '说出你看到的 5 样东西',
        '感受你触碰到的 4 种触感',
        '仔细听你听到的 3 种声音',
        '闻到你周围的 2 种气味',
        '感受口中的 1 种味道',
      ],
    ),
    PsychologyTip(
      id: 'progressiveMuscleRelaxation',
      title: '渐进式肌肉放松', // 走 ARB (显示层 localizedPsychologyTip)
      summary: '依次收紧再放松身体各肌肉群，释放身体的紧张',
      steps: [
        '坐或躺下，找一个舒适的姿势',
        '从脚趾开始，用力收紧 5 秒',
        '松开，体会放松的感觉约 10 秒',
        '依次向上：小腿、大腿、腹部、手臂、肩膀',
        '最后放松面部与头皮，完成全身扫描',
      ],
    ),
  ];

  /// 按 id 取技巧; 未知 id 返回 null
  static PsychologyTip? byId(String id) {
    for (final tip in all) {
      if (tip.id == id) return tip;
    }
    return null;
  }
}
// rule3-whitelist: 39-40, 42-46, 51-52, 54-58, 63-64, 66-70, 75-76, 78-82, 87-88, 90-94
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py

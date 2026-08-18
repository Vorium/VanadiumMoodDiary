// v0.32 R112 round 8i (渲染专项): 实时转写行 — 自持 STT 订阅的小 widget
//
// 修前 mood_audio_recorder_widget 在 STT 每个 partial 结果 (说话时每秒多次)
// setState 重建整个 600+ 行 dialog = 录音中明显掉帧。抽本 widget 自持订阅
// (unmount 时 cancel), 只有 ~40 行重建; 最新文本经 [onText] 回传父级做
// final transcript (父级只存字段不 rebuild)。
//
// 与 _RecordingTimer (R102) 同理念: 高频更新区域自隔离。
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

class SttLiveTranscript extends StatefulWidget {
  final Stream<String> stream;
  final ValueChanged<String> onText;
  const SttLiveTranscript({
    super.key,
    required this.stream,
    required this.onText,
  });

  @override
  State<SttLiveTranscript> createState() => SttLiveTranscriptState();
}

class SttLiveTranscriptState extends State<SttLiveTranscript> {
  StreamSubscription<String>? _sub;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((text) {
      if (text.isEmpty || !mounted) return;
      widget.onText(text);
      setState(() => _text = text);
    });
  }

  @override
  void dispose() {
    // R97-P1-12: unawaited 显式标记 fire-and-forget (cancel 不阻塞)
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.spacingXs),
      child: Text(
        _text,
        style: AppTokens.textStyleCaption(context).copyWith(
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

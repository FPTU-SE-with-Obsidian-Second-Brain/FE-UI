/// Optional context sent with POST /chat. Null / empty → body only has question (legacy).
class ChatRequestContext {
  final List<String> sourceIds;
  final String? sourceFile;
  final String mode; // default | subject_focus | quick_action | study_plan
  final String? action; // explain | translate_vi | summarize
  final String? excerpt;
  final int? currentSemester;
  final String? goal;
  final String? comboTrack;

  const ChatRequestContext({
    this.sourceIds = const [],
    this.sourceFile,
    this.mode = 'default',
    this.action,
    this.excerpt,
    this.currentSemester,
    this.goal,
    this.comboTrack,
  });

  bool get hasExtraFields =>
      sourceIds.isNotEmpty ||
      (sourceFile != null && sourceFile!.isNotEmpty) ||
      (mode != 'default') ||
      (action != null) ||
      (excerpt != null && excerpt!.isNotEmpty) ||
      currentSemester != null ||
      (goal != null && goal!.isNotEmpty) ||
      (comboTrack != null && comboTrack!.isNotEmpty);

  /// Build JSON fields to merge into the request body (never includes question).
  Map<String, dynamic> toJsonFields() {
    if (!hasExtraFields) return {};

    final map = <String, dynamic>{};
    if (sourceIds.isNotEmpty) map['source_ids'] = sourceIds;
    if (sourceFile != null && sourceFile!.isNotEmpty) {
      map['source_file'] = sourceFile;
    }
    if (mode != 'default') map['mode'] = mode;
    if (action != null) map['action'] = action;
    if (excerpt != null && excerpt!.isNotEmpty) map['excerpt'] = excerpt;
    if (mode == 'study_plan' || currentSemester != null || goal != null) {
      map['mode'] = 'study_plan';
      final input = <String, dynamic>{
        'current_semester': currentSemester ?? 3,
        'goal': goal ?? 'AI Engineer',
      };
      if (comboTrack != null && comboTrack!.isNotEmpty) {
        input['combo_track'] = comboTrack;
      }
      map['study_plan_input'] = input;
    }
    return map;
  }

  ChatRequestContext merge(ChatRequestContext? other) {
    if (other == null) return this;
    return ChatRequestContext(
      sourceIds: {...sourceIds, ...other.sourceIds}.toList(),
      sourceFile: other.sourceFile ?? sourceFile,
      mode: other.mode != 'default' ? other.mode : mode,
      action: other.action ?? action,
      excerpt: other.excerpt ?? excerpt,
      currentSemester: other.currentSemester ?? currentSemester,
      goal: other.goal ?? goal,
      comboTrack: other.comboTrack ?? comboTrack,
    );
  }
}

import 'package:flutter/material.dart';

class StudyPlanDialogResult {
  final int semester;
  final String goal;
  /// Tên track combo trong KB, vd. "Java chuyên sâu", "lập trình .NET"
  final String? comboTrack;

  const StudyPlanDialogResult({
    required this.semester,
    required this.goal,
    this.comboTrack,
  });
}

const _comboTracks = <String>[
  'Tự suy từ mục tiêu',
  'Java chuyên sâu',
  'lập trình .NET',
  'AI',
  'React NodeJS',
  'Phát triển game',
  'Khoa học dữ liệu (KHDL) ứng dụng',
  'Tích hợp DevSepOps cho cloud',
  'Thiết kế vi mạch',
];

/// Dialog nhập Kỳ hiện tại + mục tiêu nghề nghiệp cho Study Planner.
Future<StudyPlanDialogResult?> showStudyPlanDialog(BuildContext context) {
  return showDialog<StudyPlanDialogResult>(
    context: context,
    builder: (ctx) => const _StudyPlanDialog(),
  );
}

class _StudyPlanDialog extends StatefulWidget {
  const _StudyPlanDialog();

  @override
  State<_StudyPlanDialog> createState() => _StudyPlanDialogState();
}

class _StudyPlanDialogState extends State<_StudyPlanDialog> {
  int _semester = 3;
  String _track = _comboTracks.first;
  final _goalController = TextEditingController(text: 'Java Engineer');

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lộ trình học tập cá nhân hóa'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn kỳ, mục tiêu và chuyên ngành hẹp. Slot SE_COM* / PHE_COM* '
              'sẽ được đổi thành mã môn cụ thể (VD Java → HSF302, .NET → PRN212).',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _semester,
              decoration: const InputDecoration(
                labelText: 'Kỳ hiện tại',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: List.generate(10, (i) {
                return DropdownMenuItem(value: i, child: Text('Kỳ $i'));
              }),
              onChanged: (v) {
                if (v != null) _semester = v;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Mục tiêu nghề nghiệp',
                hintText: 'VD: Java Engineer, .NET Developer, AI Engineer…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _track,
              decoration: const InputDecoration(
                labelText: 'Chuyên ngành hẹp (combo SE)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _comboTracks
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _track = v;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final goal = _goalController.text.trim();
            if (goal.isEmpty) return;
            final track =
                _track == 'Tự suy từ mục tiêu' ? null : _track;
            Navigator.of(context).pop(
              StudyPlanDialogResult(
                semester: _semester,
                goal: goal,
                comboTrack: track,
              ),
            );
          },
          child: const Text('Tạo lộ trình'),
        ),
      ],
    );
  }
}

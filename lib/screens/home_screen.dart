import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../widgets/split_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.hub_outlined, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FPTU SE Second Brain',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (provider.currentFolderPath != null)
                      Text(
                        'Thư mục: ${provider.currentFolderPath}',
                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              if (provider.notes.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.notes.length} môn học/tài liệu',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              IconButton(
                tooltip: 'Quét lại thư mục (Reload)',
                icon: const Icon(Icons.refresh),
                onPressed: provider.currentFolderPath != null
                    ? () => provider.loadFromFolder(provider.currentFolderPath!)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: FilledButton.tonalIcon(
                  onPressed: () => provider.pickFolder(),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Đổi thư mục'),
                ),
              ),
            ],
          ),
          body: const SplitView(),
        );
      },
    );
  }
}

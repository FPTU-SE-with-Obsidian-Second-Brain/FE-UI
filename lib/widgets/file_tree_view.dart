import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_file.dart';
import '../providers/note_provider.dart';

class FileTreeView extends StatelessWidget {
  const FileTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Đang quét thư mục .md...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (provider.notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có dữ liệu Markdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng chọn thư mục chứa các file .md của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.pickFolder(),
                    icon: const Icon(Icons.folder),
                    label: const Text('Chọn thư mục'),
                  ),
                ],
              ),
            ),
          );
        }

        final grouped = provider.groupedNotes;

        return Column(
          children: [
            // Ô tìm kiếm nhanh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: TextField(
                onChanged: (value) => provider.setSearchQuery(value),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm môn học, mã môn...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => provider.setSearchQuery(''),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Danh sách cây thư mục phân theo Kỳ học
            Expanded(
              child: ListView.builder(
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final folderName = grouped.keys.elementAt(index);
                  final folderNotes = grouped[folderName]!;

                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      leading: Icon(
                        folderName.contains('Kỳ') ? Icons.school_outlined : Icons.folder_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        folderName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${folderNotes.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      children: folderNotes.map((note) {
                        final isSelected = note.path == provider.selectedNote?.path;
                        return _buildNoteItem(context, provider, note, isSelected);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    NoteProvider provider,
    NoteFile note,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary.withAlpha(120), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          Icons.description_outlined,
          size: 18,
          color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color?.withAlpha(180),
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: note.links.isNotEmpty
            ? Tooltip(
                message: '${note.links.length} liên kết [[...]]',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '[[${note.links.length}]]',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              )
            : null,
        onTap: () => provider.selectNote(note),
      ),
    );
  }
}

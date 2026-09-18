import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_file.dart';
import '../../providers/note_provider.dart';

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
                Text(
                  'Đang quét thư mục .md...',
                  style: TextStyle(color: Colors.grey),
                ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
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
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withAlpha(80),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Danh sách cây thư mục phân theo Kỳ học (Custom Collapsible Tree, no ListTile)
            Expanded(
              child: ListView.builder(
                itemCount: grouped.keys.length,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemBuilder: (context, index) {
                  final folderName = grouped.keys.elementAt(index);
                  final folderNotes = grouped[folderName]!;

                  return _FolderGroup(
                    key: ValueKey('folder_$folderName'),
                    folderName: folderName,
                    folderNotes: folderNotes,
                    provider: provider,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FolderGroup extends StatefulWidget {
  final String folderName;
  final List<NoteFile> folderNotes;
  final NoteProvider provider;

  const _FolderGroup({
    super.key,
    required this.folderName,
    required this.folderNotes,
    required this.provider,
  });

  @override
  State<_FolderGroup> createState() => _FolderGroupState();
}

class _FolderGroupState extends State<_FolderGroup> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề thư mục / Kỳ học
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.folderName.contains('Kỳ')
                        ? Icons.school_outlined
                        : Icons.folder_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.folderNotes.length}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Các môn học bên trong thư mục (nếu đang mở)
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              children: widget.folderNotes.map((note) {
                final isSelected =
                    note.path == widget.provider.selectedNote?.path;
                return _buildNoteItem(
                  context,
                  widget.provider,
                  note,
                  isSelected,
                );
              }).toList(),
            ),
          ),
      ],
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
      key: ValueKey('note_${note.path}'),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(
                color: theme.colorScheme.primary.withAlpha(120),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => provider.selectNote(note),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color?.withAlpha(180),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.links.isNotEmpty)
                  Tooltip(
                    message: '${note.links.length} liên kết [[...]]',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

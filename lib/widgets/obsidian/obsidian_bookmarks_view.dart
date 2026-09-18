import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_file.dart';
import '../../providers/note_provider.dart';

class ObsidianBookmarksView extends StatefulWidget {
  const ObsidianBookmarksView({super.key});

  @override
  State<ObsidianBookmarksView> createState() => _ObsidianBookmarksViewState();
}

class _ObsidianBookmarksViewState extends State<ObsidianBookmarksView> {
  int _tabIndex = 0; // 0: Môn cốt lõi SE, 1: Môn đã ghim ⭐

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final coreNotes = provider.coreCurriculumNotes;
        final bookmarkedNotes = provider.bookmarkedNotes;

        return Column(
          children: [
            // Thanh chuyển đổi giữa "Môn cốt lõi SE" và "Đã ghim"
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        label: 'Môn cốt lõi SE',
                        isSelected: _tabIndex == 0,
                        count: coreNotes.length,
                        onTap: () => setState(() => _tabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildSegmentButton(
                        label: 'Đã ghim',
                        isSelected: _tabIndex == 1,
                        count: bookmarkedNotes.length,
                        onTap: () => setState(() => _tabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Danh sách môn học
            Expanded(
              child: _tabIndex == 0
                  ? _buildCoreList(context, provider, coreNotes)
                  : _buildCustomBookmarksList(
                      context,
                      provider,
                      bookmarkedNotes,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : theme.hintColor,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withAlpha(70)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : theme.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreList(
    BuildContext context,
    NoteProvider provider,
    List<NoteFile> list,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (list.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy môn học cốt lõi trong thư mục',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final note = list[index];
        final isSelected = note.path == provider.selectedNote?.path;
        final isBookmarked = provider.isBookmarked(note);

        return Container(
          key: ValueKey('core_${note.path}'),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => provider.selectNote(note),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 18,
                      color: isSelected
                          ? colorScheme.primary
                          : const Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? colorScheme.primary : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            note.folderName,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        size: 16,
                        color: isBookmarked
                            ? const Color(0xFFA855F7)
                            : theme.hintColor,
                      ),
                      tooltip: isBookmarked ? 'Bỏ ghim' : 'Ghim môn học',
                      onPressed: () => provider.toggleBookmark(note),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomBookmarksList(
    BuildContext context,
    NoteProvider provider,
    List<NoteFile> list,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 44,
                color: theme.hintColor.withAlpha(120),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa ghim môn nào',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn có thể ghim các môn đang học hoặc chuẩn bị thi để truy cập nhanh chóng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.hintColor.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final note = list[index];
        final isSelected = note.path == provider.selectedNote?.path;

        return Container(
          key: ValueKey('bm_${note.path}'),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => provider.selectNote(note),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark,
                      size: 18,
                      color: Color(0xFFA855F7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? colorScheme.primary : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            note.folderName,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      tooltip: 'Bỏ ghim',
                      onPressed: () => provider.toggleBookmark(note),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

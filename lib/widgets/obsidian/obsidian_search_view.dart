import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';

class ObsidianSearchView extends StatelessWidget {
  const ObsidianSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final results = provider.detailedSearchResults;
        final hasQuery = provider.searchQuery.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ô tìm kiếm chính
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                controller: TextEditingController(text: provider.searchQuery)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: provider.searchQuery.length),
                  ),
                onChanged: (val) => provider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm toàn văn...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => provider.setSearchQuery(''),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Các nút chọn phạm vi tìm kiếm (Search Mode Chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModeChip(
                      context,
                      label: 'Tất cả',
                      isSelected: provider.searchMode == SearchMode.all,
                      onSelected: () => provider.setSearchMode(SearchMode.all),
                    ),
                    const SizedBox(width: 6),
                    _buildModeChip(
                      context,
                      label: 'Mã / Tên môn',
                      isSelected: provider.searchMode == SearchMode.titleOnly,
                      onSelected: () => provider.setSearchMode(SearchMode.titleOnly),
                    ),
                    const SizedBox(width: 6),
                    _buildModeChip(
                      context,
                      label: 'Trong nội dung',
                      isSelected: provider.searchMode == SearchMode.contentOnly,
                      onSelected: () => provider.setSearchMode(SearchMode.contentOnly),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Thông báo số lượng kết quả tìm thấy
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      '${results.length} kết quả phù hợp',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Danh sách kết quả
            Expanded(
              child: !hasQuery
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.manage_search_outlined, size: 48, color: theme.hintColor.withAlpha(120)),
                            const SizedBox(height: 12),
                            Text(
                              'Tìm kiếm nhanh',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.hintColor),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gõ mã môn (ví dụ: PRM, PRF, CSD) hoặc từ khóa bài học để tra cứu toàn bộ kho tri thức.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: theme.hintColor.withAlpha(150)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 40, color: theme.hintColor),
                                const SizedBox(height: 10),
                                Text(
                                  'Không tìm thấy kết quả',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: results.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            final note = item.note;
                            final isSelected = note.path == provider.selectedNote?.path;

                            return InkWell(
                              onTap: () => provider.selectNote(note),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                color: isSelected ? colorScheme.primary.withAlpha(35) : Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: 16,
                                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            note.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? colorScheme.primary : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            note.folderName,
                                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.matchedSnippet != null) ...[
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 24.0),
                                        child: Text(
                                          item.matchedSnippet!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.hintColor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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

  Widget _buildModeChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(45) : colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : theme.hintColor,
          ),
        ),
      ),
    );
  }
}

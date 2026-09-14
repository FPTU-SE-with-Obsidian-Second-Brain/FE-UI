import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_file.dart';
import '../services/file_service.dart';
import '../utils/constants.dart';

enum SearchMode { all, titleOnly, contentOnly }

class NoteSearchResult {
  final NoteFile note;
  final String? matchedSnippet;
  const NoteSearchResult({required this.note, this.matchedSnippet});
}

class NoteProvider extends ChangeNotifier {
  final FileService _fileService = FileService();

  List<NoteFile> notes = [];
  NoteFile? selectedNote;
  bool isLoading = false;
  String? currentFolderPath;

  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  final Set<String> _bookmarkedPaths = {};

  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  Set<String> get bookmarkedPaths => _bookmarkedPaths;

  // Thống kê Vault cho Activity Bar Settings dialog
  int get totalNotesCount => notes.length;
  int get totalLinksCount => notes.fold(0, (sum, n) => sum + n.links.length);
  int get totalSemestersCount => notes.map((n) => n.folderName).toSet().length;

  /// Danh sách các môn đã đánh dấu Bookmarks (hoặc môn trọng tâm)
  List<NoteFile> get bookmarkedNotes {
    return notes.where((note) => _bookmarkedPaths.contains(note.path)).toList();
  }

  /// Danh sách các môn cốt lõi ngành Kỹ thuật Phần mềm FPTU (Milestone Courses)
  static const List<String> coreCourseCodes = [
    'PRF192',
    'PRO192',
    'CSD201',
    'DBI202',
    'OSG202',
    'PRJ301',
    'SWE201',
    'PRM392',
    'SWP391',
    'SWT301',
    'SWR302',
    'SWD392',
    'SEP490',
  ];

  /// Danh sách môn cốt lõi tìm thấy trong dữ liệu hiện tại
  List<NoteFile> get coreCurriculumNotes {
    final Map<String, NoteFile> matched = {};
    for (final code in coreCourseCodes) {
      final note = getNoteByFileName(code);
      if (note != null) {
        matched[note.fileName] = note;
      }
    }
    return matched.values.toList();
  }

  /// Lọc danh sách note theo từ khóa tìm kiếm (theo mã môn, tiêu đề hoặc thư mục)
  List<NoteFile> get filteredNotes {
    if (_searchQuery.trim().isEmpty) return notes;
    final query = _searchQuery.toLowerCase().trim();
    return notes.where((note) {
      if (_searchMode == SearchMode.titleOnly) {
        return note.title.toLowerCase().contains(query) ||
            note.fileName.toLowerCase().contains(query);
      } else if (_searchMode == SearchMode.contentOnly) {
        return note.rawContent.toLowerCase().contains(query);
      } else {
        return note.title.toLowerCase().contains(query) ||
            note.fileName.toLowerCase().contains(query) ||
            note.folderName.toLowerCase().contains(query) ||
            note.rawContent.toLowerCase().contains(query);
      }
    }).toList();
  }

  /// Tìm kiếm chi tiết kèm đoạn trích dẫn văn bản (Full-text Snippet Search)
  List<NoteSearchResult> get detailedSearchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final query = _searchQuery.toLowerCase().trim();
    final results = <NoteSearchResult>[];

    for (final note in notes) {
      final inTitle = note.title.toLowerCase().contains(query) ||
          note.fileName.toLowerCase().contains(query);
      final inFolder = note.folderName.toLowerCase().contains(query);
      final inContent = note.rawContent.toLowerCase().contains(query);

      bool isMatch = false;
      if (_searchMode == SearchMode.titleOnly) {
        isMatch = inTitle;
      } else if (_searchMode == SearchMode.contentOnly) {
        isMatch = inContent;
      } else {
        isMatch = inTitle || inFolder || inContent;
      }

      if (isMatch) {
        String? snippet;
        if (inContent) {
          snippet = _extractSnippet(note.rawContent, query);
        }
        results.add(NoteSearchResult(note: note, matchedSnippet: snippet));
      }
    }

    return results;
  }

  String? _extractSnippet(String text, String query) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx == -1) return null;

    final start = (idx - 40).clamp(0, text.length);
    final end = (idx + query.length + 60).clamp(0, text.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < text.length ? '...' : '';
    return '$prefix${text.substring(start, end).replaceAll('\n', ' ')}$suffix';
  }

  /// Gom nhóm danh sách note theo từng Thư mục / Kỳ học (Kỳ 0, Kỳ 1, ..., Tổng quan)
  Map<String, List<NoteFile>> get groupedNotes {
    final Map<String, List<NoteFile>> groups = {};
    for (final note in filteredNotes) {
      groups.putIfAbsent(note.folderName, () => []).add(note);
    }
    return groups;
  }

  /// Cập nhật từ khóa tìm kiếm
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Cập nhật chế độ tìm kiếm
  void setSearchMode(SearchMode mode) {
    _searchMode = mode;
    notifyListeners();
  }

  /// Bật/tắt đánh dấu Bookmark
  Future<void> toggleBookmark(NoteFile note) async {
    if (_bookmarkedPaths.contains(note.path)) {
      _bookmarkedPaths.remove(note.path);
    } else {
      _bookmarkedPaths.add(note.path);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarked_paths', _bookmarkedPaths.toList());
  }

  bool isBookmarked(NoteFile note) => _bookmarkedPaths.contains(note.path);

  /// Khởi tạo và tự động nạp thư mục gần nhất hoặc thư mục có sẵn
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Nạp bookmarks đã lưu
    final savedBookmarks = prefs.getStringList('bookmarked_paths');
    if (savedBookmarks != null) {
      _bookmarkedPaths.addAll(savedBookmarks);
    }

    // 1. Kiểm tra thư mục "Lab 1 - Obsidian second brain" ngay trong thư mục app
    final labDir = Directory(p.join(Directory.current.path, 'Lab 1 - Obsidian second brain'));
    if (await labDir.exists()) {
      await loadFromFolder(labDir.path);
      return;
    }

    // 2. Kiểm tra thư mục "Obsidian second brain"
    final defaultDir = Directory(p.join(Directory.current.path, 'Obsidian second brain'));
    if (await defaultDir.exists()) {
      await loadFromFolder(defaultDir.path);
      return;
    }

    // 3. Nạp từ cấu hình đã lưu
    final savedPath = prefs.getString(AppConstants.keyKbFolderPath);
    if (savedPath != null && await Directory(savedPath).exists()) {
      await loadFromFolder(savedPath);
    }
  }

  /// Quét và nạp dữ liệu từ thư mục
  Future<void> loadFromFolder(String folderPath) async {
    isLoading = true;
    currentFolderPath = folderPath;
    notifyListeners();

    notes = await _fileService.scanDirectory(folderPath);

    // Lưu lại thư mục vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyKbFolderPath, folderPath);

    // Tự động chọn note đầu tiên nếu có
    selectedNote = notes.isNotEmpty ? notes.first : null;

    isLoading = false;
    notifyListeners();
  }

  /// Chọn note đang xem
  void selectNote(NoteFile note) {
    selectedNote = note;
    notifyListeners();
  }

  /// Tra cứu note theo tên file hoặc tên môn (Hợp đồng cho TV3 Graph View & Click Link)
  NoteFile? getNoteByFileName(String fileName) {
    final cleanName = fileName
        .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
        .trim()
        .toLowerCase();

    try {
      return notes.firstWhere((n) {
        final nTitle = n.title.toLowerCase().trim();
        final nFile = n.fileName
            .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
            .toLowerCase()
            .trim();
        return nTitle == cleanName || nFile == cleanName;
      });
    } catch (_) {
      return null;
    }
  }

  /// Chọn note bằng liên kết dạng [[TenMon]]
  bool selectNoteByLink(String link) {
    final target = getNoteByFileName(link);
    if (target != null) {
      selectNote(target);
      return true;
    }
    return false;
  }

  /// Mở hộp thoại hệ điều hành để người dùng chọn thư mục Knowledge Base
  Future<void> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await loadFromFolder(path);
    }
  }
}

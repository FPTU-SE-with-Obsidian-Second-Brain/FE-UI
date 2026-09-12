import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_file.dart';
import '../services/file_service.dart';
import '../utils/constants.dart';

class NoteProvider extends ChangeNotifier {
  final FileService _fileService = FileService();

  List<NoteFile> notes = [];
  NoteFile? selectedNote;
  bool isLoading = false;
  String? currentFolderPath;
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  /// Lọc danh sách note theo từ khóa tìm kiếm (theo mã môn, tiêu đề hoặc nội dung)
  List<NoteFile> get filteredNotes {
    if (_searchQuery.trim().isEmpty) return notes;
    final query = _searchQuery.toLowerCase().trim();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.fileName.toLowerCase().contains(query) ||
          note.folderName.toLowerCase().contains(query);
    }).toList();
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

  /// Khởi tạo và tự động nạp thư mục gần nhất hoặc thư mục có sẵn
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(AppConstants.keyKbFolderPath);

    if (savedPath != null && await Directory(savedPath).exists()) {
      await loadFromFolder(savedPath);
      return;
    }

    // Dự phòng: Tìm thư mục "Obsidian second brain" ngay trong dự án nếu có
    final defaultDir = Directory(p.join(Directory.current.path, 'Obsidian second brain'));
    if (await defaultDir.exists()) {
      await loadFromFolder(defaultDir.path);
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

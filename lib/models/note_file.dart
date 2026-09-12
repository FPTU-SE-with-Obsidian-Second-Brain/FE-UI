class NoteFile {
  final String path; // Đường dẫn đầy đủ tới file .md
  final String fileName; // Ví dụ: PRM393.md
  final String title; // Tên hiển thị (mặc định = fileName không đuôi)
  final String folderName; // Tên thư mục chứa (ví dụ: "Kỳ 1", "Kỳ 2", hoặc "Gốc")
  final String rawContent; // Toàn bộ nội dung file (markdown thô)
  final List<String> links; // Các liên kết trích từ [[...]], ví dụ: ["PRO192"]
  final DateTime lastModified;

  NoteFile({
    required this.path,
    required this.fileName,
    required this.title,
    this.folderName = '',
    required this.rawContent,
    required this.links,
    required this.lastModified,
  });
}

class NoteFile {
  final String path; // Đường dẫn đầy đủ tới file .md
  final String fileName; // Ví dụ: PRM393.md
  final String title; // Tên hiển thị (mặc định = fileName không đuôi)
  final String folderName; // Tên học kỳ / thư mục chính (ví dụ: "Kỳ 1", "Kỳ 5", "Tổng quan")
  final String? comboTrack; // Tên chuyên ngành / định hướng nếu có (ví dụ: "React NodeJS", "Cờ vua BIT", ".NET")
  final String? fullFolderPath; // Đường dẫn tương đối dạng breadcrumb (ví dụ: "Kỳ 5 › SE_COM*1 › React NodeJS")
  final String rawContent; // Toàn bộ nội dung file (markdown thô)
  final List<String> links; // Các liên kết trích từ [[...]], ví dụ: ["PRO192"]
  final DateTime lastModified;

  NoteFile({
    required this.path,
    required this.fileName,
    required this.title,
    this.folderName = '',
    this.comboTrack,
    this.fullFolderPath,
    required this.rawContent,
    required this.links,
    required this.lastModified,
  });
}

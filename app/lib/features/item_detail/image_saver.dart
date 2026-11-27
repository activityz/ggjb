import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// 把字节交给「另存为」的能力。抽成函数类型是为了在测试里替换掉系统对话框。
typedef SaveBytes = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
});

/// 保存结果。三种状态必须分开表达，页面才能决定「提示什么」：
/// 取消不是失败，不能弹错误。
sealed class SaveOutcome {
  const SaveOutcome();
}

class SaveOutcomeSaved extends SaveOutcome {
  const SaveOutcomeSaved(this.path);

  /// 用户选中的最终路径。
  final String path;
}

class SaveOutcomeCancelled extends SaveOutcome {
  const SaveOutcomeCancelled();
}

class SaveOutcomeFailed extends SaveOutcome {
  const SaveOutcomeFailed(this.message);

  /// 给用户看的一句话，不含异常堆栈。
  final String message;
}

/// 把商品图片存到用户选的位置。
class ImageSaver {
  ImageSaver({SaveBytes? saveBytes, DateTime Function()? clock})
    : _saveBytes = saveBytes ?? _saveWithFilePicker,
      _clock = clock ?? DateTime.now;

  final SaveBytes _saveBytes;
  final DateTime Function() _clock;

  /// 文件名的商品名部分最长多少字。
  static const int titleMaxLength = 10;

  Future<SaveOutcome> save({
    required String title,
    required String mime,
    required Uint8List bytes,
  }) async {
    final fileName = buildFileName(title: title, mime: mime, at: _clock());
    try {
      final path = await _saveBytes(fileName: fileName, bytes: bytes);
      // `saveFile` 返回 null 表示用户取消 —— 不是错误，不该弹提示。
      if (path == null) return const SaveOutcomeCancelled();
      return SaveOutcomeSaved(path);
    } catch (_) {
      // 异常原文对用户没有意义（FileSystemException / 堆栈），只给一句能照做的话。
      return const SaveOutcomeFailed('保存失败，换一个位置试试');
    }
  }

  /// 文件名里不允许出现的字符：路径分隔符 + Windows 保留字符 + 控制字符。
  /// 换成空格而不是直接删掉，避免「A/B」粘成「AB」。
  static final RegExp _illegal = RegExp(r'[\\/:*?"<>|\u0000-\u001F\u007F]');

  /// `ggjb-<商品名前 10 字>-<yyyyMMdd-HHmmss>.<扩展名>`。
  static String buildFileName({
    required String title,
    required String mime,
    required DateTime at,
  }) {
    final cleaned = title
        .replaceAll(_illegal, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    var name = cleaned.length > titleMaxLength
        ? cleaned.substring(0, titleMaxLength).trim()
        : cleaned;
    if (name.isEmpty) name = '图片';
    final stamp =
        '${at.year.toString().padLeft(4, '0')}'
        '${at.month.toString().padLeft(2, '0')}'
        '${at.day.toString().padLeft(2, '0')}-'
        '${at.hour.toString().padLeft(2, '0')}'
        '${at.minute.toString().padLeft(2, '0')}'
        '${at.second.toString().padLeft(2, '0')}';
    return 'ggjb-$name-$stamp.${_extFor(mime)}';
  }

  /// 扩展名跟着附件的 mime 走；未知类型按 png（库里附件基本都是 png）。
  static String _extFor(String mime) {
    final m = mime.toLowerCase();
    if (m == 'image/jpeg' || m == 'image/jpg') return 'jpg';
    return 'png';
  }

  /// 生产实现：系统「另存为」。桌面弹原生对话框，Android 走 SAF 保存面板，
  /// 两端都由 file_picker 自己把 [bytes] 写到用户选的位置。
  static Future<String?> _saveWithFilePicker({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FilePicker.saveFile(
      dialogTitle: '保存图片',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [fileName.split('.').last],
      bytes: bytes,
      lockParentWindow: true,
    );
  }
}

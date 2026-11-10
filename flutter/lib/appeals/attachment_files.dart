import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:modus_api/api.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_service.dart';
import '../api/app_error.dart';

/// Файл, выбранный пользователем для загрузки.
class PickedFile {
  const PickedFile({required this.name, required this.path, required this.size});

  final String name;
  final String path;
  final int size;
}

/// Лимит из контракта: не больше 20 МБ на файл (`413 file_too_large`).
const maxAttachmentBytes = 20 * 1024 * 1024;

Future<Attachment> uploadAttachment(ApiService api, int appealId, PickedFile file) async {
  try {
    final part = await http.MultipartFile.fromPath('file', file.path, filename: file.name);
    final result = await api.attachments.uploadAttachment(appealId, part);
    if (result == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
    return result;
  } catch (e) {
    throw AppError.from(e);
  }
}

/// Скачивает вложение во временную папку и открывает системным просмотрщиком.
/// `download_url` требует токен, поэтому качаем через клиент API. Сгенерированный
/// `downloadAttachment` пытается разобрать файл как JSON, поэтому берём `WithHttpInfo`.
Future<void> openAttachment(ApiService api, Attachment attachment) async {
  final http.Response response;
  try {
    response = await api.attachments.downloadAttachmentWithHttpInfo(attachment.id);
  } catch (e) {
    throw AppError.from(e);
  }
  if (response.statusCode >= 400) {
    throw AppError.from(ApiException(response.statusCode, response.body));
  }
  final dir = await getTemporaryDirectory();
  final safeName = attachment.filename.replaceAll(RegExp(r'[/\\]'), '_');
  final file = File('${dir.path}/attachment_${attachment.id}_$safeName');
  await file.writeAsBytes(response.bodyBytes, flush: true);
  final result = await OpenFilex.open(file.path, type: attachment.contentType);
  if (result.type != ResultType.done) {
    throw AppError(code: 'open_failed', message: 'Не удалось открыть файл: ${result.message}');
  }
}

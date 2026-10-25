import '../../library/domain/entities/song.dart';

enum TelegramAuth {
  disconnected,
  starting,
  phone,
  code,
  password,
  ready,
  unsupported,
  unconfigured,
  other,
}

enum TelegramFailure { network, phone, code, password, flood, storage, generic }

class TelegramException implements Exception {
  const TelegramException(this.failure);
  final TelegramFailure failure;
}

class TelegramChat {
  const TelegramChat({
    required this.id,
    required this.title,
    required this.kind,
    this.photoFileId = 0,
    this.photoPath = '',
    this.miniPhoto = '',
  });
  final int id;
  final String title;
  final String kind;
  final int photoFileId;
  final String photoPath;
  final String miniPhoto;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'photoFileId': photoFileId,
    'photoPath': photoPath,
    'miniPhoto': miniPhoto,
  };
  factory TelegramChat.fromJson(Map<String, dynamic> json) => TelegramChat(
    id: json['id'] as int,
    title: json['title'] as String,
    kind: json['kind'] as String,
    photoFileId: json['photoFileId'] as int? ?? 0,
    photoPath: json['photoPath'] as String? ?? '',
    miniPhoto: json['miniPhoto'] as String? ?? '',
  );
}

class TelegramAudio {
  const TelegramAudio({
    required this.messageId,
    required this.chatId,
    required this.fileId,
    required this.fileName,
    required this.size,
    required this.title,
    required this.artist,
    required this.duration,
    this.localPath = '',
    this.date = 0,
    this.coverFileId = 0,
    this.coverPath = '',
    this.miniCover = '',
  });
  final int messageId;
  final int chatId;
  final int fileId;
  final String fileName;
  final int size;
  final String title;
  final String artist;
  final int duration;
  final String localPath;
  final int date;
  final int coverFileId;
  final String coverPath;
  final String miniCover;
  String get key => '$chatId:$messageId';

  TelegramAudio withLocalPath(String path) => TelegramAudio(
    messageId: messageId,
    chatId: chatId,
    fileId: fileId,
    fileName: fileName,
    size: size,
    title: title,
    artist: artist,
    duration: duration,
    localPath: path,
    date: date,
    coverFileId: coverFileId,
    coverPath: coverPath,
    miniCover: miniCover,
  );

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'chatId': chatId,
    'fileId': fileId,
    'fileName': fileName,
    'size': size,
    'title': title,
    'artist': artist,
    'duration': duration,
    'localPath': localPath,
    'date': date,
    'coverFileId': coverFileId,
    'coverPath': coverPath,
    'miniCover': miniCover,
  };
  factory TelegramAudio.fromJson(Map<String, dynamic> json) => TelegramAudio(
    messageId: json['messageId'] as int,
    chatId: json['chatId'] as int,
    fileId: json['fileId'] as int,
    fileName: json['fileName'] as String,
    size: json['size'] as int,
    title: json['title'] as String,
    artist: json['artist'] as String,
    duration: json['duration'] as int,
    localPath: json['localPath'] as String? ?? '',
    date: json['date'] as int? ?? 0,
    coverFileId: json['coverFileId'] as int? ?? 0,
    coverPath: json['coverPath'] as String? ?? '',
    miniCover: json['miniCover'] as String? ?? '',
  );
}

class TelegramLocalFile {
  const TelegramLocalFile(
    this.id,
    this.path, {
    this.received = 0,
    this.total = 0,
  });
  final int id;
  final int received;
  final int total;

  /// Empty unless the complete file is locally available.
  final String path;
}

class TelegramAudioPage {
  const TelegramAudioPage(this.items, this.nextId);
  final List<TelegramAudio> items;
  final int nextId;
}

class TelegramTrack {
  const TelegramTrack(this.audio, {this.song});
  final TelegramAudio audio;
  final Song? song;
  bool get hasLocalFile => song != null;
}

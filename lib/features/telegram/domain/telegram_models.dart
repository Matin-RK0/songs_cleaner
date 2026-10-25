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

enum TelegramFailure { network, phone, code, password, flood, generic }

class TelegramException implements Exception {
  const TelegramException(this.failure);
  final TelegramFailure failure;
}

class TelegramChat {
  const TelegramChat({
    required this.id,
    required this.title,
    required this.kind,
  });
  final int id;
  final String title;
  final String kind;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'kind': kind};
  factory TelegramChat.fromJson(Map<String, dynamic> json) => TelegramChat(
    id: json['id'] as int,
    title: json['title'] as String,
    kind: json['kind'] as String,
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
  String get key => '$chatId:$messageId';

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
  );
}

class TelegramAudioPage {
  const TelegramAudioPage(this.items, this.nextId);
  final List<TelegramAudio> items;
  final int nextId;
}

class TelegramTrack {
  const TelegramTrack(this.audio, {this.song, this.candidates = const []});
  final TelegramAudio audio;
  final Song? song;
  final List<Song> candidates;
}

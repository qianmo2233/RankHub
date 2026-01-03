import 'package:isar_community/isar.dart';
import 'enums/level_index.dart';
import 'enums/song_type.dart';
import 'maimai_notes.dart';
import 'maimai_buddy_notes.dart';

part 'maimai_song.g.dart';

/// 谱面难度
@embedded
class MaimaiSongDifficulty {
  MaimaiSongDifficulty({
    this.type = SongType.standard,
    this.difficulty = LevelIndex.basic,
    this.level = '',
    this.levelValue = 0.0,
    this.noteDesigner = '',
    this.version = 0,
    this.notes,
  });

  /// 谱面类型
  @Enumerated(EnumType.name)
  late SongType type;

  /// 难度
  @Enumerated(EnumType.name)
  late LevelIndex difficulty;

  /// 难度标级
  late String level;

  /// 谱面定数
  late double levelValue;

  /// 谱师
  late String noteDesigner;

  /// 谱面首次出现版本
  late int version;

  /// 谱面物量
  MaimaiNotes? notes;

  factory MaimaiSongDifficulty.fromJson(Map<String, dynamic> json) {
    return MaimaiSongDifficulty(
      type: json['type'] != null
          ? SongType.fromValue(json['type'])
          : SongType.standard,
      difficulty: json['difficulty'] != null
          ? LevelIndex.fromValue(json['difficulty'] as int)
          : LevelIndex.basic,
      level: json['level'] as String? ?? '',
      levelValue: (json['level_value'] as num?)?.toDouble() ?? 0.0,
      noteDesigner: json['note_designer'] as String? ?? '',
      version: json['version'] as int? ?? 0,
      notes: json['notes'] != null ? MaimaiNotes.fromJson(json['notes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'difficulty': difficulty.value,
      'level': level,
      'level_value': levelValue,
      'note_designer': noteDesigner,
      'version': version,
      'notes': notes?.toJson(),
    };
  }
}

/// 宴会场曲目谱面难度
@embedded
class MaimaiSongDifficultyUtage {
  MaimaiSongDifficultyUtage({
    this.type = SongType.standard,
    this.difficulty = LevelIndex.basic,
    this.level = '',
    this.levelValue = 0.0,
    this.noteDesigner = '',
    this.version = 0,
    this.notes,
    this.kanji = '',
    this.description = '',
    this.isBuddy = false,
    this.buddyNotes,
  });

  /// 谱面类型
  @Enumerated(EnumType.name)
  late SongType type;

  /// 难度
  @Enumerated(EnumType.name)
  late LevelIndex difficulty;

  /// 难度标级
  late String level;

  /// 谱面定数
  late double levelValue;

  /// 谱师
  late String noteDesigner;

  /// 谱面首次出现版本
  late int version;

  /// 谱面物量
  MaimaiNotes? notes;

  /// 谱面属性
  late String kanji;

  /// 谱面描述
  late String description;

  /// 是否为 BUDDY 谱面
  late bool isBuddy;

  /// BUDDY 谱面物量
  MaimaiBuddyNotes? buddyNotes;

  factory MaimaiSongDifficultyUtage.fromJson(Map<String, dynamic> json) {
    final isBuddy = json['is_buddy'] as bool? ?? false;
    return MaimaiSongDifficultyUtage(
      type: json['type'] != null
          ? SongType.fromValue(json['type'])
          : SongType.standard,
      difficulty: json['difficulty'] != null
          ? LevelIndex.fromValue(json['difficulty'] as int)
          : LevelIndex.basic,
      level: json['level'] as String? ?? '',
      levelValue: (json['level_value'] as num?)?.toDouble() ?? 0.0,
      noteDesigner: json['note_designer'] as String? ?? '',
      version: json['version'] as int? ?? 0,
      kanji: json['kanji'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isBuddy: isBuddy,
      notes: isBuddy || json['notes'] == null
          ? null
          : MaimaiNotes.fromJson(json['notes']),
      buddyNotes: isBuddy && json['notes'] != null
          ? MaimaiBuddyNotes.fromJson(json['notes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'difficulty': difficulty.value,
      'level': level,
      'level_value': levelValue,
      'note_designer': noteDesigner,
      'version': version,
      'kanji': kanji,
      'description': description,
      'is_buddy': isBuddy,
      if (isBuddy) 'notes': buddyNotes?.toJson() else 'notes': notes?.toJson(),
    };
  }
}

/// 谱面难度列表
@embedded
class MaimaiSongDifficulties {
  const MaimaiSongDifficulties({
    this.standard = const [],
    this.dx = const [],
    this.utage = const [],
  });

  /// 标准谱面难度列表
  final List<MaimaiSongDifficulty> standard;

  /// DX 谱面难度列表
  final List<MaimaiSongDifficulty> dx;

  /// 宴会场谱面难度列表
  final List<MaimaiSongDifficultyUtage> utage;

  factory MaimaiSongDifficulties.fromJson(Map<String, dynamic> json) {
    return MaimaiSongDifficulties(
      standard:
          (json['standard'] as List?)
              ?.map((e) => MaimaiSongDifficulty.fromJson(e))
              .toList() ??
          [],
      dx:
          (json['dx'] as List?)
              ?.map((e) => MaimaiSongDifficulty.fromJson(e))
              .toList() ??
          [],
      utage:
          (json['utage'] as List?)
              ?.map((e) => MaimaiSongDifficultyUtage.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standard': standard.map((e) => e.toJson()).toList(),
      'dx': dx.map((e) => e.toJson()).toList(),
      'utage': utage.map((e) => e.toJson()).toList(),
    };
  }
}

/// 曲目
@collection
class MaimaiSong {
  MaimaiSong({
    this.id = Isar.autoIncrement,
    this.songId = 0,
    this.title = '',
    this.artist = '',
    this.genre = '',
    this.bpm = 0,
    this.map,
    this.version = 0,
    this.rights,
    this.locked = false,
    this.disabled = false,
    this.difficulties = const MaimaiSongDifficulties(),
  });

  /// Isar 自增 ID
  Id id;

  /// 曲目 ID
  @Index(unique: true)
  late int songId;

  /// 曲名
  @Index(type: IndexType.value)
  late String title;

  /// 艺术家
  late String artist;

  /// 曲目分类
  late String genre;

  /// 曲目 BPM
  late int bpm;

  /// 曲目所属区域
  String? map;

  /// 曲目首次出现版本
  late int version;

  /// 曲目版权信息
  String? rights;

  /// 是否需要解锁
  late bool locked;

  /// 是否被禁用
  late bool disabled;

  /// 谱面难度
  late MaimaiSongDifficulties difficulties;

  @ignore
  String jacketUrl = "";

  @ignore
  String mp3Url = "";

  @ignore
  List<String> aliasList = [];

  @ignore
  String versionTitle = "";

  factory MaimaiSong.fromJson(Map<String, dynamic> json) {
    final songId = json['id'] as int? ?? 0;
    final song = MaimaiSong(
      songId: songId,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      bpm: json['bpm'] as int? ?? 0,
      map: json['map'] as String?,
      version: json['version'] as int? ?? 0,
      rights: json['rights'] as String?,
      locked: json['locked'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      difficulties: json['difficulties'] != null
          ? MaimaiSongDifficulties.fromJson(json['difficulties'])
          : const MaimaiSongDifficulties(),
    );

    // 设置曲绘 URL（从 LXNS API）
    song.jacketUrl = 'https://assets2.lxns.net/maimai/jacket/$songId.png';

    return song;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': songId,
      'title': title,
      'artist': artist,
      'genre': genre,
      'bpm': bpm,
      'map': map,
      'version': version,
      'rights': rights,
      'locked': locked,
      'disabled': disabled,
      'difficulties': difficulties.toJson(),
    };
  }
}

/// 乐曲分类
@collection
class MaimaiGenre {
  MaimaiGenre({
    this.id = Isar.autoIncrement,
    this.genreId = 0,
    this.title = '',
    this.genre = '',
  });

  /// Isar 自增 ID
  Id id;

  /// 内部 ID
  @Index(unique: true)
  late int genreId;

  /// 分类标题
  late String title;

  /// 分类标题（日文）
  late String genre;

  factory MaimaiGenre.fromJson(Map<String, dynamic> json) {
    return MaimaiGenre(
      genreId: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': genreId, 'title': title, 'genre': genre};
  }
}

/// 曲目版本
@collection
class MaimaiVersion {
  MaimaiVersion({
    this.id = Isar.autoIncrement,
    this.versionId = 0,
    this.title = '',
    this.version = 0,
  });

  /// Isar 自增 ID
  Id id;

  /// 内部 ID
  @Index(unique: true)
  late int versionId;

  /// 版本标题
  late String title;

  /// 主要版本 ID
  late int version;

  factory MaimaiVersion.fromJson(Map<String, dynamic> json) {
    return MaimaiVersion(
      versionId: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      version: json['version'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': versionId, 'title': title, 'version': version};
  }
}

/// 曲目别名
@collection
class Alias {
  Alias({
    this.id = Isar.autoIncrement,
    this.songId = 0,
    this.aliases = const [],
  });

  /// Isar 自增 ID
  Id id;

  /// 曲目 ID
  @Index(unique: true)
  late int songId;

  /// 曲目所有别名
  late List<String> aliases;

  factory Alias.fromJson(Map<String, dynamic> json) {
    return Alias(
      songId: json['song_id'] as int? ?? 0,
      aliases:
          (json['aliases'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'song_id': songId, 'aliases': aliases};
  }
}

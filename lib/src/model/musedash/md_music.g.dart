// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'md_music.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MdMusicAdapter extends TypeAdapter<MdMusic> {
  @override
  final int typeId = 37;

  @override
  MdMusic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MdMusic(
      uid: fields[0] as String,
      name: fields[1] as String,
      author: fields[2] as String,
      cover: fields[3] as String,
      bpm: fields[4] as String,
      levelDesigner: (fields[5] as List).cast<String>(),
      difficulty: (fields[6] as List).cast<String>(),
      localized: fields[7] as MdLocalizedText,
    );
  }

  @override
  void write(BinaryWriter writer, MdMusic obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.cover)
      ..writeByte(4)
      ..write(obj.bpm)
      ..writeByte(5)
      ..write(obj.levelDesigner)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.localized);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MdMusicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

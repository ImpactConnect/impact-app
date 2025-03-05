// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sermon_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SermonAdapter extends TypeAdapter<Sermon> {
  @override
  final int typeId = 1;

  @override
  Sermon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sermon(
      id: fields[0] as String,
      title: fields[1] as String,
      preacherName: fields[2] as String,
      thumbnailUrl: fields[3] as String,
      audioUrl: fields[4] as String,
      category: fields[5] as String,
      tags: (fields[6] as List).cast<String>(),
      dateCreated: fields[7] as DateTime,
      isBookmarked: fields[8] as bool,
      isDownloaded: fields[9] as bool,
      localAudioPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sermon obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.preacherName)
      ..writeByte(3)
      ..write(obj.thumbnailUrl)
      ..writeByte(4)
      ..write(obj.audioUrl)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.dateCreated)
      ..writeByte(8)
      ..write(obj.isBookmarked)
      ..writeByte(9)
      ..write(obj.isDownloaded)
      ..writeByte(10)
      ..write(obj.localAudioPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SermonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

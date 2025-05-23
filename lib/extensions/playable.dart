import 'package:harmonoid/models/playable.dart';

/// Extensions for [Playable].
extension PlayableExtensions on Playable {
  /// Display title.
  String get displayTitle => title;

  /// Display subtitle.
  String get displaySubtitle => subtitle.join(', ');

  /// Query used to search for lyrics.
  String get lyricsGetQuery => [title, ...subtitle].join(' ');

  /// Playlist entry title.
  /// Ref: media_library/lib/src/extensions/track.dart
  String get playlistEntryTitle => [title, subtitle.join(', ')].where((e) => e.isNotEmpty).join(' • ');
}

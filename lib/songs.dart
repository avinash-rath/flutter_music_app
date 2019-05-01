import 'package:meta/meta.dart';

final demoPlaylist = DemoPlaylist(songs: [
  DemoSong(
    audioUrl:
        "https://api.soundcloud.com/tracks/266891990/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    albumArtUrl:
        "https://www.wyzowl.com/wp-content/uploads/2018/08/The-20-Best-Royalty-Free-Music-Sites-in-2018.png",
    songTitle: 'Song 1',
    artist: 'Artist 1',
  ),
  DemoSong(
    audioUrl: "https://api.soundcloud.com/tracks/260578593/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    albumArtUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRtDds6dS9hl9c9zld6rq7MgYBKJbh1JylUdGFv9P8ZiVm9IRmQ",
    songTitle: 'Song 2',
    artist: 'Artist 2',
  ),
]);

class DemoPlaylist {
  final List<DemoSong> songs;

  DemoPlaylist({
    this.songs,
  });
}

class DemoSong {
  final String audioUrl;
  final String albumArtUrl;
  final String songTitle;
  final String artist;
  DemoSong({
    this.audioUrl,
    this.albumArtUrl,
    this.songTitle,
    this.artist,
  });
}

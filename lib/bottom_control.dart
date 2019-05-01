import 'package:flutter/material.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'songs.dart';
import 'dart:math';

import 'theme.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
        color: accentColor,
        child: Padding(
          padding: EdgeInsets.only(
            top: 40,
            bottom: 50,
          ),
          child: Column(
            children: <Widget>[
              AudioPlaylistComponent(
                playlistBuilder: (BuildContext context, Playlist playlist, Widget child) {

                  String songTitle = demoPlaylist.songs[playlist.activeIndex].songTitle;
                  String artist = demoPlaylist.songs[playlist.activeIndex].artist;

                  return RichText(
                    textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '',
                    children: [
                      TextSpan(
                        text: '${songTitle.toUpperCase()} \n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: '${artist.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(),
                    ),
                    new PreviousButton(),
                    Expanded(
                      child: Container(),
                    ),
                    new PlayPauseButton(),
                    Expanded(
                      child: Container(),
                    ),
                    new NextButton(),
                    Expanded(
                      child: Container(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AudioComponent(
      updateMe: [WatchableAudioProperties.audioPlayerState],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        IconData icon = Icons.music_note;
        Function onPressed;
        Color buttonColor = lightAccentColor;

        if (player.state == AudioPlayerState.playing) {
          icon = Icons.pause;
          onPressed = player.pause;
          buttonColor = Colors.white;
        } else if (player.state == AudioPlayerState.paused ||
            player.state == AudioPlayerState.completed) {
          icon = Icons.play_arrow;
          onPressed = player.play;
          buttonColor = Colors.white;
        }

        return RawMaterialButton(
          onPressed: onPressed,
          shape: CircleBorder(),
          fillColor: buttonColor,
          splashColor: lightAccentColor,
          highlightColor: lightAccentColor.withOpacity(0.5),
          elevation: 10.0,
          highlightElevation: 5.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 35.0,
              color: darkAccentColor,
            ),
          ),
        );
      },
    );
  }
}

class PreviousButton extends StatelessWidget {
  const PreviousButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AudioPlaylistComponent(
      playlistBuilder: (BuildContext context, Playlist playlist, Widget child) {
        return IconButton(
          splashColor: lightAccentColor,
          highlightColor: Colors.transparent,
          icon: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 35.0,
          ),
          onPressed: playlist.previous,
        );
      },
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AudioPlaylistComponent(
      playlistBuilder: (BuildContext context, Playlist playlist, Widget child) {
        return IconButton(
          splashColor: lightAccentColor,
          highlightColor: Colors.transparent,
          icon: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 35.0,
          ),
          onPressed: playlist.next,
        );
      },
    );
  }
}

class CircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
      center: Offset(
        size.width / 2,
        size.height / 2,
      ),
      radius: min(size.width, size.height) / 2,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

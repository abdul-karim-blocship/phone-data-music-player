import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bg_media_player/position.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int selectedSong;

  const AudioPlayerScreen(
      {super.key, required this.songs, required this.selectedSong});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  AudioPlayer audioPlayer = AudioPlayer();

  // permissionCheck() async {
  //   if (await Permission.storage.request().isGranted) {
  //     await _accessFiles();
  //   } else {
  //     await Permission.storage.request();
  //     permissionCheck();
  //   }
  // }

  final playlist = ConcatenatingAudioSource(children: []);

  Future<void> _accessFiles() async {
    final Directory mainDir = Directory('/storage/emulated/0/');
    List songs = [];
    var folderList = mainDir
        .listSync()
        .map((item) => item as Directory)
        .where((item) => item.path.endsWith(""))
        .toList(growable: false);
    for (Directory i in folderList) {
      if (i.path != '/storage/emulated/0/Android') {
        songs.add(i
            .listSync()
            .map((e) => File(e.path))
            .where((element) =>
                element.path.endsWith(".mp3") || element.path.endsWith(".m4a"))
            .toList(growable: false));
      }
    }
    for (List<File> aSongList in songs) {
      if (aSongList.isNotEmpty) {
        for (var singleSong in aSongList) {
          playlist.add(AudioSource.file(singleSong.path,
              tag: MediaItem(
                  id: singleSong.uri.toString(), title: singleSong.path)));
        }
      }
    }
    print("playlist ${playlist.length}");
    print("songs ${songs}");
  }

  Stream<PositionData> get _positionDataStream => Rx.combineLatest3(
      audioPlayer.positionStream,
      audioPlayer.bufferedPositionStream,
      audioPlayer.durationStream,
      (position, bufferedPosition, duration) => PositionData(
          duration: duration ?? Duration.zero,
          position: position,
          bufferedPosition: bufferedPosition));

  @override
  void initState() {
    init();
    // permissionCheck();
    super.initState();
  }

  Future init() async {
    playlist.clear();
    for (var i in widget.songs) {
      playlist.add(AudioSource.file(i.data,
          tag: MediaItem(
              id: i.id.toString(), title: i.title, artist: i.artist!)));
    }
    audioPlayer.setLoopMode(LoopMode.all);
    audioPlayer.setAudioSource(playlist, initialIndex: widget.selectedSong);
    print(playlist.length);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF144771), Color(0xFF071A2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Music Player'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              StreamBuilder<SequenceState?>(
                  stream: audioPlayer.sequenceStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state != null) {
                      if (state.sequence.isEmpty) {
                        return const SizedBox();
                      } else {
                        final metadata = state.currentSource!.tag ??
                            MediaItem(id: '0', title: 'New');
                        return MetaData(
                          mediaItem: metadata,
                        );
                      }
                    } else {
                      return const SizedBox();
                    }
                  }),
              const SizedBox(
                height: 20,
              ),
              StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data;
                    if (snapshot.data != null) {
                      return ProgressBar(
                        onSeek: audioPlayer.seek,
                        progress: position!.position,
                        total: position.duration,
                        buffered: position.bufferedPosition,
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }),
              const SizedBox(
                height: 20,
              ),
              Controls(audioPlayer: audioPlayer)
            ],
          ),
        ),
      ),
    );
  }
}

class MetaData extends StatelessWidget {
  final MediaItem mediaItem;

  const MetaData({super.key, required this.mediaItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, offset: Offset(2, 4), blurRadius: 4)
              ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: QueryArtworkWidget(
              artworkQuality: FilterQuality.high,
              quality: 100,
              artworkHeight: MediaQuery.sizeOf(context).height * .3,
              artworkWidth: MediaQuery.sizeOf(context).width,
              id: int.parse(mediaItem.id),
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(Icons.music_note),
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          mediaItem.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        Text(
          mediaItem.artist ?? "Unknown",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        )
      ],
    );
  }
}

class Controls extends StatelessWidget {
  final AudioPlayer audioPlayer;

  const Controls({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: audioPlayer.seekToPrevious,
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 80,
        ),
        StreamBuilder(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              } else {
                final playingState = snapshot.data;
                final processingState = playingState!.processingState;
                final playing = playingState.playing;
                if (!(playing)) {
                  return IconButton(
                    onPressed: audioPlayer.play,
                    icon: const Icon(Icons.play_arrow_rounded),
                    color: Colors.white,
                    iconSize: 80,
                  );
                } else if (processingState != ProcessingState.completed) {
                  return IconButton(
                    onPressed: audioPlayer.pause,
                    icon: const Icon(Icons.pause),
                    color: Colors.white,
                    iconSize: 80,
                  );
                } else {
                  return IconButton(
                    onPressed: audioPlayer.play,
                    icon: const Icon(Icons.play_arrow_rounded),
                    color: Colors.white,
                    iconSize: 80,
                  );
                }
              }
            }),
        IconButton(
          onPressed: audioPlayer.seekToNext,
          icon: const Icon(
            Icons.skip_next_rounded,
          ),
          iconSize: 80,
        ),
      ],
    );
  }
}

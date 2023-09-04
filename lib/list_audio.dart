

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'audio_player_screen.dart';

class ListScreen extends StatefulWidget {
  ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );
    _hasPermission ? setState(() {}) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container( decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF144771), Color(0xFF071A2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("OnAudioQueryExample"),
          elevation: 0,
        ),
        body: Center(
          child: !_hasPermission
              ? noAccessToLibraryWidget()
              : FutureBuilder<List<SongModel>>(
            // Default values:
            future: _audioQuery.querySongs(
              sortType: null,
              orderType: OrderType.ASC_OR_SMALLER,
              uriType: UriType.EXTERNAL,
              ignoreCase: true,
            ),
            builder: (context, item) {
              // Display error, if any.
              if (item.hasError) {
                return Text(item.error.toString());
              }

              // Waiting content.
              if (item.data == null) {
                return const CircularProgressIndicator();
              }

              // 'Library' is empty.
              if (item.data!.isEmpty) return const Text("Nothing found!");

              return ListView.builder(
                itemCount: item.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AudioPlayerScreen(songs: item.data!, selectedSong: index,))),
                    title: Text(item.data![index].title),
                    subtitle: Text(item.data![index].artist ?? "No Artist"),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    leading: QueryArtworkWidget(
                      controller: _audioQuery,
                      id: item.data![index].id,
                      type: ArtworkType.AUDIO,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
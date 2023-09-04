import 'package:bg_media_player/audio_player_screen.dart';
import 'package:bg_media_player/list_audio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future main() async {
  await JustAudioBackground.init(
    androidNotificationOngoing: true,
    androidNotificationChannelId: 'com.example.bg_media_player',
    androidNotificationChannelName: 'Media Player'
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: ListScreen(),
    );
  }
}

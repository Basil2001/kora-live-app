import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kora/features/matches/video_player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock the video_player plugin method channel to prevent MissingPluginException
    const MethodChannel channel = MethodChannel('flutter.io/videoPlayer');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'init':
          return null;
        case 'create':
          return {'textureId': 1};
        case 'initialize':
          return null;
        case 'dispose':
          return null;
        default:
          return null;
      }
    });
  });

  testWidgets('VideoPlayerScreen renders title and secure playback banner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VideoPlayerScreen(
          videoUrl: 'https://example.com/stream.m3u8',
          title: 'El Clásico Live Stream',
        ),
      ),
    );

    // Verify the title is rendered in both the AppBar and description body
    expect(find.text('El Clásico Live Stream'), findsNWidgets(2));

    // Verify secure playback text banner is rendered
    expect(find.text('SECURE PLAYBACK ACTIVE'), findsOneWidget);

    // Verify loading indicator is displayed initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

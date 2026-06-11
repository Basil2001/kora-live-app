import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/matches/match_detail_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/standings/standings_screen.dart';
import '../../features/matches/video_player_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/match/:id',
        builder: (context, state) {
          final idString = state.pathParameters['id'] ?? '0';
          final matchId = int.tryParse(idString) ?? 0;
          return MatchDetailScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),
      GoRoute(
        path: '/standings',
        builder: (context, state) => const StandingsScreen(),
      ),
      GoRoute(
        path: '/watch',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Video Playback';
          return VideoPlayerScreen(videoUrl: url, title: title);
        },
      ),
    ],
  );
}

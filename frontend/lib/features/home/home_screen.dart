import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../matches/matches_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/favorites_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../notifications/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(notificationsProvider.notifier).fetchNotifications();
        ref.read(notificationServiceProvider).init();
        ref.read(notificationServiceProvider).requestPermissionAndRegisterToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        ref.read(notificationsProvider.notifier).fetchNotifications();
        ref.read(notificationServiceProvider).init();
        ref.read(notificationServiceProvider).requestPermissionAndRegisterToken();
      }
    });

    final matchesAsync = ref.watch(matchesProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final favorites = favoritesAsync.value ?? {};
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context);
    final unreadCount = authState.isAuthenticated ? ref.watch(unreadNotificationsCountProvider) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('app_title')),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  if (!authState.isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.get('login_required_filter')),
                        backgroundColor: AppTheme.accentCrimson,
                      ),
                    );
                    return;
                  }
                  context.push('/notifications');
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: AppTheme.darkBackground,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: AppTheme.darkSurface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppTheme.darkSurfaceCard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentGreen,
                      radius: 30,
                      child: authState.isAuthenticated && authState.avatarUrl != null
                          ? Text(
                              authState.avatarUrl!,
                              style: const TextStyle(fontSize: 32),
                            )
                          : const Icon(Icons.person, color: AppTheme.darkBackground, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authState.isAuthenticated
                          ? '${localizations.get('welcome')}, ${authState.name}'
                          : '${localizations.get('welcome')} (${localizations.get('guest_mode')})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: AppTheme.accentGreen),
                title: Text(localizations.get('home')),
                onTap: () => context.pop(),
              ),
              if (authState.isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                  title: Text(localizations.get('profile')),
                  onTap: () {
                    context.pop();
                    context.push('/profile');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.article_outlined, color: AppTheme.textSecondary),
                title: Text(localizations.get('news')),
                onTap: () {
                  context.pop();
                  context.push('/news');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined, color: AppTheme.textSecondary),
                title: Text(localizations.get('standings')),
                onTap: () {
                  context.pop();
                  context.push('/standings');
                },
              ),
              ListTile(
                leading: Icon(
                  ref.watch(themeProvider) == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: AppTheme.accentAmber,
                ),
                title: Text(localizations.get('toggle_theme')),
                trailing: Switch(
                  value: ref.watch(themeProvider) == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                  activeThumbColor: AppTheme.accentGreen,
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.dark_mode, size: 14, color: Colors.black);
                    }
                    return const Icon(Icons.light_mode, size: 14, color: Colors.white);
                  }),
                ),
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.textSecondary),
                title: Text(localizations.get('switch_language')),
                trailing: Text(
                  locale.languageCode == 'en' ? 'العربية' : 'English',
                  style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  final nextLocale = locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
                  ref.read(localeProvider.notifier).state = nextLocale;
                },
              ),
              const Divider(color: AppTheme.borderGrey),
              if (authState.isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.accentCrimson),
                  title: Text(localizations.get('sign_out')),
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.pop();
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.accentGreen),
                  title: Text(localizations.get('sign_in')),
                  onTap: () {
                    context.pop();
                    context.push('/login');
                  },
                ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesProvider.notifier).fetchMatches('2026-05-29'),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Top Highlights Promo Banner
            _buildHighlightsPromoBanner(context, localizations),
            const SizedBox(height: 24),

            // Section: Today's Matches Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.get('todays_matches'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.accentGreen),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Favorites Filter Toggle Chip Row
            Align(
              alignment: Alignment.centerLeft,
              child: ChoiceChip(
                avatar: Icon(
                  _showOnlyFavorites ? Icons.star : Icons.star_border,
                  color: _showOnlyFavorites ? AppTheme.darkBackground : AppTheme.accentAmber,
                  size: 16,
                ),
                label: Text(localizations.get('my_teams_only')),
                selected: _showOnlyFavorites,
                selectedColor: AppTheme.accentGreen,
                backgroundColor: AppTheme.darkSurfaceCard,
                labelStyle: TextStyle(
                  color: _showOnlyFavorites ? AppTheme.darkBackground : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (!authState.isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.get('login_required_filter')),
                        backgroundColor: AppTheme.accentCrimson,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _showOnlyFavorites = selected;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Matches Async Builder
            matchesAsync.when(
              data: (matches) {
                final displayedMatches = _showOnlyFavorites
                    ? matches
                        .where((m) =>
                            favorites.contains(m.homeTeamId) ||
                            favorites.contains(m.awayTeamId))
                        .toList()
                    : matches;

                if (displayedMatches.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _showOnlyFavorites
                            ? localizations.get('no_fav_matches')
                            : localizations.get('no_matches'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedMatches.length,
                  itemBuilder: (context, index) {
                    final match = displayedMatches[index];
                    return MatchCard(
                      match: match,
                      onTap: () => context.push('/match/${match.id}'),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: ShimmerLoading(width: double.infinity, height: 120),
                ),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading matches: $err'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            context.push('/news');
          } else if (index == 2) {
            context.push('/standings');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_soccer),
            label: localizations.get('matches_label'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_outlined),
            label: localizations.get('news_label'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.table_chart_outlined),
            label: localizations.get('standings_label'),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsPromoBanner(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.accentMint, AppTheme.darkSurfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentMint.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.sports_soccer_outlined,
              size: 180,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    localizations.get('exclusive_streaming'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.get('promo_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.get('promo_subtitle'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../matches/matches_provider.dart';
import '../matches/comments_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/share_button.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final int matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchDetailsAsync = ref.watch(matchDetailsProvider(widget.matchId));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('match_center')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: matchDetailsAsync.maybeWhen(
              data: (match) => ShareButton(
                title: '${match.homeTeam} vs ${match.awayTeam}',
                subtitle: '${match.scoreHome} - ${match.scoreAway} | ${match.competition}',
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: matchDetailsAsync.when(
        data: (match) => Column(
          children: [
            // Core Match Hero Header
            _buildMatchHeroHeader(match, localizations),
            
            // Tab Header Control Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentGreen,
              labelColor: AppTheme.accentGreen,
              unselectedLabelColor: AppTheme.textSecondary,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: localizations.get('timeline')),
                Tab(text: localizations.get('lineups')),
                Tab(text: localizations.get('streaming')),
                Tab(text: localizations.get('comments')),
              ],
            ),
            
            // Core Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimelineTab(match, localizations),
                  _buildLineupsTab(match, localizations),
                  _buildStreamingTab(match, localizations),
                  _buildCommentsTab(match, localizations),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGreen),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildMatchHeroHeader(MatchModel match, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 1)),
      ),
      child: Column(
        children: [
          Text(
            match.competition,
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home team display
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      match.homeLogo,
                      height: 64,
                      width: 64,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, size: 64, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Scores Center details
              Column(
                children: [
                  if (match.status != 'scheduled') ...[
                    Text(
                      '${match.scoreHome} - ${match.scoreAway}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: match.status == 'live' ? AppTheme.accentCrimson : AppTheme.accentMint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.status == 'live'
                            ? "${localizations.get('live_status')} ${match.currentMinute}'"
                            : localizations.get('finished_status'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'VS',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.startTime,
                      style: const TextStyle(fontSize: 14, color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),

              // Away team display
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      match.awayLogo,
                      height: 64,
                      width: 64,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, size: 64, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(MatchModel match, AppLocalizations localizations) {
    if (match.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer_outlined,
                  size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                localizations.get('no_events'),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: match.events.length,
      itemBuilder: (context, index) {
        final event = match.events[index];
        final isHomeTeam = event['team_name'] == match.homeTeam;
        // Staggered entrance: each card delays by 60ms × its index
        final delay = Duration(milliseconds: 60 * index);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          // Re-trigger animation per item by using a unique key
          key: ValueKey('event_$index'),
          builder: (context, value, child) {
            // Apply delay by using the animation value only after delay fraction
            final delayFraction = delay.inMilliseconds / 2000.0;
            final animValue = ((value - delayFraction) / (1.0 - delayFraction)).clamp(0.0, 1.0);
            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(isHomeTeam ? -20 * (1 - animValue) : 20 * (1 - animValue), 0),
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisAlignment:
                isHomeTeam ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!isHomeTeam) const Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceCard,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isHomeTeam ? 4 : 12),
                    topRight: Radius.circular(isHomeTeam ? 12 : 4),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkBackground.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHomeTeam) ...[
                      _buildEventIcon(event),
                      const SizedBox(width: 10),
                    ],
                    _buildEventContent(event, localizations),
                    if (!isHomeTeam) ...[
                      const SizedBox(width: 10),
                      _buildEventIcon(event),
                    ],
                  ],
                ),
              ),
              if (isHomeTeam) const Spacer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventIcon(Map<String, dynamic> event) {
    final isGoal = event['type'] == 'goal';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isGoal
            ? AppTheme.accentGreen.withValues(alpha: 0.15)
            : AppTheme.accentAmber.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isGoal ? Icons.sports_soccer : Icons.bookmark,
        color: isGoal ? AppTheme.accentGreen : AppTheme.accentAmber,
        size: 14,
      ),
    );
  }

  Widget _buildEventContent(Map<String, dynamic> event, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${event['minute']}'",
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              event['player_name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (event['detail_player_name'] != null) ...[
          const SizedBox(height: 3),
          Text(
            '${localizations.get('assist')}: ${event['detail_player_name']}',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineupsTab(MatchModel match, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.get('starting_xi'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // Home Starting XI mockup list
          _buildTeamLineupsList(match.homeTeam, [
            'Courtois (GK)',
            'Carvajal',
            'Rüdiger',
            'Militão',
            'Mendy',
            'Valverde',
            'Tchouaméni',
            'Bellingham',
            'Rodrygo',
            'Mbappé',
            'Vinícius Jr.'
          ]),
          const Divider(height: 32, color: AppTheme.borderGrey),
          // Away Starting XI mockup list
          _buildTeamLineupsList(match.awayTeam, [
            'Ter Stegen (GK)',
            'Koundé',
            'Araújo',
            'Cubarsí',
            'Cancelo',
            'Christensen',
            'Gavi',
            'Gündoğan',
            'Yamal',
            'Lewandowski',
            'Raphinha'
          ]),
        ],
      ),
    );
  }

  Widget _buildTeamLineupsList(String teamName, List<String> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 24),
                Text(players[index], style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingTab(MatchModel match, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.live_tv,
            size: 80,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.get('secure_legal_ott'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.get('ott_details'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final authState = ref.read(authProvider);
              // Capture messenger and router before any async gap
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);

              if (!authState.isAuthenticated) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(localizations.get('login_required_filter')),
                    backgroundColor: AppTheme.accentCrimson,
                  ),
                );
                return;
              }

              messenger.showSnackBar(
                SnackBar(
                  content: Text(localizations.get('validating_token')),
                  backgroundColor: AppTheme.accentMint,
                ),
              );

              try {
                final client = ref.read(apiClientProvider);
                final response = await client.get('/matches/${match.id}/stream');
                if (response.statusCode == 200) {
                  final data = response.data;
                  final streamUrl = data['stream_url'] as String;
                  router.push(
                    Uri(
                      path: '/watch',
                      queryParameters: {
                        'url': streamUrl,
                        'title': '${match.homeTeam} vs ${match.awayTeam} - Live',
                      },
                    ).toString(),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${localizations.get('stream_link_failed')}: $e'),
                    backgroundColor: AppTheme.accentCrimson,
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(localizations.get('watch_stream')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.darkBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(MatchModel match, AppLocalizations localizations) {
    final commentsState = ref.watch(commentsProvider(match.id));
    final authState = ref.watch(authProvider);
    final textController = TextEditingController();

    return Column(
      children: [
        // Comment input box (only for authenticated users)
        if (authState.isAuthenticated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.accentGreen,
                  child: Text(
                    authState.name?.isNotEmpty == true
                        ? authState.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.darkBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: localizations.get('write_comment'),
                      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.darkSurfaceCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                commentsState.isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentGreen,
                        ),
                      )
                    : IconButton(
                        onPressed: () async {
                          final body = textController.text.trim();
                          if (body.isEmpty) return;
                          final success = await ref
                              .read(commentsProvider(match.id).notifier)
                              .postComment(body);
                          if (success) textController.clear();
                        },
                        icon: const Icon(Icons.send_rounded, color: AppTheme.accentGreen),
                        tooltip: localizations.get('send'),
                      ),
              ],
            ),
          ),

        // Comment list
        Expanded(
          child: commentsState.isLoading && commentsState.comments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGreen),
                )
              : commentsState.comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            localizations.get('no_comments'),
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accentGreen,
                      onRefresh: () => ref
                          .read(commentsProvider(match.id).notifier)
                          .fetchComments(refresh: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: commentsState.comments.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppTheme.borderGrey, height: 1),
                        itemBuilder: (context, index) {
                          final comment = commentsState.comments[index];
                          final isOwn = authState.isAuthenticated &&
                              comment.userId == authState.userId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.accentMint,
                              child: Text(
                                comment.userName.isNotEmpty
                                    ? comment.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  comment.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (comment.isPinned) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.push_pin,
                                      size: 12, color: AppTheme.accentAmber),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  comment.body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Like button
                                GestureDetector(
                                  onTap: authState.isAuthenticated
                                      ? () => ref
                                          .read(commentsProvider(match.id).notifier)
                                          .likeComment(comment.id)
                                      : null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_border,
                                          size: 14, color: AppTheme.accentCrimson),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${comment.likesCount}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete (own only)
                                if (isOwn) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => ref
                                        .read(commentsProvider(match.id).notifier)
                                        .deleteComment(comment.id),
                                    child: const Icon(Icons.delete_outline,
                                        size: 14, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import 'notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final notificationsState = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C24),
        title: Text(
          localizations.get('notifications'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showPreferencesBottomSheet(context),
            tooltip: localizations.get('notification_preferences'),
          ),
          if (notificationsState.items.any((e) => !e.isRead))
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFF00E676)),
              onPressed: () => notifier.markAllAsRead(),
              tooltip: localizations.get('mark_all_read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchNotifications(),
        color: const Color(0xFF00E676),
        backgroundColor: const Color(0xFF151C24),
        child: notificationsState.isLoading && notificationsState.items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                ),
              )
            : notificationsState.items.isEmpty
                ? _buildEmptyState(context, localizations)
                : _buildNotificationsList(notificationsState.items, notifier, localizations),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations localizations) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.get('no_notifications'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(
    List<AppNotificationModel> items,
    NotificationsNotifier notifier,
    AppLocalizations localizations,
  ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF151C24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead
                  ? Colors.transparent
                  : const Color(0xFF00E676).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _getNotificationIcon(item.type),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ),
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (!item.isRead) {
                notifier.markAsRead(item.id);
              }
              _handleNotificationTap(item);
            },
          ),
        );
      },
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        color = const Color(0xFF00E676);
        break;
      case 'match_start':
        icon = Icons.play_circle_outline;
        color = Colors.blue;
        break;
      case 'match_end':
        icon = Icons.stop_circle_outlined;
        color = Colors.red;
        break;
      case 'news':
        icon = Icons.article_outlined;
        color = Colors.amber;
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = Colors.purpleAccent;
        break;
      default:
        icon = Icons.notifications_none_outlined;
        color = Colors.white60;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNotificationTap(AppNotificationModel item) {
    // If notification has extra parameters, perform redirection
    if (item.data != null) {
      final matchId = item.data!['match_id'];
      if (matchId != null) {
        // Redirect to match detail screen
        // In Flutter, using GoRouter: context.push('/match/$matchId')
      }
    }
  }

  void _showPreferencesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const NotificationPreferencesWidget();
      },
    );
  }
}

class NotificationPreferencesWidget extends ConsumerWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final prefsState = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      child: prefsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error loading preferences: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (prefs) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.get('notification_preferences'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: localizations.get('notification_goals'),
                value: prefs.goals,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(goals: val));
                },
              ),
              _buildSwitchTile(
                title: localizations.get('notification_match_start'),
                value: prefs.matchStart,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(matchStart: val));
                },
              ),
              _buildSwitchTile(
                title: localizations.get('notification_match_end'),
                value: prefs.matchEnd,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(matchEnd: val));
                },
              ),
              _buildSwitchTile(
                title: localizations.get('notification_news'),
                value: prefs.news,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(news: val));
                },
              ),
              _buildSwitchTile(
                title: localizations.get('notification_promo'),
                value: prefs.promotions,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(promotions: val));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00E676),
      activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.3),
      inactiveThumbColor: Colors.white60,
      inactiveTrackColor: Colors.white12,
      contentPadding: EdgeInsets.zero,
    );
  }
}

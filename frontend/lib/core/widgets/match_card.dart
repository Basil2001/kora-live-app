import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_theme.dart';
import '../../features/matches/matches_provider.dart';

class MatchCard extends StatefulWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Only animate when match is live
    if (widget.match.status == 'live') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subtle entrance scale-up animation
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // League/Competition Info Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.match.competition,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusBadge(),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          color: AppTheme.accentGreen,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () {
                            final scoreStr = widget.match.status == 'scheduled'
                                ? widget.match.startTime
                                : '${widget.match.scoreHome}-${widget.match.scoreAway}';
                            final text = '⚽ ${widget.match.homeTeam} $scoreStr ${widget.match.awayTeam} | ${widget.match.competition} | Kora App 🏆';
                            Share.share(text);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Team Logos and Score Row
                Row(
                  children: [
                    // Home Team
                    Expanded(
                      child: Column(
                        children: [
                          Image.network(
                            widget.match.homeLogo,
                            height: 48,
                            width: 48,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shield,
                                    size: 48,
                                    color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.match.homeTeam,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // Score / Time Center
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: widget.match.status == 'scheduled'
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.match.startTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.accentGreen,
                                      fontSize: 16,
                                    ),
                              ),
                            )
                          : Row(
                              children: [
                                Text(
                                  '${widget.match.scoreHome}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: widget.match.status == 'live'
                                            ? AppTheme.accentGreen
                                            : AppTheme.textPrimary,
                                      ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(':',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  '${widget.match.scoreAway}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: widget.match.status == 'live'
                                            ? AppTheme.accentGreen
                                            : AppTheme.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                    ),

                    // Away Team
                    Expanded(
                      child: Column(
                        children: [
                          Image.network(
                            widget.match.awayLogo,
                            height: 48,
                            width: 48,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shield,
                                    size: 48,
                                    color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.match.awayTeam,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Minute indicator if live
                if (widget.match.status == 'live') ...[
                  const SizedBox(height: 12),
                  Text(
                    "${widget.match.currentMinute}'",
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;

    if (widget.match.status == 'live') {
      badgeColor = AppTheme.accentCrimson;
      badgeText = 'LIVE';
    } else if (widget.match.status == 'finished') {
      badgeColor = AppTheme.accentMint;
      badgeText = 'FT';
    } else {
      badgeColor = AppTheme.textSecondary;
      badgeText = 'SCH';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.match.status == 'live') ...[
            // Animated pulsing dot for LIVE matches
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

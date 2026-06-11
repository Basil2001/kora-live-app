import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_theme.dart';

/// A premium share button that invokes the native share sheet.
class ShareButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? url;

  const ShareButton({
    super.key,
    required this.title,
    required this.subtitle,
    this.url,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _controller.reverse();
    await _controller.forward();

    final shareText = widget.url != null
        ? '${widget.title}\n${widget.subtitle}\n\n${widget.url}'
        : '${widget.title}\n${widget.subtitle}\n\nWatching via Kora Live 🏆';

    await Share.share(
      shareText,
      subject: widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share_outlined,
                size: 16,
                color: AppTheme.accentGreen,
              ),
              SizedBox(width: 6),
              Text(
                'Share',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

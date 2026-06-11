import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'news_provider.dart';
import '../../core/localization/app_localizations.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('news_highlights_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Highlights Section (Video cards)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                localizations.get('video_highlights'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              height: 180,
              child: highlightsAsync.when(
                data: (highlights) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = highlights[index];
                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            context.push(
                              Uri(
                                path: '/watch',
                                queryParameters: {
                                  'url': highlight.videoUrl,
                                  'title': highlight.title,
                                },
                              ).toString(),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                highlight.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: AppTheme.darkSurfaceCard),
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 48,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Text(
                                  highlight.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 2,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: ShimmerLoading(width: 260, height: 180),
                  ),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),

            const SizedBox(height: 24),

            // Trending News Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                localizations.get('trending_news'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            
            newsAsync.when(
              data: (articles) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${localizations.get('watch')}: ${article.title}')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                article.imageUrl,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: AppTheme.darkSurface, height: 80, width: 80),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      article.category.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.publishedAt,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 2,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: ShimmerLoading(width: double.infinity, height: 100),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

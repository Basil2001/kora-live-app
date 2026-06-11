import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class ArticleModel {
  final int id;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final String imageUrl;
  final String category;
  final String publishedAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.body,
    required this.bodyAr,
    required this.imageUrl,
    required this.category,
    required this.publishedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      titleAr: json['title_ar'] ?? '',
      body: json['body'] ?? '',
      bodyAr: json['body_ar'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'General',
      publishedAt: json['published_at'] ?? '',
    );
  }
}

class HighlightModel {
  final int id;
  final String title;
  final String titleAr;
  final String videoUrl;
  final String thumbnailUrl;

  HighlightModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      titleAr: json['title_ar'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}

final newsProvider = FutureProvider<List<ArticleModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/news');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => ArticleModel.fromJson(e)).toList();
  } catch (e) {
    return [
      ArticleModel(
        id: 1,
        title: 'Real Madrid Clinches Thrilling El Clásico Victory',
        titleAr: 'ريال مدريد يحسم كلاسيكو الأرض بفوز مثير',
        body: 'In an action-packed match at the Santiago Bernabéu, Real Madrid defeated Barcelona 2-1.',
        bodyAr: 'في مباراة مليئة بالإثارة على ملعب سانتياغو برنابيو، تغلب ريال مدريد على برشلونة بنتيجة 2-1.',
        imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=800',
        category: 'La Liga',
        publishedAt: '2 hours ago',
      ),
      ArticleModel(
        id: 2,
        title: 'Al Ahly Dominates Cairo Derby Against Zamalek',
        titleAr: 'الأهلي يسيطر على ديربي القاهرة ويفوز على الزمالك',
        body: 'Egyptian Premier League leaders Al Ahly secure a comfortable 2-0 victory against rivals Zamalek.',
        bodyAr: 'حقق الأهلي متصدر الدوري المصري الممتاز فوزاً مريحاً بنتيجة 2-0 على غريمه التقليدي الزمالك.',
        imageUrl: 'https://images.unsplash.com/photo-1540747737956-37872404a821?q=80&w=800',
        category: 'Egyptian Premier League',
        publishedAt: '5 hours ago',
      ),
    ];
  }
});

final highlightsProvider = FutureProvider<List<HighlightModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/highlights');
    final List<dynamic> data = response.data;
    return data.map((e) => HighlightModel.fromJson(e)).toList();
  } catch (e) {
    return [
      HighlightModel(
        id: 1,
        title: 'Real Madrid vs FC Barcelona (2-1) Highlights',
        titleAr: 'ملخص مباراة ريال مدريد وبرشلونة (2-1)',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        thumbnailUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=800',
      ),
      HighlightModel(
        id: 2,
        title: 'Al Ahly vs Zamalek SC (2-0) Highlights',
        titleAr: 'ملخص مباراة الأهلي والزمالك (2-0)',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        thumbnailUrl: 'https://images.unsplash.com/photo-1540747737956-37872404a821?q=80&w=800',
      ),
    ];
  }
});

<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Article;
use App\Models\Highlight;
use Illuminate\Support\Carbon;

class NewsController extends Controller
{
    public function index(Request $request)
    {
        $this->seedNewsIfEmpty();

        $articles = Article::where('status', 'published')
            ->orderBy('published_at', 'desc')
            ->paginate(10);

        return response()->json($articles);
    }

    public function showBySlug($slug)
    {
        $article = Article::where('slug', $slug)->firstOrFail();
        return response()->json($article);
    }

    public function highlights()
    {
        $this->seedHighlightsIfEmpty();

        $highlights = Highlight::with('match.homeTeam', 'match.awayTeam')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($highlights);
    }

    private function seedNewsIfEmpty()
    {
        if (Article::count() > 0) return;

        Article::create([
            'title' => 'Real Madrid Clinches Thrilling El Clásico Victory',
            'title_ar' => 'ريال مدريد يحسم كلاسيكو الأرض بفوز مثير',
            'slug' => 'real-madrid-clinches-thrilling-el-clasico-victory',
            'body' => 'In an action-packed match at the Santiago Bernabéu, Real Madrid defeated Barcelona 2-1. Kylian Mbappé scored the winning goal in the 55th minute after an incredible assist from Federico Valverde.',
            'body_ar' => 'في مباراة مليئة بالإثارة على ملعب سانتياغو برنابيو، تغلب ريال مدريد على برشلونة بنتيجة 2-1. وسجل كيليان مبابي هدف الفوز في الدقيقة 55 بعد تمريرة حاسمة رائعة من فيديريكو فالفيردي.',
            'image_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=800',
            'status' => 'published',
            'category' => 'La Liga',
            'published_at' => Carbon::now()->subHours(2),
        ]);

        Article::create([
            'title' => 'Al Ahly Dominates Cairo Derby Against Zamalek',
            'title_ar' => 'الأهلي يسيطر على ديربي القاهرة ويفوز على الزمالك',
            'slug' => 'al-ahly-dominates-cairo-derby-against-zamalek',
            'body' => 'Egyptian Premier League leaders Al Ahly secure a comfortable 2-0 victory against rivals Zamalek. Hussein El Shahat and Wessam Abou Ali were the goalscorers.',
            'body_ar' => 'حقق الأهلي متصدر الدوري المصري الممتاز فوزاً مريحاً بنتيجة 2-0 على غريمه التقليدي الزمالك. سجل الأهداف حسين الشحات ووسام أبو علي.',
            'image_url' => 'https://images.unsplash.com/photo-1540747737956-37872404a821?q=80&w=800',
            'status' => 'published',
            'category' => 'Egyptian Premier League',
            'published_at' => Carbon::now()->subHours(5),
        ]);
    }

    private function seedHighlightsIfEmpty()
    {
        if (Highlight::count() > 0) return;

        Highlight::create([
            'title' => 'Real Madrid vs FC Barcelona (2-1) Highlights',
            'title_ar' => 'ملخص مباراة ريال مدريد وبرشلونة (2-1)',
            'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            'thumbnail_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=800',
            'access_level' => 'free',
        ]);

        Highlight::create([
            'title' => 'Al Ahly vs Zamalek SC (2-0) Highlights',
            'title_ar' => 'ملخص مباراة الأهلي والزمالك (2-0)',
            'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            'thumbnail_url' => 'https://images.unsplash.com/photo-1540747737956-37872404a821?q=80&w=800',
            'access_level' => 'free',
        ]);
    }
}

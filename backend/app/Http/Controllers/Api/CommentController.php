<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Comment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    /**
     * List comments for a given match (latest first, paginated).
     */
    public function index(Request $request, int $matchId): JsonResponse
    {
        $comments = Comment::with('user:id,name,avatar_url')
            ->where('match_id', $matchId)
            ->orderByDesc('is_pinned')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json([
            'comments' => $comments->items(),
            'total' => $comments->total(),
            'current_page' => $comments->currentPage(),
            'last_page' => $comments->lastPage(),
        ]);
    }

    /**
     * Post a new comment on a match.
     */
    public function store(Request $request, int $matchId): JsonResponse
    {
        $validated = $request->validate([
            'body' => 'required|string|min:1|max:500',
        ]);

        $comment = Comment::create([
            'user_id' => $request->user()->id,
            'match_id' => $matchId,
            'body' => $validated['body'],
        ]);

        $comment->load('user:id,name,avatar_url');

        return response()->json([
            'message' => 'Comment posted successfully.',
            'comment' => $comment,
        ], 201);
    }

    /**
     * Delete own comment.
     */
    public function destroy(Request $request, int $matchId, int $commentId): JsonResponse
    {
        $comment = Comment::where('id', $commentId)
            ->where('match_id', $matchId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $comment->delete();

        return response()->json(['message' => 'Comment deleted.']);
    }

    /**
     * Like a comment (increment counter).
     */
    public function like(Request $request, int $matchId, int $commentId): JsonResponse
    {
        $comment = Comment::where('id', $commentId)
            ->where('match_id', $matchId)
            ->firstOrFail();

        $comment->increment('likes_count');

        return response()->json([
            'message' => 'Liked!',
            'likes_count' => $comment->likes_count,
        ]);
    }
}

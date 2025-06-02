import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/board_game.dart';

class BoardGameCard extends StatelessWidget {
  final BoardGame game;

  const BoardGameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          (game.imageUrl.isNotEmpty ? game.imageUrl : game.thumbnailUrl)
                  .isNotEmpty
              ? CachedNetworkImage(
                imageUrl:
                    game.imageUrl.isNotEmpty
                        ? game.imageUrl
                        : game.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
              )
              : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
          // Gradient overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Game information overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game name
                  Text(
                    game.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Game details
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        game.playerCountText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        game.playingTimeText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.child_care,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        game.ageText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        game.weightText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  // Best with player count
                  if (game.playerCountRecommendations
                      .getBestWithText()
                      .isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      game.playerCountRecommendations.getBestWithText(),
                      style: TextStyle(
                        color: Colors.yellow.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Recommended with player count
                  if (game.playerCountRecommendations
                          .getRecommendedWithText()
                          .isNotEmpty &&
                      game.playerCountRecommendations.getBestWithText() !=
                          game.playerCountRecommendations
                              .getRecommendedWithText()) ...[
                    const SizedBox(height: 1),
                    Text(
                      game.playerCountRecommendations.getRecommendedWithText(),
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.9),
                        fontSize: 8,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

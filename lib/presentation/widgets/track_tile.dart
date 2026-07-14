import 'package:flutter/material.dart';
import '../../domain/entities/video.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isCurrent;
  final bool isDownloaded;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onMore;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TrackTile({
    super.key,
    required this.track,
    this.isCurrent = false,
    this.isDownloaded = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onMore,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 50,
          height: 50,
          child: track.thumbnailUrl == null
              ? Container(
                  color: const Color(0xFF252525),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white38,
                  ),
                )
              : Image.network(
                  track.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF252525),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white38,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isCurrent ? theme.colorScheme.primary : Colors.white,
        ),
      ),
      subtitle: Row(
        children: [
          if (isDownloaded) ...[
            const Icon(
              Icons.offline_pin_rounded,
              size: 13,
              color: Colors.white54,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              track.author ?? 'YouTube',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite
                    ? const Color(0xFFFF7FA4)
                    : Colors.white54,
                size: 20,
              ),
              onPressed: onToggleFavorite,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Remove from Offline',
              onPressed: onDelete,
            ),
          if (onMore != null)
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: onMore,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

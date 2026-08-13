import 'package:flutter/material.dart';

class SongArtwork extends StatelessWidget {
  const SongArtwork({
    required this.url,
    this.size = 56,
    this.borderRadius = 14,
    super.key,
  });

  final String? url;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: size * 0.42,
        ),
      ),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox.square(
          dimension: size,
          child: url == null || url!.isEmpty
              ? placeholder
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}

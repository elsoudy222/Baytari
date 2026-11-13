/// The photo grid of a report post (Figma's Home feed).
///
/// Layout follows the photo count, exactly like Figma:
/// - 0 photos: nothing.
/// - 1 photo: full-width, fixed height.
/// - 2 photos: two side-by-side.
/// - 3 or more: three side-by-side; when there are more than 3,
///   the last tile shows a "+N" overlay (N = the hidden count).
/// Tapping a photo does nothing in this stage (no full-screen
/// viewer yet).
library;

import 'package:flutter/material.dart';

class ReportPhotoGrid extends StatelessWidget {
  const ReportPhotoGrid({required this.photoUrls, super.key});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    if (photoUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _Photo(url: photoUrls.first, height: 200),
      );
    }
    final int shown = photoUrls.length > 3 ? 3 : photoUrls.length;
    final int hidden = photoUrls.length - shown;
    return Row(
      children: <Widget>[
        for (int i = 0; i < shown; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
                right: i == shown - 1 ? 0 : 4,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    _Photo(url: photoUrls[i], height: 120),
                    // "+N" overlay on the last visible tile when
                    // more photos are hidden behind it.
                    if (i == shown - 1 && hidden > 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Text(
                            '+ $hidden',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One network photo with a spinner while loading and a broken
/// icon when the URL fails (a bad photo must never break the
/// whole feed).
class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}

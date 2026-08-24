import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:user_app/core/utils/media_url.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  Widget get _fallback =>
      errorWidget ??
      Container(
        width: width,
        height: height,
        color: const Color(0xFFF0F0F0),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrl.resolve(url);
    if (resolved == null) return _fallback;

    if (MediaUrl.isSvg(resolved)) {
      return SvgPicture.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => _fallback,
        errorBuilder: (_, _, _) => _fallback,
      );
    }

    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}

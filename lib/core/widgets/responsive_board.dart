import 'package:flutter/material.dart';

/// 居中的自适应棋盘容器。
///
/// API 36 起 600dp 以上大屏不允许锁定方向，因此棋盘尺寸
/// 必须由可用空间推导，不能假设竖屏或固定尺寸。
class ResponsiveBoard extends StatelessWidget {
  const ResponsiveBoard({
    super.key,
    required this.child,
    this.maxSize = 520,
    this.aspectRatio = 1,
  });

  final Widget child;
  final double maxSize;

  /// 宽高比，宽除以高。
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.biggest;
          var width = available.width;
          var height = width / aspectRatio;
          if (height > available.height) {
            height = available.height;
            width = height * aspectRatio;
          }
          if (width > maxSize) {
            width = maxSize;
            height = maxSize / aspectRatio;
          }
          return SizedBox(width: width, height: height, child: child);
        },
      ),
    );
  }
}

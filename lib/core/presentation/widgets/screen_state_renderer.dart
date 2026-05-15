import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/core/component/app_button.dart';
import 'package:manus/core/presentation/state/screen_state.dart';

class ScreenStateRenderer<T> extends StatelessWidget {
  final ScreenState<T> state;
  final Widget Function(BuildContext context, T data, bool isLoadingMore)
  itemBuilder;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final Widget? loadingWidget;
  final Widget Function(String)? errorWidgetBuilder;

  const ScreenStateRenderer({
    super.key,
    required this.state,
    required this.itemBuilder,
    this.onRetry,
    this.onRefresh,
    this.onLoadMore,
    this.loadingWidget,
    this.errorWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == ScreenStatus.loading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    } else if (state.status == ScreenStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48.w),
            SizedBox(height: 16.h),
            Text(
              state.error ?? 'Unknown error',
              style: TextStyle(fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              AppButton(label: 'Retry', onTap: onRetry),
            ],
          ],
        ),
      );
    } else if (state.status == ScreenStatus.loaded) {
      if (state.data == null) {
        return const SizedBox.shrink();
      }

      final content = NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (onLoadMore != null &&
              !state.isLoadingMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            onLoadMore!();
          }
          return false;
        },
        child: itemBuilder(context, state.data as T, state.isLoadingMore),
      );

      if (onRefresh != null) {
        return RefreshIndicator(
          onRefresh: () async => onRefresh!(),
          child: content,
        );
      }
      return content;
    }

    return const SizedBox.shrink();
  }
}

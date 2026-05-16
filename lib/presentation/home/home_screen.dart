import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/core/presentation/state/screen_state.dart';
import 'package:manus/core/presentation/widgets/screen_state_renderer.dart';
import 'package:manus/domain/entities/product.dart';
import 'package:manus/presentation/home/notifier/product_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products (Offline First)')),
      body: _buildBody(context, ref, state.screenState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScreenState<List<Product>> state,
  ) {
    final notifier = ref.read(productProvider.notifier);
    return ScreenStateRenderer<List<Product>>(
      state: state,
      onRetry: notifier.loadProducts,
      onRefresh: notifier.loadProducts,
      onLoadMore: notifier.loadMoreProducts,
      itemBuilder: (context, products, isLoadingMore) {
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: products.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            if (isLoadingMore && index == products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final product = products[index];
            return Card(
              elevation: 2,
              child: ListTile(
                leading: Image.network(
                  product.thumbnail,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.image_not_supported, size: 50.w),
                ),
                title: Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '\$${product.price}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

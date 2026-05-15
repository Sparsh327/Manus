import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/core/presentation/state/screen_state.dart';
import 'package:manus/data/providers/product_data_providers.dart';
import 'package:manus/domain/entities/product.dart';
import 'package:manus/presentation/home/notifier/product_state.dart';

final productProvider = NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);

class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    Future.microtask(loadProducts);
    return const ProductState();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(screenState: ScreenState.loading());
    final result = await ref.read(productRepositoryProvider).getProducts();
    result.fold(
      (failure) =>
          state = state.copyWith(screenState: ScreenState.error(failure.message)),
      (products) =>
          state = state.copyWith(screenState: ScreenState.loaded(products)),
    );
  }

  Future<void> loadMoreProducts() async {
    final current = state.screenState;
    if (current.isLoadingMore || current.status != ScreenStatus.loaded) return;

    state = state.copyWith(screenState: current.copyWith(isLoadingMore: true));
    await Future.delayed(const Duration(seconds: 2));

    final existing = current.data ?? [];
    final more = List<Product>.from(existing).take(5).toList();

    state = state.copyWith(
      screenState: current.copyWith(
        isLoadingMore: false,
        data: [...existing, ...more],
      ),
    );
  }
}

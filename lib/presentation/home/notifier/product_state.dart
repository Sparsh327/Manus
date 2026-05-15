import 'package:manus/core/presentation/state/screen_state.dart';
import 'package:manus/domain/entities/product.dart';

class ProductState {
  final ScreenState<List<Product>> screenState;

  const ProductState({
    this.screenState = const ScreenState(status: ScreenStatus.initial),
  });

  ProductState copyWith({ScreenState<List<Product>>? screenState}) {
    return ProductState(screenState: screenState ?? this.screenState);
  }
}

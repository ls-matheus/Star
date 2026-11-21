import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gift_inventory_provider.g.dart';

@riverpod
class GiftInventory extends _$GiftInventory {
  @override
  Future<List<GiftCodeMetadataResponse>> build() {
    return ref.read(starClientProvider).users.listUserGifts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(starClientProvider).users.listUserGifts(),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionsRepositoryHash() =>
    r'645852cc01a9f124b773ac983bab34290a6e097e';

/// See also [transactionsRepository].
@ProviderFor(transactionsRepository)
final transactionsRepositoryProvider =
    AutoDisposeProvider<TransactionsRepository>.internal(
  transactionsRepository,
  name: r'transactionsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TransactionsRepositoryRef
    = AutoDisposeProviderRef<TransactionsRepository>;
String _$addTransactionControllerHash() =>
    r'3b6f6d0a4015604985c31f1d01adfe7a2d620234';

/// See also [AddTransactionController].
@ProviderFor(AddTransactionController)
final addTransactionControllerProvider = AutoDisposeNotifierProvider<
    AddTransactionController, InputFormState>.internal(
  AddTransactionController.new,
  name: r'addTransactionControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addTransactionControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddTransactionController = AutoDisposeNotifier<InputFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

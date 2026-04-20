// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$interactionsRepositoryHash() =>
    r'7d8b3447ab6134f334bc9335da1c284e49bd3a3e';

/// See also [interactionsRepository].
@ProviderFor(interactionsRepository)
final interactionsRepositoryProvider =
    AutoDisposeProvider<InteractionsRepository>.internal(
  interactionsRepository,
  name: r'interactionsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$interactionsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InteractionsRepositoryRef
    = AutoDisposeProviderRef<InteractionsRepository>;
String _$interactionTimerNotifierHash() =>
    r'02af4d6298cffef6b4f5db96a9f91ec360e1ce8d';

/// See also [InteractionTimerNotifier].
@ProviderFor(InteractionTimerNotifier)
final interactionTimerNotifierProvider =
    AutoDisposeNotifierProvider<InteractionTimerNotifier, TimerState>.internal(
  InteractionTimerNotifier.new,
  name: r'interactionTimerNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$interactionTimerNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InteractionTimerNotifier = AutoDisposeNotifier<TimerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

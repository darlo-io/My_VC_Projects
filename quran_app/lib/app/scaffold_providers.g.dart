// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scaffold_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scaffoldAppNameHash() => r'2e820138af585fc7de554fb05dfde30122e2ed6c';

/// Простой Provider с @riverpod-аннотацией.
///
/// Copied from [scaffoldAppName].
@ProviderFor(scaffoldAppName)
final scaffoldAppNameProvider = AutoDisposeProvider<String>.internal(
  scaffoldAppName,
  name: r'scaffoldAppNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scaffoldAppNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScaffoldAppNameRef = AutoDisposeProviderRef<String>;
String _$scaffoldSurahCountHash() =>
    r'f3a2eef5688d4b9b96e3bcac597626980d85c9c4';

/// Async Provider, демонстрирующий FutureProvider.
///
/// Copied from [scaffoldSurahCount].
@ProviderFor(scaffoldSurahCount)
final scaffoldSurahCountProvider = AutoDisposeFutureProvider<int>.internal(
  scaffoldSurahCount,
  name: r'scaffoldSurahCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scaffoldSurahCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScaffoldSurahCountRef = AutoDisposeFutureProviderRef<int>;
String _$scaffoldSurahNameHash() => r'd252b410ed12ae92b99f8c2f59f38b3dd2934027';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider с параметром (family).
///
/// Copied from [scaffoldSurahName].
@ProviderFor(scaffoldSurahName)
const scaffoldSurahNameProvider = ScaffoldSurahNameFamily();

/// Provider с параметром (family).
///
/// Copied from [scaffoldSurahName].
class ScaffoldSurahNameFamily extends Family<String> {
  /// Provider с параметром (family).
  ///
  /// Copied from [scaffoldSurahName].
  const ScaffoldSurahNameFamily();

  /// Provider с параметром (family).
  ///
  /// Copied from [scaffoldSurahName].
  ScaffoldSurahNameProvider call(int surahId) {
    return ScaffoldSurahNameProvider(surahId);
  }

  @override
  ScaffoldSurahNameProvider getProviderOverride(
    covariant ScaffoldSurahNameProvider provider,
  ) {
    return call(provider.surahId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scaffoldSurahNameProvider';
}

/// Provider с параметром (family).
///
/// Copied from [scaffoldSurahName].
class ScaffoldSurahNameProvider extends AutoDisposeProvider<String> {
  /// Provider с параметром (family).
  ///
  /// Copied from [scaffoldSurahName].
  ScaffoldSurahNameProvider(int surahId)
    : this._internal(
        (ref) => scaffoldSurahName(ref as ScaffoldSurahNameRef, surahId),
        from: scaffoldSurahNameProvider,
        name: r'scaffoldSurahNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$scaffoldSurahNameHash,
        dependencies: ScaffoldSurahNameFamily._dependencies,
        allTransitiveDependencies:
            ScaffoldSurahNameFamily._allTransitiveDependencies,
        surahId: surahId,
      );

  ScaffoldSurahNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.surahId,
  }) : super.internal();

  final int surahId;

  @override
  Override overrideWith(String Function(ScaffoldSurahNameRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: ScaffoldSurahNameProvider._internal(
        (ref) => create(ref as ScaffoldSurahNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        surahId: surahId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _ScaffoldSurahNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScaffoldSurahNameProvider && other.surahId == surahId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, surahId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScaffoldSurahNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `surahId` of this provider.
  int get surahId;
}

class _ScaffoldSurahNameProviderElement
    extends AutoDisposeProviderElement<String>
    with ScaffoldSurahNameRef {
  _ScaffoldSurahNameProviderElement(super.provider);

  @override
  int get surahId => (origin as ScaffoldSurahNameProvider).surahId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

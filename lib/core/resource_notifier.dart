import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/resource_key.dart';

/// 资源加载 Notifier
/// 管理单个资源的加载状态和数据
class ResourceNotifier<T> extends AsyncNotifier<T> {
  final ResourceKey<T> resourceKey;
  AppContext? _lastContext;
  T? _cachedData;

  ResourceNotifier(this.resourceKey);

  @override
  Future<T> build() async {
    // 监听 AppContext 变化
    final appContext = ref.watch(appContextProvider);

    if (appContext == null) {
      throw Exception('AppContext 未初始化');
    }

    // 如果 AppContext 没有变化且有缓存数据，直接返回缓存
    if (_lastContext != null &&
        _lastContext == appContext &&
        _cachedData != null) {
      return _cachedData!;
    }

    _lastContext = appContext;

    // 加载资源
    final data = await appContext.load<T>(resourceKey);
    _cachedData = data;
    return data;
  }

  /// 手动刷新资源
  Future<void> refresh() async {
    final appContext = ref.read(appContextProvider);
    if (appContext == null) {
      throw Exception('AppContext 未初始化');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await appContext.forceRefresh<T>(resourceKey);
      _cachedData = data;
      return data;
    });
  }
}

/// 创建资源 Provider 的工厂方法
AsyncNotifierProvider<ResourceNotifier<T>, T> createResourceProvider<T>(
  ResourceKey<T> key,
) {
  return AsyncNotifierProvider<ResourceNotifier<T>, T>(() {
    return ResourceNotifier<T>(key);
  });
}

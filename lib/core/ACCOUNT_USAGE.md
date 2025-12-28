# Account 和 AccountRegistry 使用指南

## 概述

新架构使用了简化的账号系统：

- **core.Account** - 简化版本，只包含 platformId 和 credentials，用于资源加载
- **AccountEntity** - Isar 数据模型，用于持久化存储
- **CoreStorageService** - 存储服务，管理账号的保存、读取和删除
- **AccountManager** - 辅助工具类，简化常用操作

`AccountRegistry` 用于在资源加载过程中，通过 `accountIdentifier` 获取完整的 `core.Account` 对象。

## 快速开始（推荐使用 AccountManager）

### 1. 初始化

```dart
import 'package:rank_hub/core/core.dart';

// 应用启动时初始化
await CoreStorageService.instance.initialize();
```

### 2. 账号登录

```dart
import 'package:rank_hub/core/account_manager.dart';

// 登录成功后保存并注册
final account = await AccountManager.saveAndRegister(
  platformId: 'lxns',
  accountIdentifier: 'user123',
  displayName: '玩家名称',
  credentials: {
    'accessToken': 'xxx',
    'refreshToken': 'yyy',
    'externalId': 'user123',
  },
);
```

### 3. 恢复账号

```dart
// 应用启动时恢复所有账号
await AccountManager.loadAndRegisterAll();

// 或只恢复指定平台的账号
await AccountManager.loadAndRegisterAllByPlatform('lxns');

// 或恢复单个账号
final account = await AccountManager.loadAndRegister('lxns', 'user123');
```

### 4. 账号登出

```dart
await AccountManager.deleteAndUnregister('lxns', 'user123');
```

### 5. 更新凭证

```dart
await AccountManager.updateCredentialsAndReregister(
  'lxns',
  'user123',
  {'accessToken': 'new_token', ...},
);
```

## AccountManager API（推荐）

### saveAndRegister()

保存账号到数据库并注册到 Registry：

```dart
final account = await AccountManager.saveAndRegister(
  platformId: 'lxns',
  accountIdentifier: 'user123',
  displayName: '玩家名称',
  credentials: {...},
);
```

### loadAndRegister()

从数据库加载单个账号并注册：

```dart
final account = await AccountManager.loadAndRegister('lxns', 'user123');
if (account == null) {
  print('账号不存在');
}
```

### loadAndRegisterAllByPlatform()

加载指定平台的所有账号：

```dart
final count = await AccountManager.loadAndRegisterAllByPlatform('lxns');
print('已加载 $count 个账号');
```

### loadAndRegisterAll()

加载所有平台的所有账号：

```dart
final count = await AccountManager.loadAndRegisterAll();
print('已加载 $count 个账号');
```

### deleteAndUnregister()

删除账号并取消注册：

```dart
await AccountManager.deleteAndUnregister('lxns', 'user123');
```

### updateCredentialsAndReregister()

更新凭证并重新注册：

```dart
await AccountManager.updateCredentialsAndReregister(
  'lxns',
  'user123',
  {'accessToken': 'new_token', ...},
);
```

### clearAll()

清空所有内存注册（不删除数据库）：

```dart
await AccountManager.clearAll();
```

## 基本使用流程（手动方式）

### 1. 账号登录时保存并注册到 Registry

```dart
import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/services/storage_service.dart';

// 登录成功后，创建 Account 并保存
Future<void> onLoginSuccess({
  required String platformId,
  required String accountIdentifier,
  required String displayName,
  required Map<String, dynamic> credentials,
}) async {
  // 创建 Account
  final account = Account(
    platformId: platformId,
    credentials: credentials,
  );

  // 保存到数据库
  await CoreStorageService.instance.saveAccount(
    account,
    accountIdentifier,
    displayName,
  );

  // 注册到 AccountRegistry
  AccountRegistry.instance.register(accountIdentifier, account);

  print('✅ 账号已保存并注册: $accountIdentifier');
}
```

### 2. 从数据库加载账号并注册

```dart
// 应用启动时或需要时加载账号
Future<void> loadAndRegisterAccount(
  String platformId,
  String accountIdentifier,
) async {
  // 从数据库获取账号实体
  final entity = await CoreStorageService.instance.getAccountEntity(
    platformId,
    accountIdentifier,
  );

  if (entity == null) {
    print('账号不存在');
    return;
  }

  // 创建 Account
  final account = Account.fromEntity(
    entity.platformId,
    entity.credentialsJson,
  );

  // 注册到 Registry
  AccountRegistry.instance.register(accountIdentifier, account);
}
```

### 3. 创建 ResourceScope 时使用 identifier

```dart
import 'package:rank_hub/core/resource_scope.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/platform_id.dart';

final scope = ResourceScope(
  gameId: GameId(name: 'maimai', version: 'DX', platform: 'arcade', region: 'CN'),
  platformId: PlatformId('lxns'),
  accountIdentifier: accountIdentifier, // 使用相同的 identifier
);
```

### 4. 在 GameResourceDefinition 中使用

```dart
@override
Future<List<MaimaiScore>> fetch(
  ResourceScope scope,
  List<PlatformAdapter> adapters,
) async {
  if (!scope.hasAccount) {
    throw Exception('需要登录账号');
  }

  // 从 AccountRegistry 获取账号
  final account = AccountRegistry.instance.get(scope.accountIdentifier!);
  if (account == null) {
    throw Exception('未找到账号: ${scope.accountIdentifier}');
  }

  // 使用账号获取数据
  final adapter = adapters.firstWhere((a) => a.supports(scope.gameId));
  final scores = await adapter.fetchResource<List<MaimaiScore>>(key, account);
  return scores ?? [];
}
```

### 5. 账号登出时删除并取消注册

```dart
Future<void> onLogout(String platformId, String accountIdentifier) async {
  // 从数据库删除
  await CoreStorageService.instance.deleteAccount(platformId, accountIdentifier);

  // 从 Registry 取消注册
  AccountRegistry.instance.unregister(accountIdentifier);

  print('✅ 账号已删除: $accountIdentifier');
}
```

## CoreStorageService API

### 初始化

```dart
await CoreStorageService.instance.initialize();
```

### 保存账号

```dart
await CoreStorageService.instance.saveAccount(
  account,
  accountIdentifier,
  displayName,
);
```

### 获取账号实体

```dart
final entity = await CoreStorageService.instance.getAccountEntity(
  platformId,
  accountIdentifier,
);
```

### 获取指定平台的所有账号

```dart
final accounts = await CoreStorageService.instance.getAccountsByPlatform(platformId);
```

### 获取所有账号实体

```dart
final entities = await CoreStorageService.instance.getAccountEntitiesByPlatform(platformId);
```

### 删除账号

```dart
await CoreStorageService.instance.deleteAccount(platformId, accountIdentifier);
```

### 更新账号凭证

```dart
await CoreStorageService.instance.updateAccountCredentials(
  platformId,
  accountIdentifier,
  newCredentials,
);
```

### 游戏账号选择

```dart
// 设置游戏选择的账号
await CoreStorageService.instance.setSelectedAccountForGame(
  gameId,
  platformId,
  accountIdentifier,
);

// 获取游戏选择的账号
final account = await CoreStorageService.instance.getSelectedAccount(gameId);

// 清除游戏账号选择
await CoreStorageService.instance.clearSelectedAccountForGame(gameId);
```

## Account API

### 从 AccountEntity 创建

```dart
final account = Account.fromEntity(
  entity.platformId,
  entity.credentialsJson,
);
```

### 基本属性

- `platformId`: 平台标识
- `credentials`: 凭据 Map

### 便捷访问器

- `accessToken`: OAuth2 访问令牌
- `refreshToken`: OAuth2 刷新令牌
- `apiKey`: API Key
- `username`: 用户名
- `password`: 密码
- `externalId`: 外部标识

### 转换为 JSON

```dart
final json = account.toCredentialsJson();
```

## AccountRegistry API

### register()

注册账号：

```dart
AccountRegistry.instance.register(identifier, account);
```

### get()

获取已注册的账号：

```dart
final account = AccountRegistry.instance.get(identifier);
if (account == null) {
  print('账号未找到');
}
```

### unregister()

取消注册：

```dart
AccountRegistry.instance.unregister(identifier);
```

### clear()

清空所有注册：

```dart
AccountRegistry.instance.clear();
```

### registeredIdentifiers

获取所有已注册的标识符：

```dart
final identifiers = AccountRegistry.instance.registeredIdentifiers;
print('已注册账号: $identifiers');
```

## 完整示例：LXNS OAuth2 登录

```dart
import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/services/storage_service.dart';
import 'package:rank_hub/core/resource_scope.dart';

// 1. OAuth2 登录成功
Future<void> onLxnsLoginSuccess({
  required String accessToken,
  required String refreshToken,
  required String externalId,
  required String displayName,
}) async {
  // 构建凭据
  final credentials = {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'externalId': externalId,
    'tokenExpiry': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
  };

  // 创建 Account
  final account = Account(
    platformId: 'lxns',
    credentials: credentials,
  );

  // 保存到数据库
  await CoreStorageService.instance.saveAccount(
    account,
    externalId,
    displayName,
  );

  // 注册到 Registry
  AccountRegistry.instance.register(externalId, account);

  print('✅ LXNS 账号登录成功: $displayName');
}

// 2. 应用启动时恢复账号
Future<void> restoreAccountOnStartup() async {
  // 初始化存储服务
  await CoreStorageService.instance.initialize();

  // 获取所有 LXNS 账号
  final entities = await CoreStorageService.instance
      .getAccountEntitiesByPlatform('lxns');

  // 注册所有账号到 Registry
  for (final entity in entities) {
    final account = Account.fromEntity(
      entity.platformId,
      entity.credentialsJson,
    );
    AccountRegistry.instance.register(entity.accountIdentifier, account);
  }

  print('✅ 已恢复 ${entities.length} 个账号');
}

// 3. 资源定义中使用
class MaimaiScoreListResource extends GameResourceDefinition<List<MaimaiScore>> {
  @override
  Future<List<MaimaiScore>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    // 获取账号
    final account = AccountRegistry.instance.get(scope.accountIdentifier!);
    if (account == null) {
      throw Exception('账号未注册');
    }

    // 使用账号获取数据
    final adapter = adapters.first;
    return await adapter.fetchResource(key, account) ?? [];
  }
}

// 4. 登出
Future<void> onLogout(String externalId) async {
  // 从数据库删除
  await CoreStorageService.instance.deleteAccount('lxns', externalId);

  // 从 Registry 取消注册
  AccountRegistry.instance.unregister(externalId);

  print('✅ 已登出');
}
```

## 注意事项

1. **初始化**: 应用启动时必须先调用 `CoreStorageService.instance.initialize()`
2. **生命周期管理**: 确保账号登录时保存+注册，登出时删除+取消注册
3. **Identifier 一致性**: 同一账号在存储、ResourceScope 和 AccountRegistry 中使用相同的 identifier
4. **错误处理**: 始终检查 `AccountRegistry.instance.get()` 返回值是否为 null
5. **凭据刷新**: 如果凭据被刷新，需要更新数据库并重新注册到 Registry

## 调试

启用日志查看账号状态：

```dart
// 注册时会打印
📦 注册账号: user123 -> lxns

// 取消注册时会打印
🗑️ 取消注册账号: user123

// 清空时会打印
🧹 清空所有账号注册

// 查看已注册账号
print(AccountRegistry.instance.registeredIdentifiers);
```
```

### 2. 创建 ResourceScope 时使用 identifier

```dart
import 'package:rank_hub/core/resource_scope.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/platform_id.dart';

final scope = ResourceScope(
  gameId: GameId(name: 'maimai', version: 'DX', platform: 'arcade', region: 'CN'),
  platformId: PlatformId('lxns'),
  accountIdentifier: account.externalId, // 使用相同的 identifier
);
```

### 3. 在 GameResourceDefinition 中使用

```dart
@override
Future<List<MaimaiScore>> fetch(
  ResourceScope scope,
  List<PlatformAdapter> adapters,
) async {
  if (!scope.hasAccount) {
    throw Exception('需要登录账号');
  }

  // 从 AccountRegistry 获取账号
  final account = AccountRegistry.instance.get(scope.accountIdentifier!);
  if (account == null) {
    throw Exception('未找到账号: ${scope.accountIdentifier}');
  }

  // 使用账号获取数据
  final adapter = adapters.firstWhere((a) => a.supports(scope.gameId));
  final scores = await adapter.fetchResource<List<MaimaiScore>>(key, account);
  return scores ?? [];
}
```

### 4. 账号登出时取消注册

```dart
void onLogout(String identifier) {
  AccountConverter.unregisterFromRegistry(identifier);
  print('✅ 账号已取消注册: $identifier');
}
```

## AccountConverter API

### toCore()

将 `models.Account` 转换为 `core.Account`：

```dart
final coreAccount = AccountConverter.toCore(modelsAccount);
```

转换规则：
- **API Key**: `credentials['apiKey']`
- **OAuth2**: `credentials['accessToken']`, `credentials['refreshToken']`, `credentials['tokenExpiry']`
- **Username/Password**: `credentials['username']`, `credentials['password']`
- **Custom**: 从 `additionalData` JSON 解析

### registerToRegistry()

将账号转换并注册到 Registry：

```dart
AccountConverter.registerToRegistry(identifier, account);
```

### unregisterFromRegistry()

从 Registry 取消注册：

```dart
AccountConverter.unregisterFromRegistry(identifier);
```

## AccountRegistry API

### register()

直接注册 `core.Account`：

```dart
AccountRegistry.instance.register(identifier, coreAccount);
```

### get()

获取已注册的账号：

```dart
final account = AccountRegistry.instance.get(identifier);
if (account == null) {
  print('账号未找到');
}
```

### unregister()

取消注册：

```dart
AccountRegistry.instance.unregister(identifier);
```

### clear()

清空所有注册：

```dart
AccountRegistry.instance.clear();
```

### registeredIdentifiers

获取所有已注册的标识符：

```dart
final identifiers = AccountRegistry.instance.registeredIdentifiers;
print('已注册账号: $identifiers');
```

## core.Account 属性

### 基本属性

- `platformId`: 平台标识
- `credentials`: 凭据 Map

### 便捷访问器

- `accessToken`: OAuth2 访问令牌
- `refreshToken`: OAuth2 刷新令牌
- `apiKey`: API Key
- `username`: 用户名
- `password`: 密码
- `externalId`: 外部标识

## 完整示例

```dart
import 'package:rank_hub/core/account_converter.dart';
import 'package:rank_hub/core/resource_scope.dart';
import 'package:rank_hub/models/account/account.dart';

// 1. 登录成功
void onLxnsLoginSuccess(Account account) {
  final identifier = account.externalId;
  
  // 注册到 Registry
  AccountConverter.registerToRegistry(identifier, account);
  
  // 创建 Scope
  final scope = ResourceScope(
    gameId: GameId(name: 'maimai', version: 'DX', platform: 'arcade', region: 'CN'),
    platformId: PlatformId('lxns'),
    accountIdentifier: identifier,
  );
  
  // 使用 Scope 创建 Context 和 Loader...
}

// 2. 资源定义中使用
class MaimaiScoreListResource extends GameResourceDefinition<List<MaimaiScore>> {
  @override
  Future<List<MaimaiScore>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    // 获取账号
    final account = AccountRegistry.instance.get(scope.accountIdentifier!);
    if (account == null) {
      throw Exception('账号未注册');
    }
    
    // 使用账号获取数据
    final adapter = adapters.first;
    return await adapter.fetchResource(key, account) ?? [];
  }
}

// 3. 登出
void onLogout(String identifier) {
  AccountConverter.unregisterFromRegistry(identifier);
}
```

## 注意事项

1. **生命周期管理**: 确保账号登录时注册，登出时取消注册
2. **Identifier 一致性**: 同一账号在 ResourceScope 和 AccountRegistry 中使用相同的 identifier
3. **错误处理**: 始终检查 `AccountRegistry.instance.get()` 返回值是否为 null
4. **线程安全**: AccountRegistry 是单例，在多线程环境下使用需注意
5. **凭据刷新**: 如果凭据（如 accessToken）被刷新，需要重新注册到 Registry

## 调试

启用日志查看账号注册状态：

```dart
// 注册时会打印
📦 注册账号: user123 -> lxns

// 取消注册时会打印
🗑️ 取消注册账号: user123

// 清空时会打印
🧹 清空所有账号注册

// 查看已注册账号
print(AccountRegistry.instance.registeredIdentifiers);
```

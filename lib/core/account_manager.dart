import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/services/storage_service.dart';

/// 账号管理辅助工具
/// 简化账号的保存、加载和注册操作
class AccountManager {
  /// 保存账号并注册到 Registry
  ///
  /// [platformId] 平台 ID
  /// [accountIdentifier] 账号唯一标识
  /// [displayName] 显示名称
  /// [credentials] 凭据数据
  static Future<Account> saveAndRegister({
    required String platformId,
    required String accountIdentifier,
    required String displayName,
    required Map<String, dynamic> credentials,
  }) async {
    // 创建 Account
    final account = Account(platformId: platformId, credentials: credentials);

    // 保存到数据库
    await CoreStorageService.instance.saveAccount(
      account,
      accountIdentifier,
      displayName,
    );

    // 注册到 Registry
    AccountRegistry.instance.register(accountIdentifier, account);

    print('✅ 账号已保存并注册: $displayName ($accountIdentifier)');

    return account;
  }

  /// 从数据库加载账号并注册到 Registry
  ///
  /// [platformId] 平台 ID
  /// [accountIdentifier] 账号唯一标识
  ///
  /// 返回加载的 Account，如果账号不存在则返回 null
  static Future<Account?> loadAndRegister(
    String platformId,
    String accountIdentifier,
  ) async {
    // 从数据库获取账号实体
    final entity = await CoreStorageService.instance.getAccountEntity(
      platformId,
      accountIdentifier,
    );

    if (entity == null) {
      print('⚠️ 账号不存在: $platformId:$accountIdentifier');
      return null;
    }

    // 创建 Account
    final account = Account.fromEntity(
      entity.platformId,
      entity.credentialsJson,
    );

    // 注册到 Registry
    AccountRegistry.instance.register(accountIdentifier, account);

    print('✅ 账号已加载并注册: ${entity.displayName} ($accountIdentifier)');

    return account;
  }

  /// 加载指定平台的所有账号并注册到 Registry
  ///
  /// [platformId] 平台 ID
  ///
  /// 返回加载的账号数量
  static Future<int> loadAndRegisterAllByPlatform(String platformId) async {
    // 获取所有账号实体
    final entities = await CoreStorageService.instance
        .getAccountEntitiesByPlatform(platformId);

    // 注册所有账号到 Registry
    for (final entity in entities) {
      final account = Account.fromEntity(
        entity.platformId,
        entity.credentialsJson,
      );
      AccountRegistry.instance.register(entity.accountIdentifier, account);
    }

    print('✅ 已加载并注册 ${entities.length} 个 $platformId 账号');

    return entities.length;
  }

  /// 加载所有平台的所有账号并注册到 Registry
  ///
  /// 返回加载的账号数量
  static Future<int> loadAndRegisterAll() async {
    // 获取所有账号
    final accounts = await CoreStorageService.instance.getAllAccounts();

    int count = 0;
    for (final account in accounts) {
      // 需要从 credentials 中获取 accountIdentifier
      final identifier = account.externalId;
      if (identifier != null) {
        AccountRegistry.instance.register(identifier, account);
        count++;
      }
    }

    print('✅ 已加载并注册 $count 个账号');

    return count;
  }

  /// 删除账号并从 Registry 取消注册
  ///
  /// [platformId] 平台 ID
  /// [accountIdentifier] 账号唯一标识
  static Future<void> deleteAndUnregister(
    String platformId,
    String accountIdentifier,
  ) async {
    // 从数据库删除
    await CoreStorageService.instance.deleteAccount(
      platformId,
      accountIdentifier,
    );

    // 从 Registry 取消注册
    AccountRegistry.instance.unregister(accountIdentifier);

    print('✅ 账号已删除: $platformId:$accountIdentifier');
  }

  /// 更新账号凭证并重新注册
  ///
  /// [platformId] 平台 ID
  /// [accountIdentifier] 账号唯一标识
  /// [newCredentials] 新的凭据数据
  static Future<void> updateCredentialsAndReregister(
    String platformId,
    String accountIdentifier,
    Map<String, dynamic> newCredentials,
  ) async {
    // 更新数据库中的凭证
    await CoreStorageService.instance.updateAccountCredentials(
      platformId,
      accountIdentifier,
      newCredentials,
    );

    // 创建新的 Account
    final account = Account(
      platformId: platformId,
      credentials: newCredentials,
    );

    // 重新注册到 Registry
    AccountRegistry.instance.register(accountIdentifier, account);

    print('✅ 账号凭证已更新: $platformId:$accountIdentifier');
  }

  /// 清空所有账号（数据库和 Registry）
  static Future<void> clearAll() async {
    // 清空 Registry
    AccountRegistry.instance.clear();

    print('✅ 已清空所有账号注册');
    print('⚠️ 注意: 数据库中的账号数据未删除，仅清空了内存注册');
  }
}

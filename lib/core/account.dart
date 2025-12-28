import 'dart:convert';

/// 账号信息（简化版，用于核心架构）
class Account {
  final String platformId;
  final Map<String, dynamic> credentials;

  Account({required this.platformId, required this.credentials});

  /// 从 credentials 中获取 accessToken
  String? get accessToken => credentials['accessToken'] as String?;

  /// 从 credentials 中获取 refreshToken
  String? get refreshToken => credentials['refreshToken'] as String?;

  /// 从 credentials 中获取 apiKey
  String? get apiKey => credentials['apiKey'] as String?;

  /// 从 credentials 中获取 username
  String? get username => credentials['username'] as String?;

  /// 从 credentials 中获取 password
  String? get password => credentials['password'] as String?;

  /// 从 credentials 中获取 externalId
  String? get externalId => credentials['externalId'] as String?;

  /// 从 AccountEntity 创建 Account
  static Account fromEntity(String platformId, String credentialsJson) {
    final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
    return Account(platformId: platformId, credentials: credentials);
  }

  /// 转换为 JSON 字符串（用于存储）
  String toCredentialsJson() {
    return jsonEncode(credentials);
  }
}

/// 账号注册表
/// 用于在资源加载过程中通过 accountIdentifier 获取完整的 Account 对象
class AccountRegistry {
  static final AccountRegistry _instance = AccountRegistry._();
  static AccountRegistry get instance => _instance;

  AccountRegistry._();

  /// 存储账号映射：accountIdentifier -> Account
  final Map<String, Account> _accounts = {};

  /// 注册账号
  void register(String identifier, Account account) {
    _accounts[identifier] = account;
    print('📦 注册账号: $identifier -> ${account.platformId}');
  }

  /// 获取账号
  Account? get(String identifier) {
    return _accounts[identifier];
  }

  /// 删除账号
  void unregister(String identifier) {
    _accounts.remove(identifier);
    print('🗑️ 取消注册账号: $identifier');
  }

  /// 清空所有账号
  void clear() {
    _accounts.clear();
    print('🧹 清空所有账号注册');
  }

  /// 获取所有已注册的账号标识
  List<String> get registeredIdentifiers => _accounts.keys.toList();
}

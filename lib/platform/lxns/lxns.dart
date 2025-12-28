/// 落雪咖啡屋平台集成
///
/// 本模块提供了落雪咖啡屋平台的完整集成，包括：
/// - Platform 实现：处理登录、刷新和验证
/// - PlatformAdapter 实现：提供资源获取能力
/// - OAuth2 登录流程：支持自动跳转和手动输入两种方式
/// - 凭据管理：自动刷新 OAuth2 令牌

export 'lxns_platform.dart';
export 'lxns_platform_adapter.dart';
export 'lxns_login_page.dart';
export 'lxns_credential_provider.dart';
export 'lxns_oauth2_helper.dart';

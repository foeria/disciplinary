/// 云端后端接口路径常量（任务三预留）。
class BackendEndpoints {
  BackendEndpoints._();

  static const String loginByPhone = '/api/v1/auth/login/phone';
  static const String sendCode = '/api/v1/auth/code/send';
  static const String refreshToken = '/api/v1/auth/token/refresh';

  static const String syncUpload = '/api/v1/sync/upload';
  static const String syncDownload = '/api/v1/sync/download';
  static const String syncUsage = '/api/v1/sync/usage';

  static const String memberStatus = '/api/v1/member/status';
  static const String memberOrder = '/api/v1/member/order';
  static const String memberVerify = '/api/v1/member/verify';
  static const String memberProducts = '/api/v1/member/products';

  static const String adsConfig = '/api/v1/ads/config';
  static const String adsImpression = '/api/v1/ads/impression';
}

/// ===== 认证接口 =====
class PhoneLoginRequest {
  final String phone;
  final String code;

  const PhoneLoginRequest({
    required this.phone,
    required this.code,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'code': code,
      };
}

class SendCodeRequest {
  final String phone;
  final String type;

  const SendCodeRequest({
    required this.phone,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'type': type,
      };
}

class AuthTokenPayload {
  final String userId;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokenPayload({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

abstract class AuthApi {
  Future<AuthTokenPayload> loginByPhone(PhoneLoginRequest request);
  Future<void> sendCode(SendCodeRequest request);
  Future<String> refreshToken(String refreshToken);
}

/// ===== 同步接口 =====
class SyncUploadPayload {
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> apps;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> schedule;
  final List<Map<String, dynamic>> whitelist;
  final Map<String, dynamic> notificationSettings;

  const SyncUploadPayload({
    required this.settings,
    required this.apps,
    required this.questions,
    required this.schedule,
    required this.whitelist,
    required this.notificationSettings,
  });

  Map<String, dynamic> toMap() => {
        'settings': settings,
        'apps': apps,
        'questions': questions,
        'schedule': schedule,
        'whitelist': whitelist,
        'notification_settings': notificationSettings,
      };
}

class UsageRecordPayload {
  final String appPackage;
  final String date;
  final int usedMinutes;
  final int openCount;

  const UsageRecordPayload({
    required this.appPackage,
    required this.date,
    required this.usedMinutes,
    required this.openCount,
  });

  Map<String, dynamic> toMap() => {
        'app_package': appPackage,
        'date': date,
        'used_minutes': usedMinutes,
        'open_count': openCount,
      };
}

abstract class SyncApi {
  Future<DateTime> uploadConfig(SyncUploadPayload payload);
  Future<Map<String, dynamic>> downloadConfig();
  Future<int> syncUsageRecords(List<UsageRecordPayload> records);
}

/// ===== 会员接口 =====
class MemberStatusPayload {
  final bool isPremium;
  final DateTime? expireDate;
  final List<String> features;

  const MemberStatusPayload({
    required this.isPremium,
    required this.expireDate,
    required this.features,
  });
}

class MemberProductPayload {
  final String productId;
  final String name;
  final double price;
  final String currency;
  final int durationDays;

  const MemberProductPayload({
    required this.productId,
    required this.name,
    required this.price,
    required this.currency,
    required this.durationDays,
  });
}

abstract class MemberApi {
  Future<MemberStatusPayload> getMemberStatus();
  Future<String> createOrder({required String productId, required String platform});
  Future<MemberStatusPayload> verifyOrder({required String orderId, required String receipt});
  Future<List<MemberProductPayload>> getProducts();
}

/// ===== 广告接口 =====
class AdsConfigPayload {
  final bool enabled;
  final Map<String, String> adUnits;
  final int dailyLimit;
  final List<String> categories;

  const AdsConfigPayload({
    required this.enabled,
    required this.adUnits,
    required this.dailyLimit,
    required this.categories,
  });
}

abstract class AdsApi {
  Future<AdsConfigPayload> getAdsConfig();
  Future<void> reportImpression({
    required String adUnit,
    required String adId,
    required String placement,
  });
}

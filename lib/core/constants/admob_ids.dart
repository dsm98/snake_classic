import 'dart:io';

class AdmobIds {
  // ── Test IDs (use during development) ────────────────────────
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // ── TODO: Replace with your real AdMob IDs before publishing ─
  static const _prodAndroidBanner = 'ca-app-pub-6149570316675621/2549652657';
  static const _prodAndroidInterstitial =
      'ca-app-pub-6149570316675621/7976179663';
  static const _prodAndroidRewarded = 'ca-app-pub-6149570316675621/6663097997';
  static const _prodIosBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodIosInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodIosRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static const bool _useTestIds = true; // ← set false before release

  static String get bannerAdUnitId {
    if (_useTestIds) return _testBanner;
    return Platform.isAndroid ? _prodAndroidBanner : _prodIosBanner;
  }

  static String get interstitialAdUnitId {
    if (_useTestIds) return _testInterstitial;
    return Platform.isAndroid ? _prodAndroidInterstitial : _prodIosInterstitial;
  }

  static String get rewardedAdUnitId {
    if (_useTestIds) return _testRewarded;
    return Platform.isAndroid ? _prodAndroidRewarded : _prodIosRewarded;
  }

  // ── AdMob App IDs (add to AndroidManifest.xml / Info.plist) ──
  // Android: ca-app-pub-3940256099942544~3347511713 (test)
  // iOS:     ca-app-pub-3940256099942544~1458002511 (test)
}

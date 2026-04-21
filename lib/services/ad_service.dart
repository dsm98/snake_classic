import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants/admob_ids.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _interstitialReady = false;
  bool _rewardedReady = false;

  bool get isRewardedReady => !kIsWeb && _rewardedReady;

  Future<void> init() async {
    if (kIsWeb) return; // AdMob has no web implementation
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  // ── Interstitial ───────────────────────────────────────────────
  void loadInterstitial() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: AdmobIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialReady = false;
              loadInterstitial(); // preload next
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
        },
      ),
    );
  }

  Future<bool> showInterstitial() async {
    if (kIsWeb || !_interstitialReady || _interstitialAd == null) return false;
    await _interstitialAd!.show();
    return true;
  }

  // ── Rewarded ───────────────────────────────────────────────────
  void loadRewarded() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: AdmobIds.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _rewardedReady = false;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) => _rewardedReady = false,
      ),
    );
  }

  Future<bool> showRewarded({required void Function() onRewarded}) async {
    if (kIsWeb || !_rewardedReady || _rewardedAd == null) return false;
    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
    return true;
  }

  void dispose() {
    if (kIsWeb) return;
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

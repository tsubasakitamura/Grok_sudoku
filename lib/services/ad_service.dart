import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdService {
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;

  BannerAd? get bannerAd => _bannerAd;

  void loadBannerAd({required VoidCallback onAdLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: Constants.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('バナー広告が正常にロードされました');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          print('バナー広告の読み込みに失敗: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd!.load();
  }

  void loadRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;

    RewardedAd.load(
      adUnitId: Constants.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('リワード広告が正常にロードされました');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('リワード広告の読み込みに失敗: $error');
          _rewardedAd = null;
          Future.delayed(Duration(seconds: 5), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  void showRewardedAd({required VoidCallback onReward, required VoidCallback onError}) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onReward();
          loadRewardedAd();
        },
      );
    } else {
      onError();
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
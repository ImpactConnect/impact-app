import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal() {
    // Initialize ads when the service is created
    initialize();
  }

  // Track if ads are initialized
  bool _initialized = false;
  
  // Track session time for timed ads
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  int _sessionDurationMinutes = 0;
  
  // Track if an interstitial ad was recently shown
  DateTime? _lastInterstitialAdTime;
  
  // Ad units - replace these with your actual ad unit IDs in production
  // Using test ad unit IDs for development
  final String _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
      
  final String _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
      
  final String _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
  
  final String _rewardedInterstitialAdUnitId = 'YOUR_REWARDED_INTERSTITIAL_AD_UNIT_ID';
  
  // Ad objects
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  DateTime? _rewardedInterstitialAdLoadTime;
  
  // Cooldown period between interstitial ads (in minutes)
  final int _interstitialAdCooldownMinutes = 3;
  
  // Initialize AdMob
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Check if running on web or in debug mode
      if (kIsWeb) {
        print('Running on web platform, skipping Mobile Ads initialization');
        _initialized = true;
        return;
      }

      print('Starting Mobile Ads initialization...');
      await MobileAds.instance.initialize();
      
      // Update test device IDs
      // Replace with your test device ID in development
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['FAD7164E21BF44C0C74A56068366E537'],
        ),
      );
      
      print('Mobile Ads initialized successfully');
      
      // Set up session timer
      _sessionStartTime = DateTime.now();
      _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _sessionDurationMinutes++;
      });
      
      _initialized = true;
      
      // Preload ads
      _loadInterstitialAd();
      _loadRewardedVideoAd();
      _loadRewardedInterstitialAd();
      
      print('Ad preloading started');
    } catch (e) {
      print('Error initializing Mobile Ads: $e');
      // Set initialized to true anyway to prevent repeated initialization attempts
      _initialized = true;
    }
  }
  
  // Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
  
  // Check if enough time has passed since the last interstitial ad
  bool _canShowInterstitialAd() {
    if (_lastInterstitialAdTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastInterstitialAdTime!);
    return difference.inMinutes >= _interstitialAdCooldownMinutes;
  }
  
  // Banner Ad
  BannerAd createBannerAd({
    required AdSize size,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    print('Creating BannerAd with adUnitId: ${_getBannerAdUnitId()}');
    return BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => print('Banner ad opened'),
        onAdClosed: (ad) => print('Banner ad closed'),
        onAdImpression: (ad) => print('Banner ad impression recorded'),
      ),
    );
  }
  
  // Load Interstitial Ad
  Future<void> _loadInterstitialAd() async {
    if (kIsWeb) return;
    
    try {
      print('Loading interstitial ad...');
      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Interstitial ad dismissed');
                _interstitialAd = null;
                _loadInterstitialAd(); // Reload the ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Failed to show interstitial ad: $error');
                ad.dispose();
                _interstitialAd = null;
                _loadInterstitialAd(); // Try to reload the ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('Interstitial ad showed successfully');
              },
              onAdImpression: (ad) {
                print('Interstitial ad impression recorded');
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('Failed to load interstitial ad: ${error.message}');
            _interstitialAd = null;
            
            // Retry after a delay
            Future.delayed(const Duration(seconds: 30), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error in _loadInterstitialAd: $e');
      // Retry after a delay
      Future.delayed(const Duration(seconds: 30), () {
        _loadInterstitialAd();
      });
    }
  }
  
  // Show Interstitial Ad
  Future<bool> showInterstitialAd() async {
    if (!_initialized) await initialize();
    
    if (kIsWeb) {
      print('Interstitial ads not supported on web platform');
      return false;
    }
    
    if (!_canShowInterstitialAd()) {
      print('Interstitial ad cooldown period not over yet');
      return false;
    }
    
    if (_interstitialAd == null) {
      print('Interstitial ad not loaded yet');
      
      // Try to load a new ad
      _loadInterstitialAd();
      return false;
    }
    
    final Completer<bool> adCompleter = Completer<bool>();
    
    try {
      print('Showing interstitial ad');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed');
          _lastInterstitialAdTime = DateTime.now();
          _interstitialAd = null;
          _loadInterstitialAd(); // Reload the ad
          if (!adCompleter.isCompleted) adCompleter.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show interstitial ad: $error');
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd(); // Try to reload the ad
          if (!adCompleter.isCompleted) adCompleter.complete(false);
        },
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed successfully');
          _lastInterstitialAdTime = DateTime.now();
        },
        onAdImpression: (ad) {
          print('Interstitial ad impression recorded');
        },
      );
      
      await _interstitialAd!.show();
      
      // Set up a timeout in case the ad doesn't complete
      Future.delayed(const Duration(seconds: 30), () {
        if (!adCompleter.isCompleted) {
          print('Interstitial ad timed out');
          adCompleter.complete(false);
        }
      });
      
      return await adCompleter.future;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      if (!adCompleter.isCompleted) adCompleter.complete(false);
      
      // Load a new ad for next time
      _loadInterstitialAd();
      return false;
    }
  }
  
  // Check if a timed ad should be shown
  bool shouldShowTimedAd() {
    // Show an ad every 5 minutes of app usage
    return _sessionDurationMinutes > 0 && _sessionDurationMinutes % 5 == 0;
  }
  
  // Load Rewarded Video Ad
  Future<void> _loadRewardedVideoAd() async {
    if (kIsWeb) return;
    
    try {
      print('Loading rewarded video ad...');
      await RewardedAd.load(
        adUnitId: _getRewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('Rewarded video ad loaded successfully');
            _rewardedAd = ad;
            
            // Set callback for when the ad is closed
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Rewarded video ad dismissed');
                _rewardedAd = null;
                _loadRewardedVideoAd(); // Reload the ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Failed to show rewarded video ad: $error');
                ad.dispose();
                _rewardedAd = null;
                _loadRewardedVideoAd(); // Try to reload the ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('Rewarded video ad showed successfully');
              },
              onAdImpression: (ad) {
                print('Rewarded video ad impression recorded');
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('Rewarded video ad failed to load: ${error.message}');
            _rewardedAd = null;
            
            // Retry after a delay
            Future.delayed(const Duration(minutes: 1), () {
              _loadRewardedVideoAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error in _loadRewardedVideoAd: $e');
      // Retry after a delay
      Future.delayed(const Duration(minutes: 1), () {
        _loadRewardedVideoAd();
      });
    }
  }
  
  // Show Rewarded Video Ad
  Future<bool> showRewardedVideoAd() async {
    if (!_initialized) await initialize();
    
    if (kIsWeb) {
      print('Rewarded video ads not supported on web platform');
      return false;
    }
    
    if (_rewardedAd == null) {
      print('Rewarded video ad not loaded yet');
      
      // Try to load a new ad
      int attempts = 0;
      while (_rewardedAd == null && attempts < 3) {
        print('Attempting to load rewarded video ad (attempt ${attempts + 1})');
        await _loadRewardedVideoAd();
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
      
      if (_rewardedAd == null) {
        print('Failed to load rewarded ad after multiple attempts');
        return false;
      }
    }
    
    final Completer<bool> adCompleter = Completer<bool>();
    
    try {
      print('Showing rewarded video ad');
      await _rewardedAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          if (!adCompleter.isCompleted) adCompleter.complete(true);
        }
      );
      
      // Set up a timeout in case the ad doesn't complete
      Future.delayed(const Duration(seconds: 30), () {
        if (!adCompleter.isCompleted) {
          print('Rewarded ad timed out');
          adCompleter.complete(false);
        }
      });
      
      return await adCompleter.future;
    } catch (e) {
      print('Error showing rewarded video ad: $e');
      if (!adCompleter.isCompleted) adCompleter.complete(false);
      
      // Load a new ad for next time
      _loadRewardedVideoAd();
      return false;
    }
  }
  
  // Load Rewarded Interstitial Ad
  Future<void> _loadRewardedInterstitialAd() async {
    if (kIsWeb) return;
    
    try {
      print('Loading rewarded interstitial ad...');
      await RewardedInterstitialAd.load(
        adUnitId: _getRewardedInterstitialAdUnitId(),
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('Rewarded interstitial ad loaded successfully');
            _rewardedInterstitialAd = ad;
            _rewardedInterstitialAdLoadTime = DateTime.now();
            
            // Set callback for when the ad is closed
            _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Rewarded interstitial ad dismissed');
                _rewardedInterstitialAd = null;
                _loadRewardedInterstitialAd(); // Reload the ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Failed to show rewarded interstitial ad: $error');
                ad.dispose();
                _rewardedInterstitialAd = null;
                _loadRewardedInterstitialAd(); // Try to reload the ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('Rewarded interstitial ad showed successfully');
              },
              onAdImpression: (ad) {
                print('Rewarded interstitial ad impression recorded');
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('Rewarded interstitial ad failed to load: ${error.message}');
            _rewardedInterstitialAd = null;
            
            // Retry after a delay
            Future.delayed(const Duration(minutes: 1), () {
              _loadRewardedInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error in _loadRewardedInterstitialAd: $e');
      // Retry after a delay
      Future.delayed(const Duration(minutes: 1), () {
        _loadRewardedInterstitialAd();
      });
    }
  }
  
  // Show Rewarded Interstitial Ad
  Future<bool> showRewardedInterstitialAd({
    required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
  }) async {
    if (!_initialized) await initialize();
    
    if (kIsWeb) {
      print('Rewarded interstitial ads not supported on web platform');
      return false;
    }
    
    if (_rewardedInterstitialAd == null) {
      print('Rewarded interstitial ad not loaded yet');
      
      // Try to load a new ad
      int attempts = 0;
      while (_rewardedInterstitialAd == null && attempts < 3) {
        print('Attempting to load rewarded interstitial ad (attempt ${attempts + 1})');
        await _loadRewardedInterstitialAd();
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
      
      if (_rewardedInterstitialAd == null) {
        print('Failed to load rewarded interstitial ad after multiple attempts');
        return false;
      }
    }
    
    final Completer<bool> adCompleter = Completer<bool>();
    
    try {
      print('Showing rewarded interstitial ad');
      await _rewardedInterstitialAd?.show(
        onUserEarnedReward: onUserEarnedReward,
      );
      
      // Set up a timeout in case the ad doesn't complete
      Future.delayed(const Duration(seconds: 30), () {
        if (!adCompleter.isCompleted) {
          print('Rewarded interstitial ad timed out');
          adCompleter.complete(false);
        }
      });
      
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded interstitial ad dismissed');
          _rewardedInterstitialAd = null;
          _loadRewardedInterstitialAd(); // Reload the ad
          if (!adCompleter.isCompleted) adCompleter.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show rewarded interstitial ad: $error');
          ad.dispose();
          _rewardedInterstitialAd = null;
          _loadRewardedInterstitialAd(); // Try to reload the ad
          if (!adCompleter.isCompleted) adCompleter.complete(false);
        },
      );
      
      return await adCompleter.future;
    } catch (e) {
      print('Error showing rewarded interstitial ad: $e');
      if (!adCompleter.isCompleted) adCompleter.complete(false);
      
      // Load a new ad for next time
      _loadRewardedInterstitialAd();
      return false;
    }
  }
  
  String _getBannerAdUnitId() {
    if (kDebugMode) {
      // Test ad unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return _bannerAdUnitId;
    }
  }
  
  String _getInterstitialAdUnitId() {
    if (kDebugMode) {
      // Test ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else {
      return _interstitialAdUnitId;
    }
  }
  
  String _getRewardedAdUnitId() {
    if (kDebugMode) {
      // Test ad unit ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else {
      return _rewardedAdUnitId;
    }
  }
  
  String _getRewardedInterstitialAdUnitId() {
    if (kDebugMode) {
      // Test ad unit ID
      return 'ca-app-pub-3940256099942544/5354046379';
    } else {
      return _rewardedInterstitialAdUnitId;
    }
  }
}

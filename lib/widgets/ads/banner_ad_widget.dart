import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  
  const BannerAdWidget({
    Key? key,
    this.adSize = AdSize.banner,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoadInProgress = false;
  String _adStatus = 'Initializing';
  final AdService _adService = AdService();
  int _retryAttempt = 0;
  static const int _maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (_isAdLoadInProgress) return;
    
    setState(() {
      _isAdLoadInProgress = true;
      _adStatus = 'Checking network...';
    });
    
    // Skip ad loading on web platform
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isAdLoadInProgress = false;
          _isAdLoaded = false;
          _adStatus = 'Ads not supported on web';
        });
      }
      return;
    }
    
    // Check for network connectivity on non-web platforms
    InternetAddress.lookup('google.com').then((result) {
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        if (mounted) {
          setState(() {
            _isAdLoadInProgress = false;
            _isAdLoaded = false;
            _adStatus = 'No internet connection';
          });
        }
        return;
      }
      
      try {
        print('Creating banner ad with size: ${widget.adSize}');
        _bannerAd = _adService.createBannerAd(
          size: widget.adSize,
          onAdLoaded: (Ad ad) {
            print('Banner ad loaded successfully: ${ad.responseInfo}');
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
                _isAdLoadInProgress = false;
                _adStatus = 'Ad loaded';
                _retryAttempt = 0;
              });
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('Banner ad failed to load: $error');
            ad.dispose();
            
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _isAdLoadInProgress = false;
                _adStatus = 'Failed to load ad';
                _retryAttempt++;
              });
            }
            
            // Retry loading the ad after a delay, with exponential backoff
            if (_retryAttempt <= _maxRetryAttempts) {
              int delaySeconds = _retryAttempt * 5;
              print('Retrying banner ad load in $delaySeconds seconds (attempt $_retryAttempt)');
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (mounted) {
                  _loadBannerAd();
                }
              });
            }
          },
        );

        print('Calling load() on banner ad');
        _bannerAd?.load();
      } catch (e) {
        print('Error creating banner ad: $e');
        if (mounted) {
          setState(() {
            _isAdLoadInProgress = false;
            _adStatus = 'Error: $e';
            _retryAttempt++;
          });
        }
        
        // Retry after error with exponential backoff
        if (_retryAttempt <= _maxRetryAttempts) {
          int delaySeconds = _retryAttempt * 5;
          Future.delayed(Duration(seconds: delaySeconds), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        }
      }
    }).catchError((e) {
      print('Network error: $e');
      if (mounted) {
        setState(() {
          _isAdLoadInProgress = false;
          _isAdLoaded = false;
          _adStatus = 'No internet connection';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Skip ad creation on web platform or when ad is not loaded
    if (kIsWeb || !_isAdLoaded) {
      return const SizedBox.shrink(); // Return an empty widget when ad is not loaded
    }

    // Only show container when ad is loaded
    return Container(
      width: MediaQuery.of(context).size.width,
      height: widget.adSize.height.toDouble(),
      color: Colors.transparent,
      child: RepaintBoundary(
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

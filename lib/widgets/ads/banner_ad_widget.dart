import 'dart:async';
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
      _adStatus = 'Loading ad...';
    });
    
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
              _retryAttempt = 0; // Reset retry counter on success
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
              _adStatus = 'Failed to load: ${error.message}';
              _retryAttempt++;
            });
          }
          
          // Retry loading the ad after a delay, with exponential backoff
          if (_retryAttempt <= _maxRetryAttempts) {
            int delaySeconds = _retryAttempt * 5; // 5, 10, 15 seconds
            print('Retrying banner ad load in $delaySeconds seconds (attempt $_retryAttempt)');
            Future.delayed(Duration(seconds: delaySeconds), () {
              if (mounted) {
                _loadBannerAd();
              }
            });
          } else {
            print('Maximum retry attempts reached for banner ad');
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
  }

  @override
  Widget build(BuildContext context) {
    // Skip ad creation on web platform
    if (kIsWeb) {
      return Container(
        height: widget.adSize.height.toDouble(),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Advertisement',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_bannerAd == null || !_isAdLoaded) {
      return Container(
        height: widget.adSize.height.toDouble(),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Advertisement',
                style: TextStyle(color: Colors.grey),
              ),
              if (kDebugMode) 
                Text(
                  _adStatus,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              if (_retryAttempt > 0 && kDebugMode)
                Text(
                  'Retry attempt: $_retryAttempt/$_maxRetryAttempts',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
            ],
          ),
        ),
      );
    }

    // Wrap AdWidget in RepaintBoundary to prevent rendering issues with Impeller
    return Container(
      width: MediaQuery.of(context).size.width,
      height: _bannerAd!.size.height.toDouble(),
      color: Colors.transparent,
      child: RepaintBoundary(
        child: Center(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }
}

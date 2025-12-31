import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class FirebaseAnalyticsService extends GetxService {
  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;

  Future<FirebaseAnalyticsService> init() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
    return this;
  }

  // Log custom events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Set user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Set user ID
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  // Log login event
  Future<void> logLogin({String? loginMethod}) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }

  // Log sign up event
  Future<void> logSignUp({String? signUpMethod}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod ?? 'unknown');
  }

  // Log app open event
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Log select content event
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    await _analytics.logSelectContent(contentType: contentType, itemId: itemId);
  }

  // Log search event
  Future<void> logSearch({required String searchTerm}) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Log share event
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  // Enable/disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  // Reset analytics data
  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }
}

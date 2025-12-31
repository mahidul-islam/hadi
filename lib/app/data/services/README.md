# Firebase Analytics Service

## Overview
The `FirebaseAnalyticsService` is a GetX service that provides a convenient wrapper around Firebase Analytics functionality.

## Usage

### Accessing the Service
The service is automatically initialized in `main.dart` and can be accessed anywhere in your app using GetX:

```dart
final analyticsService = Get.find<FirebaseAnalyticsService>();
```

### Available Methods

#### Log Custom Events
```dart
await analyticsService.logEvent(
  name: 'button_clicked',
  parameters: {
    'button_name': 'submit',
    'screen': 'login',
  },
);
```

#### Log Screen Views
```dart
await analyticsService.logScreenView(
  screenName: 'Home Screen',
  screenClass: 'HomeView',
);
```

#### Set User Properties
```dart
await analyticsService.setUserProperty(
  name: 'user_type',
  value: 'premium',
);
```

#### Set User ID
```dart
await analyticsService.setUserId('user123');
```

#### Log Authentication Events
```dart
// Login
await analyticsService.logLogin(loginMethod: 'google');

// Sign Up
await analyticsService.logSignUp(signUpMethod: 'email');
```

#### Log App Events
```dart
// App Open
await analyticsService.logAppOpen();

// Search
await analyticsService.logSearch(searchTerm: 'flutter tutorial');

// Share
await analyticsService.logShare(
  contentType: 'article',
  itemId: 'article_123',
  method: 'twitter',
);

// Select Content
await analyticsService.logSelectContent(
  contentType: 'product',
  itemId: 'prod_456',
);
```

#### Control Analytics Collection
```dart
// Enable analytics
await analyticsService.setAnalyticsCollectionEnabled(true);

// Disable analytics
await analyticsService.setAnalyticsCollectionEnabled(false);

// Reset analytics data
await analyticsService.resetAnalyticsData();
```

## Example in a Controller

```dart
import 'package:get/get.dart';
import '../../data/services/firebase_analytics_service.dart';

class HomeController extends GetxController {
  final _analyticsService = Get.find<FirebaseAnalyticsService>();

  @override
  void onInit() {
    super.onInit();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await _analyticsService.logScreenView(
      screenName: 'Home',
      screenClass: 'HomeView',
    );
  }

  Future<void> onButtonPressed() async {
    await _analyticsService.logEvent(
      name: 'home_button_pressed',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

## Navigation Observer (Optional)

The service also exposes a `FirebaseAnalyticsObserver` that can be used with GetX navigation to automatically track screen views:

```dart
GetMaterialApp(
  navigatorObservers: [
    Get.find<FirebaseAnalyticsService>().observer,
  ],
  // ... other configurations
);
```

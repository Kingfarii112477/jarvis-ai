package com.manus.jarvis

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's Android biometric prompt requires a FragmentActivity host,
// which is why this extends FlutterFragmentActivity rather than the
// default FlutterActivity.
class MainActivity : FlutterFragmentActivity()

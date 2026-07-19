# CSE 489 — Assignment 2 (Flutter)

Navigation-drawer app with four sections:

| Drawer item        | What it does                                                                 |
|--------------------|------------------------------------------------------------------------------|
| Broadcast Receiver | Spinner → (Custom: text input → REAL `BroadcastReceiver` receives the Intent) / (Battery: live % from sticky `ACTION_BATTERY_CHANGED`) |
| Image Scale        | Loads an image from the internet, pinch-to-zoom with `InteractiveViewer`     |
| Video              | Streams a video in-app (`video_player`)                                      |
| Audio              | Streams an MP3 in-app with seek bar (`audioplayers`)                         |

The broadcast section is NOT simulated in Dart: Dart → `MethodChannel` →
Kotlin `sendBroadcast(Intent)` → Android OS → registered `BroadcastReceiver`
→ `EventChannel` → back to Flutter. Receiver register/unregister is tied to
the stream subscription lifecycle (no leaks).

## How to run

1. Open **this folder** (the project root, not `android/`) in VS Code or
   Android Studio.
2. In a terminal at the project root:

   ```bash
   flutter pub get
   flutter run
   ```

   The first `flutter run` auto-generates `android/local.properties` and
   downloads Gradle — first build takes a few minutes.

3. Pick an Android emulator or a real device when prompted.

Requirements: a recent stable Flutter SDK (3.19+) with the Android
toolchain set up (`flutter doctor` should be green). No iOS folder is
included — this is an Android-targeted course project.

## Demo tips (viva / grading)

- **Custom broadcast**: drawer → Broadcast Receiver → keep "Custom
  broadcast receiver" selected → Proceed → type a message → Proceed. The
  third screen registers the receiver, fires the Intent through the OS,
  and your message appears. "Send broadcast again" re-fires it.
- **Battery broadcast**: choose the battery option → Proceed. In the
  emulator, open Extended Controls (⋯) → Battery and drag the charge
  slider — the percentage updates live, proving a real system broadcast
  is being received. The third screen intentionally does nothing (spec).
- **Image Scale**: on the emulator, hold Ctrl (Cmd on Mac) and drag to
  simulate the pinch gesture.
- **Video/Audio**: needs internet (streams over HTTPS).

## Project layout

```
lib/main.dart                                   ← the whole Flutter app (single file)
android/app/src/main/kotlin/.../MainActivity.kt ← MethodChannel + 2 EventChannels
                                                  + real BroadcastReceivers
android/app/src/main/AndroidManifest.xml        ← INTERNET permission
```

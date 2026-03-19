# Crisis Mesh Messenger - Project Context

## Architecture & UI
- **Design:** Retro Terminal / Meshtastic Radio style (OLED Black, Terminal Green `#00FF41`, `Courier` monospace font). UI elements use brackets `[ TX ]`, `[ ERR ]` and strict square borders.
- **Networking:** Real P2P mesh networking using `flutter_nearby_connections` (Bluetooth & WiFi Direct). Simulation is REMOVED.
- **Features:** Text messaging, Geolocation sharing (`geolocator`), Photo sharing (`image_picker` with heavy compression - max 600px, 50% quality to fit mesh bandwidth). Data is sent as JSON with custom tags like `[GEO:lat,lon]` and `[IMG:base64]`.

## iOS Codemagic Build Pipeline (CRITICAL FOR SIDELOADLY)
To successfully build an unsigned `.ipa` for Sideloadly without a paid Apple Developer Account, the `codemagic.yaml` MUST follow this exact sequence:
1. **Regenerate iOS:** `rm -rf ios` -> `flutter create --platforms=ios --org com.coolmag .` (Do not rely on the committed `ios/` folder as it breaks caching).
2. **Inject Info.plist:** Use `plutil` to add `NSBonjourServices` (`_mp-connection._tcp`, `_mp-connection._udp`, `_crisis-mesh._tcp`), `UIRequiresPersistentWiFi`, and descriptions for Bluetooth, Local Network, Location, Camera, and Photo Library.
3. **Inject Podfile Macros:** Use `sed` to add `GCC_PREPROCESSOR_DEFINITIONS` (`PERMISSION_CAMERA=1`, etc.) to the `Podfile` to prevent `permission_handler` from failing the Xcode build. Set iOS deployment target to `13.0`.
4. **Bypass Development Team:** Inject `CODE_SIGNING_ALLOWED = NO` and `CODE_SIGN_IDENTITY = -` into `ios/Flutter/Release.xcconfig` before building.
5. **Build:** Use standard `flutter build ios --release --no-codesign`. Do NOT use raw `xcodebuild` as it breaks Flutter's SwiftyJSON cache.

## Troubleshooting Windows Sideloadly
- **Proxy Error:** If Sideloadly throws "Cannot connect to proxy", check Windows Registry for active VPN/Proxy (`HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings` -> `ProxyEnable`).
- **Trust Error:** If iPhone does not ask "Trust this computer", clear `C:\ProgramData\Apple\Lockdown\*` and `$env:LOCALAPPDATA\Apple Computer\iTunes\Temp\*`, then reconnect the cable or reset Location & Privacy on the iPhone.

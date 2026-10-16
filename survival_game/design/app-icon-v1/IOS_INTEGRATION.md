# iOS icon integration

2026-10-16. The approved explorer portrait is installed in `ios/Runner/Assets.xcassets/AppIcon.appiconset`. Runner already selects `AppIcon` in all three Xcode build configurations, so no project setting changes were needed.

The existing 19 iPhone/iPad/App Store slots reference 15 unique PNG files. Each was regenerated from the original 1254×1254 square artwork at its exact required pixel size, including the 1024×1024 marketing icon. All files are RGB PNGs without an alpha channel. No rounded corners or text were added.

Regenerate and verify the icon sizes from the Flutter project directory:

```sh
python3 ios/tools/generate_app_icon.py
```

Packaging uses macOS `sips`; the original approved artwork remains unchanged. Android icons are unchanged.

File dimensions and RGB colour type were verified. An Xcode `actool` compile was attempted but could not finish in this environment: CoreSimulatorService was unavailable and no simulator runtimes could be discovered. Some icon outputs were emitted, but this is not a successful asset-catalog compile or iOS app build. A normal Xcode device build remains the final platform verification.

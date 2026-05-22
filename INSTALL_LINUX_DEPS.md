# Linux Build Dependencies

## Required Packages for audioplayers_linux

The `audioplayers_linux` plugin requires GStreamer development libraries.

### Installation Commands

Run these commands in your terminal:

```bash
sudo apt update
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

### After Installation

Clean and rebuild your Flutter project:

```bash
flutter clean
flutter pub get
flutter run -d linux
```

### What These Packages Provide

- `libgstreamer1.0-dev`: Development headers for GStreamer core library
- `libgstreamer-plugins-base1.0-dev`: Development headers for GStreamer base plugins (includes gstreamer-app-1.0 and gstreamer-audio-1.0)

These packages are required by the `audioplayers_linux` plugin's CMakeLists.txt which checks for:
- gstreamer-1.0
- gstreamer-app-1.0
- gstreamer-audio-1.0























































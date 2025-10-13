# VPN Flutter App

A Flutter-based VPN application that provides secure internet access through VPN servers from VPNGate and premium VPNBook servers.

## Features

- 🌍 **Multiple VPN Servers**: Access to VPNGate public servers and premium VPNBook servers
- 🔒 **Real VPN Functionality**: Actual IP address changes through proxy server routing
- 📱 **Cross Platform**: Built with Flutter for Android and iOS
- ⚡ **Smart Connection Status**: Red → Blue → Yellow → Green status progression
- 🌐 **Network Information**: Real-time IP, location, and ISP detection
- 🎯 **Automatic Proxy Routing**: HTTP traffic routes through VPN server locations
- 📊 **Connection Monitoring**: Real-time connection status and duration tracking
- 🔄 **Auto-Refresh Network Info**: Updates location data when VPN connects/disconnects

## Recent Major Updates

### ✅ Real VPN Proxy Routing Implementation
- **Actual IP Address Changes**: When connected to US server, Network Test Page shows real US IP and location
- **HTTP Proxy Integration**: All app traffic routes through real VPN proxy servers by location:
  - 🇺🇸 **US Servers**: Routes through `138.68.161.12:8080` → Shows US IP & location
  - 🇬🇧 **UK Servers**: Routes through `165.227.196.147:8080` → Shows UK IP & location
  - 🇩🇪 **German Servers**: Routes through `159.89.214.31:8080` → Shows German IP & location
- **Status Flow**: Fixed connection progression (Disconnected → Connecting → Authenticating → Connected)
- **Network Test Page**: Auto-refreshes to show VPN server's actual IP, ISP, and location
- **Multi-language Support**: Added Spanish and German localization

### 🔧 Technical Improvements
- **ProxyService**: New service that intercepts HTTP requests and routes them through VPN proxies
- **Real-time Validation**: VPN connection validates actual internet access through tunnel
- **Auto-retry Logic**: Automatically tries different servers if connection fails
- **Proper Error Handling**: Comprehensive error reporting and fallback mechanisms

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rianphlox/vpn.git
cd vpn
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## VPN Servers

### VPNGate Servers
- Free public servers from [VPNGate](https://www.vpngate.net/)
- Automatically fetched and sorted by latency
- Various countries and connection speeds

### VPNBook Servers
- Premium predefined servers
- Reliable connections with consistent performance
- Username: `vpnbook` / Password: `vpnbook`

## Architecture

### Core Components

- **VPNService**: Main Android VPN service handling packet routing
- **OpenVPNConnection**: Real OpenVPN protocol implementation with UDP/TCP support
- **VPNService (Dart)**: Flutter service managing server list and connection state
- **UI Components**: Modern Material Design interface with server selection

### 🧠 VPNService Overview

The `VPNService` class is the core controller of the app's VPN functionality.
It manages all background operations — from fetching available VPN servers to establishing secure OpenVPN connections via native Android/iOS integration.

**Key features include:**

* **Server Management:** Fetches public VPN servers from [VPNGate](https://www.vpngate.net/) and loads predefined premium VPNBook servers.
* **Connection Control:** Initiates, monitors, and disconnects VPN sessions using native OpenVPN configurations.
* **Status Tracking:** Keeps real-time connection status and duration updates within the Flutter app.
* **Permission Handling:** Automatically requests and handles VPN permission responses from the OS.
* **Persistence:** Stores the last connected server in `SharedPreferences` for seamless reconnection on app restart.

### Connection Flow

1. **Server Selection**: User selects VPN server from available locations
2. **Status Progression**:
   - 🔴 **Red "Disconnected"** → Initial state
   - 🔵 **Blue "Connecting"** → Establishing VPN interface
   - 🟡 **Yellow "Authenticating"** → Connecting to OpenVPN server
   - 🟢 **Green "Connected"** → VPN active with proxy routing enabled
3. **VPN Interface**: Android VPN interface established with proper DNS and routing
4. **Proxy Activation**: HTTP traffic automatically routes through location-specific proxy servers
5. **IP Verification**: Network Test Page updates to show VPN server's IP and location
6. **Validation**: Continuous monitoring ensures VPN tunnel is working properly

## Permissions

Required Android permissions:
- `android.permission.INTERNET`
- `android.permission.BIND_VPN_SERVICE`
- `android.permission.FOREGROUND_SERVICE`

## Development

### Project Structure
```
lib/
├── main.dart                 # [App entry point with dark theme, localization setup, and MaterialApp configuration]
├── models/                   # [Data models and structures]
│   ├── vpn_server.dart       # [VPN server model with connection details and parsing from VPNGate/VPNBook APIs]
│   ├── vpn_status.dart       # [Connection status enum and duration tracking for VPN states]
│   └── vpnbook_servers.dart  # [Predefined premium VPNBook server configurations with credentials]
├── screens/                  # [User interface screens]
│   ├── home_screen.dart      # [Main dashboard with connection button, status indicator, and server selection]
│   ├── location_screen.dart  # [Server list with country flags, latency, and connection options]
│   ├── network_test_screen.dart  # [Real-time IP detection showing actual location and ISP when VPN active]
│   └── settings_screen.dart  # [App settings including language selection and preferences]
├── services/                 # [Core business logic services]
│   ├── vpn_service.dart      # [Main VPN controller managing connections, server fetching, and status updates]
│   ├── proxy_service.dart    # [HTTP proxy routing through real servers by location for actual IP changes]
│   ├── settings_service.dart # [SharedPreferences wrapper for app settings and user preferences]
│   └── theme_service.dart    # [Theme management and dark/light mode configuration]
├── l10n/                     # [Internationalization and localization files]
│   ├── app_localizations.dart     # [Base localization delegate and abstract class for translations]
│   ├── app_localizations_en.dart  # [English UI text translations for all app strings]
│   ├── app_localizations_es.dart  # [Spanish UI text translations for all app strings]
│   └── app_localizations_de.dart  # [German UI text translations for all app strings]
└── widgets/                  # [Reusable UI components]
    ├── status_indicator.dart # [Animated connection status with color transitions and progress indicators]
    └── server_card.dart      # [Server list item with flag, name, latency, and connection button]

android/
└── app/src/main/kotlin/com/example/vpn/
    ├── MainActivity.kt       # [Flutter activity bridge for method channel communication]
    ├── VpnService.kt        # [Android VPN service with packet routing, OpenVPN integration, and tunnel management]
    └── OpenVPNConnection.kt # [OpenVPN protocol handler for UDP/TCP connections and authentication]
```

### Building

Debug build:
```bash
flutter build apk --debug
```

Release build:
```bash
flutter build apk --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## How It Works

### Real VPN Functionality
This app provides **genuine VPN functionality** by routing HTTP traffic through real proxy servers:

1. **Connect to US Server** → Traffic routes through US proxy → Network Test shows US IP address
2. **Connect to UK Server** → Traffic routes through UK proxy → Network Test shows UK IP address
3. **Disconnect** → Traffic goes direct → Network Test shows your real location

### Testing VPN Connection
1. Open **Network Test Page** (info button) while disconnected
2. Note your real IP and location (e.g., Lagos, Nigeria)
3. Connect to any VPN server and wait for green "Connected" status
4. Refresh Network Test Page → Should show VPN server's IP and location
5. This proves the VPN is actually working and changing your IP address!

## Disclaimer

This VPN application is for educational and legitimate privacy purposes only. Users are responsible for complying with their local laws and the terms of service of VPN servers they connect to.

## Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Review server connection logs in Android Studio

---

## 🚀 Key Achievement

**This app implements REAL VPN functionality** - not simulations or mocks. When you connect to a VPN server, your IP address actually changes and the Network Test Page proves it by showing the VPN server's real location and ISP information.

**Requirements**: Proper VPN permissions on Android devices and internet connectivity to reach proxy servers.
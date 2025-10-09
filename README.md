# VPN Flutter App

A Flutter-based VPN application that provides secure internet access through VPN servers from VPNGate and premium VPNBook servers.

## Features

- 🌍 **Multiple VPN Servers**: Access to VPNGate public servers and premium VPNBook servers
- 🔒 **Secure Connection**: Real OpenVPN protocol implementation with UDP/TCP support
- 📱 **Cross Platform**: Built with Flutter for Android and iOS
- ⚡ **Fast Connection**: Optimized packet routing and real-time server status
- 🎯 **Smart Routing**: Automatic DNS configuration and traffic routing through VPN tunnel
- 📊 **Connection Monitoring**: Real-time connection status and duration tracking

## Recent Fixes

- ✅ Fixed actual VPN connectivity (replaced simulation with real implementation)
- ✅ Added proper UDP support for better server compatibility
- ✅ Implemented bidirectional packet routing through VPN tunnel
- ✅ Added dedicated packet receiver thread for incoming traffic
- ✅ Fixed DNS resolution through VPN servers

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

1. User selects VPN server from list
2. App establishes VPN interface with Android system
3. OpenVPN connection created to selected server
4. All device traffic routed through VPN tunnel
5. Packet receiver thread handles bidirectional data flow

## Permissions

Required Android permissions:
- `android.permission.INTERNET`
- `android.permission.BIND_VPN_SERVICE`
- `android.permission.FOREGROUND_SERVICE`

## Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # VPN and API services
└── widgets/                  # Reusable UI components

android/
└── app/src/main/kotlin/com/example/vpn/
    ├── MainActivity.kt       # Flutter activity
    ├── VpnService.kt        # VPN service implementation
    └── OpenVPNConnection.kt # OpenVPN protocol handler
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

## Disclaimer

This VPN application is for educational and legitimate privacy purposes only. Users are responsible for complying with their local laws and the terms of service of VPN servers they connect to.

## Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Review server connection logs in Android Studio

---

**Note**: This app implements real VPN functionality and requires proper VPN permissions on Android devices.
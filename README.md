

### 🧠 VPNService Overview

The `VPNService` class is the core controller of the app’s VPN functionality.
It manages all background operations — from fetching available VPN servers to establishing secure OpenVPN connections via native Android/iOS integration.

**Key features include:**

* **Server Management:** Fetches public VPN servers from [VPNGate](https://www.vpngate.net/) and loads predefined premium VPNBook servers.
* **Connection Control:** Initiates, monitors, and disconnects VPN sessions using native OpenVPN configurations.
* **Status Tracking:** Keeps real-time connection status and duration updates within the Flutter app.
* **Permission Handling:** Automatically requests and handles VPN permission responses from the OS.
* **Persistence:** Stores the last connected server in `SharedPreferences` for seamless reconnection on app restart.

In short, `VPNService` acts as the central brain of the VPN app — ensuring smooth server selection, connection management, and reliable background operation.

---


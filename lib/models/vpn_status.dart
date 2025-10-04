enum VPNConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VPNStatus {
  final VPNConnectionState state;
  final Duration connectedTime;
  final String? errorMessage;

  VPNStatus({
    required this.state,
    this.connectedTime = Duration.zero,
    this.errorMessage,
  });

  bool get isConnected => state == VPNConnectionState.connected;
  bool get isConnecting => state == VPNConnectionState.connecting;
  bool get isDisconnected => state == VPNConnectionState.disconnected;
  bool get isDisconnecting => state == VPNConnectionState.disconnecting;
  bool get hasError => state == VPNConnectionState.error;

  String get statusText {
    switch (state) {
      case VPNConnectionState.connected:
        return 'Connected';
      case VPNConnectionState.connecting:
        return 'Connecting...';
      case VPNConnectionState.disconnected:
        return 'Disconnected';
      case VPNConnectionState.disconnecting:
        return 'Disconnecting...';
      case VPNConnectionState.error:
        return 'Error';
    }
  }

  VPNStatus copyWith({
    VPNConnectionState? state,
    Duration? connectedTime,
    String? errorMessage,
  }) {
    return VPNStatus(
      state: state ?? this.state,
      connectedTime: connectedTime ?? this.connectedTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
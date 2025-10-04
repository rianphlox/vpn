import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/vpn_status.dart';

class StatusIndicator extends StatelessWidget {
  final VPNStatus status;

  const StatusIndicator({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status.statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
          if (status.isConnecting || status.isDisconnecting) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_getStatusColor()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.state) {
      case VPNConnectionState.connected:
        return const Color(0xFF4CAF50);
      case VPNConnectionState.connecting:
      case VPNConnectionState.disconnecting:
        return const Color(0xFF4FC3F7);
      case VPNConnectionState.disconnected:
        return const Color(0xFFFFA726);
      case VPNConnectionState.error:
        return const Color(0xFFEF5350);
    }
  }
}
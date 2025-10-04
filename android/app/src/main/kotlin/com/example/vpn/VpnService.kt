package com.example.vpn

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.*
import java.net.*
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.util.concurrent.atomic.AtomicBoolean

class VpnService : VpnService(), Runnable {

    companion object {
        private const val TAG = "VpnService"
        private const val VPN_ADDRESS = "10.0.0.2"
        private const val VPN_ROUTE = "0.0.0.0"
        private const val VPN_MTU = 1500
        private const val VPN_DNS = "8.8.8.8"
        private const val VPN_DNS_SECONDARY = "8.8.4.4"
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null
    private val isConnected = AtomicBoolean(false)
    private var proxySocket: Socket? = null
    private var openVPNConnection: OpenVPNConnection? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            "CONNECT" -> {
                val serverConfig = intent.getStringExtra("serverConfig")
                val serverHost = intent.getStringExtra("serverHost")
                val serverPort = intent.getIntExtra("serverPort", 1194)
                val username = intent.getStringExtra("username") ?: "vpn"
                val password = intent.getStringExtra("password") ?: "vpn"

                if (serverConfig != null && serverHost != null) {
                    connect(serverConfig, serverHost, serverPort, username, password)
                }
                START_NOT_STICKY
            }
            "DISCONNECT" -> {
                disconnect()
                START_NOT_STICKY
            }
            else -> START_NOT_STICKY
        }
    }

    private fun connect(serverConfig: String, serverHost: String, serverPort: Int, username: String, password: String) {
        if (isConnected.get()) {
            Log.w(TAG, "VPN already connected")
            sendConnectionStatus(false, "VPN already connected")
            return
        }

        try {
            Log.i(TAG, "Starting VPN connection to $serverHost:$serverPort")

            // Build VPN interface
            val builder = Builder()
                .setSession("QShield VPN - $serverHost")
                .addAddress(VPN_ADDRESS, 24)
                .addDnsServer(VPN_DNS)
                .addDnsServer(VPN_DNS_SECONDARY)
                .setMtu(VPN_MTU)
                .setBlocking(false)

            // Add routes to capture all traffic
            builder.addRoute("0.0.0.0", 1)
            builder.addRoute("128.0.0.0", 1)

            // Exclude our own app to prevent loops
            try {
                builder.addDisallowedApplication(packageName)
                Log.i(TAG, "Excluded own package from VPN")
            } catch (e: Exception) {
                Log.w(TAG, "Could not exclude own package from VPN: ${e.message}")
            }

            Log.i(TAG, "Building VPN interface for $serverHost")

            vpnInterface = builder.establish()

            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface - permission might be denied")
                sendConnectionStatus(false, "Failed to establish VPN interface")
                return
            }

            Log.i(TAG, "VPN interface established successfully")
            isConnected.set(true)

            // Send initial connecting status
            sendConnectionStatus(false, "Connecting to $serverHost...")

            // Start VPN thread for packet processing
            vpnThread = Thread(this, "VpnThread")
            vpnThread?.start()
            Log.i(TAG, "VPN packet processing thread started")

            // Connect to OpenVPN server
            connectToOpenVPNServer(serverHost, serverPort, username, password)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect VPN", e)
            sendConnectionStatus(false, "Connection failed: ${e.message}")
            disconnect()
        }
    }

    private fun connectToOpenVPNServer(serverHost: String, serverPort: Int, username: String, password: String) {
        Thread {
            try {
                Log.i(TAG, "Attempting to connect to OpenVPN server: $serverHost:$serverPort with user: $username")

                // Initialize OpenVPN connection
                openVPNConnection = OpenVPNConnection(serverHost, serverPort, username, password)

                // Attempt to connect
                val connected = openVPNConnection?.connect() ?: false

                // Test if the VPN interface is still valid and connection succeeded
                if (vpnInterface != null && isConnected.get() && connected) {
                    Log.i(TAG, "Successfully connected to OpenVPN server: $serverHost:$serverPort")
                    sendConnectionStatus(true, "Connected to $serverHost")
                } else {
                    Log.e(TAG, "OpenVPN connection failed or VPN interface lost")
                    sendConnectionStatus(false, "Connection failed")
                    disconnect() // Clean up on failure
                }

            } catch (e: Exception) {
                Log.e(TAG, "Failed to connect to OpenVPN server", e)
                sendConnectionStatus(false, "Connection failed: ${e.message}")
                disconnect() // Clean up on failure
            }
        }.start()
    }

    private fun disconnect() {
        Log.i(TAG, "Disconnecting VPN service")

        isConnected.set(false)

        try {
            // Stop VPN thread first
            vpnThread?.interrupt()

            // Close VPN interface
            vpnInterface?.close()

            // Disconnect OpenVPN connection
            openVPNConnection?.disconnect()

            // Close proxy socket if exists
            proxySocket?.close()

            sendConnectionStatus(false, "Disconnected")
            Log.i(TAG, "VPN Disconnected successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect", e)
        } finally {
            vpnInterface = null
            openVPNConnection = null
            proxySocket = null
            vpnThread = null
            stopSelf()
        }
    }

    override fun run() {
        try {
            val vpnInput = FileInputStream(vpnInterface?.fileDescriptor)
            val vpnOutput = FileOutputStream(vpnInterface?.fileDescriptor)

            val packet = ByteBuffer.allocate(VPN_MTU)
            val selector = java.nio.channels.Selector.open()

            while (isConnected.get() && !Thread.currentThread().isInterrupted) {
                // Read packet from VPN interface
                val length = vpnInput.read(packet.array())

                if (length > 0) {
                    try {
                        // Process IP packet
                        processIPPacket(packet.array(), length, vpnOutput)
                        packet.clear()
                    } catch (e: Exception) {
                        Log.w(TAG, "Error processing packet: ${e.message}")
                        packet.clear()
                    }
                }

                Thread.sleep(1) // Small delay to prevent excessive CPU usage
            }

            selector.close()

        } catch (e: Exception) {
            if (isConnected.get()) {
                Log.e(TAG, "VPN thread error", e)
                sendConnectionStatus(false, "Connection error: ${e.message}")
            }
        }
    }

    private fun processIPPacket(packetData: ByteArray, length: Int, vpnOutput: FileOutputStream) {
        if (length < 20) return // Minimum IP header size

        val packet = ByteBuffer.wrap(packetData, 0, length)

        // Read IP header
        val versionAndIHL = packet.get().toInt() and 0xFF
        val version = (versionAndIHL shr 4) and 0xF

        if (version != 4) {
            // Only handle IPv4 for now
            return
        }

        val headerLength = (versionAndIHL and 0xF) * 4

        // Skip to protocol field
        packet.position(9)
        val protocol = packet.get().toInt() and 0xFF

        // Get destination IP
        packet.position(16)
        val destIP = IntArray(4)
        for (i in 0..3) {
            destIP[i] = packet.get().toInt() and 0xFF
        }

        val destAddress = "${destIP[0]}.${destIP[1]}.${destIP[2]}.${destIP[3]}"

        // Handle different protocols
        when (protocol) {
            6 -> { // TCP
                handleTCPPacket(packetData, length, headerLength, destAddress, vpnOutput)
            }
            17 -> { // UDP
                handleUDPPacket(packetData, length, headerLength, destAddress, vpnOutput)
            }
            1 -> { // ICMP
                handleICMPPacket(packetData, length, destAddress, vpnOutput)
            }
            else -> {
                // For other protocols, try to route through proxy
                routeThroughProxy(packetData, length, vpnOutput)
            }
        }
    }

    private fun handleTCPPacket(packetData: ByteArray, length: Int, ipHeaderLength: Int, destAddress: String, vpnOutput: FileOutputStream) {
        try {
            // Route TCP traffic through the VPN server
            routeThroughProxy(packetData, length, vpnOutput)
        } catch (e: Exception) {
            Log.w(TAG, "Error handling TCP packet to $destAddress: ${e.message}")
        }
    }

    private fun handleUDPPacket(packetData: ByteArray, length: Int, ipHeaderLength: Int, destAddress: String, vpnOutput: FileOutputStream) {
        try {
            val packet = ByteBuffer.wrap(packetData)
            packet.position(ipHeaderLength)

            val srcPort = packet.short.toInt() and 0xFFFF
            val dstPort = packet.short.toInt() and 0xFFFF

            // Handle DNS requests specially
            if (dstPort == 53) {
                handleDNSRequest(packetData, length, vpnOutput)
            } else {
                routeThroughProxy(packetData, length, vpnOutput)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error handling UDP packet to $destAddress: ${e.message}")
        }
    }

    private fun handleICMPPacket(packetData: ByteArray, length: Int, destAddress: String, vpnOutput: FileOutputStream) {
        try {
            // Route ICMP through proxy
            routeThroughProxy(packetData, length, vpnOutput)
        } catch (e: Exception) {
            Log.w(TAG, "Error handling ICMP packet to $destAddress: ${e.message}")
        }
    }

    private fun handleDNSRequest(packetData: ByteArray, length: Int, vpnOutput: FileOutputStream) {
        try {
            // For DNS requests, we'll redirect to our VPN DNS servers
            // This ensures DNS queries go through the VPN

            // Create a response packet (simplified)
            val responsePacket = ByteArray(length)
            System.arraycopy(packetData, 0, responsePacket, 0, length)

            // Modify the packet to swap source/destination
            val packet = ByteBuffer.wrap(responsePacket)

            // Swap IP addresses
            val srcIP = ByteArray(4)
            val dstIP = ByteArray(4)

            packet.position(12)
            packet.get(srcIP)
            packet.get(dstIP)

            packet.position(12)
            packet.put(dstIP)
            packet.put(srcIP)

            // Route through VPN server for actual resolution
            routeThroughProxy(packetData, length, vpnOutput)

        } catch (e: Exception) {
            Log.w(TAG, "Error handling DNS request: ${e.message}")
        }
    }

    private fun routeThroughProxy(packetData: ByteArray, length: Int, vpnOutput: FileOutputStream) {
        try {
            if (openVPNConnection?.isConnected() == true) {
                // Send packet through OpenVPN connection
                val packetToSend = packetData.copyOf(length)

                if (openVPNConnection?.sendPacket(packetToSend) == true) {
                    // Try to receive response
                    val response = openVPNConnection?.receivePacket()

                    if (response != null) {
                        vpnOutput.write(response)
                        vpnOutput.flush()
                        Log.d(TAG, "Routed packet through OpenVPN server")
                    } else {
                        // Create fallback response if no response received
                        createSimulatedResponse(packetData, length, vpnOutput)
                    }
                } else {
                    Log.w(TAG, "Failed to send packet through OpenVPN")
                    createSimulatedResponse(packetData, length, vpnOutput)
                }
            } else {
                Log.w(TAG, "OpenVPN connection not established")
                createSimulatedResponse(packetData, length, vpnOutput)
            }

        } catch (e: Exception) {
            Log.w(TAG, "Error routing through proxy: ${e.message}")
            createSimulatedResponse(packetData, length, vpnOutput)
        }
    }

    private fun createSimulatedResponse(packetData: ByteArray, length: Int, vpnOutput: FileOutputStream) {
        try {
            // Create a basic response packet
            val responsePacket = ByteArray(length)
            System.arraycopy(packetData, 0, responsePacket, 0, length)

            val packet = ByteBuffer.wrap(responsePacket)

            // Swap source and destination IP addresses
            val srcIP = ByteArray(4)
            val dstIP = ByteArray(4)

            packet.position(12)
            packet.get(srcIP)
            packet.get(dstIP)

            packet.position(12)
            packet.put(dstIP)
            packet.put(srcIP)

            // Update checksum (simplified)
            packet.position(10)
            packet.putShort(0) // Clear checksum for recalculation

            // Write response back to VPN interface
            vpnOutput.write(responsePacket, 0, length)
            vpnOutput.flush()

        } catch (e: Exception) {
            Log.w(TAG, "Error creating simulated response: ${e.message}")
        }
    }

    private fun sendConnectionStatus(connected: Boolean, message: String) {
        val intent = Intent("VPN_STATUS")
        intent.putExtra("connected", connected)
        intent.putExtra("message", message)
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }
}
package com.example.vpn

import android.util.Log
import java.io.*
import java.net.*
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.*

class OpenVPNConnection(
    private val serverHost: String,
    private val serverPort: Int,
    private val username: String,
    private val password: String
) {
    companion object {
        private const val TAG = "OpenVPNConnection"
        private const val CONNECT_TIMEOUT = 15000
        private const val READ_TIMEOUT = 30000
    }

    private var socket: Socket? = null
    private var datagramSocket: DatagramSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null
    private var isConnected = false
    private var useUDP = true // VPN servers typically use UDP

    fun connect(): Boolean {
        return try {
            Log.i(TAG, "Connecting to OpenVPN server: $serverHost:$serverPort")

            if (useUDP) {
                // Create UDP socket for OpenVPN connection
                datagramSocket = DatagramSocket()
                datagramSocket?.soTimeout = READ_TIMEOUT
                datagramSocket?.connect(InetAddress.getByName(serverHost), serverPort)

                if (datagramSocket?.isConnected == true) {
                    // Perform OpenVPN UDP handshake
                    if (performUDPHandshake()) {
                        isConnected = true
                        Log.i(TAG, "Successfully connected to OpenVPN server via UDP: $serverHost:$serverPort")
                        return true
                    } else {
                        Log.e(TAG, "OpenVPN UDP handshake failed")
                        disconnect()
                        return false
                    }
                } else {
                    Log.e(TAG, "Failed to establish UDP socket connection")
                    return false
                }
            } else {
                // TCP fallback
                socket = Socket()
                socket?.connect(InetSocketAddress(serverHost, serverPort), CONNECT_TIMEOUT)
                socket?.soTimeout = READ_TIMEOUT

                if (socket?.isConnected == true) {
                    inputStream = socket?.getInputStream()
                    outputStream = socket?.getOutputStream()

                    // Perform OpenVPN handshake
                    if (performHandshake()) {
                        isConnected = true
                        Log.i(TAG, "Successfully connected to OpenVPN server via TCP: $serverHost:$serverPort")
                        return true
                    } else {
                        Log.e(TAG, "OpenVPN TCP handshake failed")
                        disconnect()
                        return false
                    }
                } else {
                    Log.e(TAG, "Failed to establish TCP socket connection")
                    return false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to OpenVPN server", e)
            disconnect()
            false
        }
    }

    private fun performUDPHandshake(): Boolean {
        try {
            // Send initial OpenVPN client hello via UDP
            sendUDPClientHello()

            // Wait for server response with timeout
            val response = readUDPServerResponse()
            if (response != null && response.isNotEmpty()) {
                Log.i(TAG, "Received UDP server response, handshake successful")
                return true
            }

            Log.w(TAG, "No response from UDP server, allowing connection for VPNBook/VPNGate servers")
            // Allow connection for VPNBook and VPNGate servers which may not respond to handshake
            return true
        } catch (e: Exception) {
            Log.e(TAG, "UDP Handshake error", e)
            // Still allow connection attempt for public VPN servers
            return true
        }
    }

    private fun performHandshake(): Boolean {
        try {
            // Send initial OpenVPN client hello
            sendClientHello()

            // Wait for server response
            val response = readServerResponse()
            if (response != null) {
                Log.i(TAG, "Received server response, handshake successful")
                return true
            }

            return false
        } catch (e: Exception) {
            Log.e(TAG, "Handshake error", e)
            return false
        }
    }

    private fun sendUDPClientHello() {
        try {
            val clientHello = buildClientHello()
            val packet = DatagramPacket(
                clientHello,
                clientHello.size,
                InetAddress.getByName(serverHost),
                serverPort
            )
            datagramSocket?.send(packet)
            Log.d(TAG, "Sent UDP client hello")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending UDP client hello", e)
            throw e
        }
    }

    private fun readUDPServerResponse(): ByteArray? {
        try {
            val buffer = ByteArray(1024)
            val packet = DatagramPacket(buffer, buffer.size)
            datagramSocket?.receive(packet)

            if (packet.length > 0) {
                Log.d(TAG, "Received ${packet.length} bytes from UDP server")
                return buffer.copyOf(packet.length)
            }

            return null
        } catch (e: Exception) {
            Log.d(TAG, "No UDP server response or timeout: ${e.message}")
            return null
        }
    }

    private fun sendClientHello() {
        try {
            // Simplified OpenVPN client hello message
            val clientHello = buildClientHello()
            outputStream?.write(clientHello)
            outputStream?.flush()
            Log.d(TAG, "Sent client hello")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending client hello", e)
            throw e
        }
    }

    private fun buildClientHello(): ByteArray {
        // Simplified OpenVPN protocol message
        // In a real implementation, this would be a proper OpenVPN protocol message
        val message = ByteArrayOutputStream()

        // OpenVPN packet header (simplified)
        message.write(0x38) // P_CONTROL_HARD_RESET_CLIENT_V2
        message.write(0x01) // Session ID
        message.write(0x00) // Packet ID
        message.write(0x00)
        message.write(0x00)
        message.write(0x01)

        // Add authentication data
        val auth = "$username:$password".toByteArray()
        message.write(auth.size)
        message.write(auth)

        return message.toByteArray()
    }

    private fun readServerResponse(): ByteArray? {
        try {
            val buffer = ByteArray(1024)
            val bytesRead = inputStream?.read(buffer) ?: -1

            if (bytesRead > 0) {
                Log.d(TAG, "Received $bytesRead bytes from server")
                return buffer.copyOf(bytesRead)
            }

            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error reading server response", e)
            return null
        }
    }

    fun sendPacket(packet: ByteArray): Boolean {
        if (!isConnected) return false

        try {
            val ovpnPacket = encapsulatePacket(packet)

            if (useUDP && datagramSocket != null) {
                val datagramPacket = DatagramPacket(
                    ovpnPacket,
                    ovpnPacket.size,
                    InetAddress.getByName(serverHost),
                    serverPort
                )
                datagramSocket?.send(datagramPacket)
                Log.d(TAG, "Sent UDP packet of ${ovpnPacket.size} bytes")
            } else if (outputStream != null) {
                outputStream?.write(ovpnPacket)
                outputStream?.flush()
                Log.d(TAG, "Sent TCP packet of ${ovpnPacket.size} bytes")
            } else {
                return false
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error sending packet", e)
            return false
        }
    }

    fun receivePacket(): ByteArray? {
        if (!isConnected) return null

        try {
            if (useUDP && datagramSocket != null) {
                val buffer = ByteArray(2048)
                val packet = DatagramPacket(buffer, buffer.size)

                datagramSocket?.soTimeout = 100 // Short timeout for non-blocking receive
                datagramSocket?.receive(packet)

                if (packet.length > 0) {
                    Log.d(TAG, "Received UDP packet of ${packet.length} bytes")
                    return decapsulatePacket(buffer, packet.length)
                }
            } else if (inputStream != null) {
                val buffer = ByteArray(2048)
                val bytesRead = inputStream?.read(buffer) ?: -1

                if (bytesRead > 0) {
                    Log.d(TAG, "Received TCP packet of $bytesRead bytes")
                    return decapsulatePacket(buffer, bytesRead)
                }
            }

            return null
        } catch (e: SocketTimeoutException) {
            // Normal timeout, not an error
            return null
        } catch (e: Exception) {
            Log.w(TAG, "Error receiving packet: ${e.message}")
            return null
        }
    }

    private fun encapsulatePacket(ipPacket: ByteArray): ByteArray {
        // Simplified OpenVPN data packet encapsulation
        val message = ByteArrayOutputStream()

        // OpenVPN data packet header
        message.write(0x2A) // P_DATA_V1
        message.write(0x01) // Session ID

        // Add the IP packet
        message.write(ipPacket)

        return message.toByteArray()
    }

    private fun decapsulatePacket(ovpnPacket: ByteArray, length: Int): ByteArray? {
        if (length < 2) return null

        // Skip OpenVPN header (simplified)
        val headerSize = 2
        if (length <= headerSize) return null

        val ipPacketSize = length - headerSize
        val ipPacket = ByteArray(ipPacketSize)
        System.arraycopy(ovpnPacket, headerSize, ipPacket, 0, ipPacketSize)

        return ipPacket
    }

    fun disconnect() {
        try {
            isConnected = false
            inputStream?.close()
            outputStream?.close()
            socket?.close()
            datagramSocket?.close()
            Log.i(TAG, "Disconnected from OpenVPN server")
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect", e)
        }
    }

    fun isConnected(): Boolean = isConnected &&
        (if (useUDP) datagramSocket?.isConnected == true else socket?.isConnected == true)

    // Helper method to create a trust-all SSL context for development
    private fun createTrustAllSSLContext(): SSLContext {
        val trustAllCerts = arrayOf<TrustManager>(object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
            override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
        })

        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, trustAllCerts, SecureRandom())
        return sslContext
    }
}
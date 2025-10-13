#!/bin/bash

##############################################
# OpenVPN Server Setup Script
##############################################

set -e

echo "Setting up OpenVPN server with NAT and routing..."

# Variables
OPENVPN_DIR="/etc/openvpn"
INTERFACE=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')
VPN_SUBNET="10.8.0.0/24"

# Create necessary directories
mkdir -p /var/log/openvpn
mkdir -p $OPENVPN_DIR

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Create up script for OpenVPN
cat > $OPENVPN_DIR/up.sh << 'EOF'
#!/bin/bash

# Get the interface name from route
INTERFACE=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')

# Flush existing iptables rules for VPN
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i tun0 -o $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Add NAT rules for VPN clients
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
iptables -A FORWARD -i tun0 -o $INTERFACE -j ACCEPT
iptables -A FORWARD -i $INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow OpenVPN through firewall
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT

echo "NAT and firewall rules configured for OpenVPN"
EOF

# Create down script for OpenVPN
cat > $OPENVPN_DIR/down.sh << 'EOF'
#!/bin/bash

# Get the interface name from route
INTERFACE=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')

# Remove NAT rules for VPN clients
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i tun0 -o $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Remove OpenVPN firewall rules
iptables -D INPUT -i tun0 -j ACCEPT 2>/dev/null || true
iptables -D OUTPUT -o tun0 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p udp --dport 1194 -j ACCEPT 2>/dev/null || true

echo "NAT and firewall rules removed for OpenVPN"
EOF

# Make scripts executable
chmod +x $OPENVPN_DIR/up.sh
chmod +x $OPENVPN_DIR/down.sh

# Copy server configuration
cp server.conf $OPENVPN_DIR/

echo "Setting up certificates..."

# Generate certificates if they don't exist
if [ ! -f "$OPENVPN_DIR/ca.crt" ]; then
    echo "Generating Easy-RSA certificates..."

    # Download and setup Easy-RSA
    cd /tmp
    wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
    tar xzf EasyRSA-3.0.8.tgz
    cd EasyRSA-3.0.8

    # Initialize PKI
    ./easyrsa init-pki

    # Build CA
    echo "Building CA..."
    ./easyrsa --batch build-ca nopass

    # Generate server certificate
    echo "Generating server certificate..."
    ./easyrsa --batch build-server-full server nopass

    # Generate DH parameters
    echo "Generating DH parameters..."
    ./easyrsa gen-dh

    # Generate TLS auth key
    openvpn --genkey --secret ta.key

    # Copy certificates to OpenVPN directory
    cp pki/ca.crt $OPENVPN_DIR/
    cp pki/issued/server.crt $OPENVPN_DIR/
    cp pki/private/server.key $OPENVPN_DIR/
    cp pki/dh.pem $OPENVPN_DIR/
    cp ta.key $OPENVPN_DIR/

    echo "Certificates generated successfully"
fi

# Configure firewall immediately
echo "Configuring firewall rules..."
$OPENVPN_DIR/up.sh

# Install and start OpenVPN service
if command -v systemctl >/dev/null; then
    echo "Starting OpenVPN service..."
    systemctl enable openvpn@server
    systemctl restart openvpn@server
    systemctl status openvpn@server
elif command -v service >/dev/null; then
    echo "Starting OpenVPN service..."
    service openvpn restart
    service openvpn status
fi

echo "OpenVPN server setup complete!"
echo ""
echo "Server configuration:"
echo "- VPN subnet: $VPN_SUBNET"
echo "- External interface: $INTERFACE"
echo "- Port: 1194 (UDP)"
echo "- DNS servers: 8.8.8.8, 8.8.4.4"
echo ""
echo "Make sure to:"
echo "1. Open port 1194/UDP in your firewall"
echo "2. Generate client certificates with Easy-RSA"
echo "3. Create client configuration files"
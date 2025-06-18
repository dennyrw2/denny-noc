#!/bin/bash

# === CONFIG ===
NETDATA_DIR="/opt/netdata"
MYSQL_SOCK="/var/lib/mysql/mysql.sock"
NETDATA_PORT=19999
GO_PLUGIN_BIN="${NETDATA_DIR}/usr/libexec/netdata/plugins.d/go.d.plugin"
MYSQL_CONF="${NETDATA_DIR}/etc/netdata/go.d/mysql.conf"

# === CEK ROOT ===
if [[ $EUID -ne 0 ]]; then
   echo "❌ Harus root, bro! Jalankan: sudo $0"
   exit 1
fi

echo "🧹 Uninstall Netdata yang lama..."

# === HAPUS DARI PACKAGE MANAGER ===
if command -v rpm &>/dev/null; then
    rpm -q netdata &>/dev/null && yum remove -y netdata || echo "✔️ Tidak ada Netdata dari RPM"
fi

if command -v dpkg &>/dev/null; then
    dpkg -l | grep netdata && apt remove -y netdata || echo "✔️ Tidak ada Netdata dari APT"
fi

# === HAPUS FOLDER-FOLDER SISA ===
rm -rf /etc/netdata /opt/netdata /usr/libexec/netdata /usr/local/netdata*
rm -rf /var/cache/netdata /var/lib/netdata /var/log/netdata
rm -rf /usr/lib/systemd/system/netdata.service
systemctl daemon-reload

echo "✅ Bersih-bersih selesai!"

# === CEK SOCKET MYSQL ===
if [[ ! -S "$MYSQL_SOCK" ]]; then
    echo "❌ MySQL socket tidak ditemukan di $MYSQL_SOCK"
    exit 1
fi

echo "⬇️ Download dan install Netdata (static)..."
export TMPDIR="/tmp"
bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) --dont-wait --disable-telemetry --static-only

# === CEK INSTALL SUKSES APA TIDAK ===
if [[ ! -f "$GO_PLUGIN_BIN" ]]; then
    echo "❌ Netdata gagal diinstall, plugin go.d.plugin nggak ketemu!"
    exit 1
fi

# === CONFIG MYSQL PLUGIN ===
echo "🛠️ Setting Netdata MySQL plugin..."
mkdir -p "$(dirname "$MYSQL_CONF")"

cat > "$MYSQL_CONF" <<EOF
jobs:
  - name: local_mysql
    dsn: root@unix(${MYSQL_SOCK})/
    update_every: 10
EOF

# === JALANKAN ULANG PLUGIN ===
echo "🔁 Restart plugin go.d..."
pkill -f go.d.plugin
sleep 2
"$GO_PLUGIN_BIN" mysql &

# === CEK PORT ===
echo "✅ Cek port Netdata..."
ss -tulnp | grep ":${NETDATA_PORT}" || echo "⚠️ Port ${NETDATA_PORT} belum kelihatan, cek firewall dan service"

# === DONE ===
echo ""
echo "🎉 Netdata bersih dan MySQL plugin"
echo "📊 Akses di: http://<IP-SERVER>:${NETDATA_PORT}/"


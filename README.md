# incident-tools
Compromised Assesment
Panduan Script
Download script > curl -o testing.sh https://raw.githubusercontent.com/kangaman/incident-tools/refs/heads/Assessment/testing.sh
Ijin eksekusi > chmod +x testing.sh

Ubah konfigurasi Nama Server, Telegram Bot Token dan Chat ID
> nano testing.sh
ubah nama SERVER_NAME, TELEGRAM_BOT_TOKEN dan TELEGRAM_CHAT_ID
lalu simpan konfigurasi.
jalankan script > ./testing.sh

Troubleshooting
Install YARA
Ubuntu/Debian : sudo apt update && sudo apt install yara -y
Chent)S/RHEL : sudo yum install yara -y

Jika Lynis Gagal berjalan > sudo apt install git -y


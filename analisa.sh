#! /bin/bash

# *****************************************************************
# Analyst Incident Response Toolkit v2.1
# *****************************************************************
# Script ini digunakan untuk mengumpulkan informasi terkait keamanan sistem,
# mencari backdoor, mendeteksi aktivitas mencurigakan, serta melakukan audit keamanan.
# Sekarang dengan fitur notifikasi ke Telegram.

# Konfigurasi otomatis tanpa input manual
SERVER_NAME="server1"
TELEGRAM_BOT_TOKEN="Bot Telegram Token"
TELEGRAM_CHAT_ID="Chat ID"

echo "Memulai proses pada server: $SERVER_NAME ..."

# Membaca direktori saat ini
curr=${PWD}

# Membuat direktori utama untuk menyimpan hasil
mkdir -p $curr/CyberSecIR-$SERVER_NAME/SystemInfo

# Menyesuaikan direktori
sysDir=$curr/CyberSecIR-$SERVER_NAME/SystemInfo

# ================================================================
# PENGUMPULAN INFORMASI SISTEM
# ================================================================
echo "Mengumpulkan informasi sistem..."

date > $sysDir/0.DateTime.txt
uname -a > $sysDir/1.Versi_Kernel.txt
if [ -f /etc/os-release ]; then
    cat /etc/os-release > $sysDir/2.Versi_OS.txt
elif [ -f /etc/lsb-release ]; then
    cat /etc/lsb-release > $sysDir/2.Versi_OS.txt
fi

ps -aux > $sysDir/3.Daftar_Proses.txt
top -b -n 1 > $sysDir/4.Daftar_Running_App.txt

cat /root/.bash_history > $sysDir/5.History.txt
ls -al /etc/cron* > $sysDir/6.Cron.txt
crontab -l > $sysDir/7.Crontab.txt

netstat -tulnp > $sysDir/8.Inbound.txt
netstat -antup > $sysDir/9.Outbound.txt
netstat -antup | grep "ESTABLISHED" > $sysDir/10.Established_Conn.txt
w > $sysDir/11.Connected_to_PC.txt
cat /etc/resolv.conf > $sysDir/12.DNS.txt
cat /etc/hostname > $sysDir/13.Hostname.txt
cat /etc/hosts > $sysDir/14.Hosts.txt

cat /etc/passwd > $sysDir/15.Daftar_User.txt
cat /etc/passwd | grep "bash"> $sysDir/16.Daftar_User_Bash.txt
lastlog > $sysDir/17.Lastlog.txt
last > $sysDir/18.Last.txt

ls -alrt -R /home > $sysDir/19.Homedir.txt
ls -alrt -R /var/www > $sysDir/20.VarWWWdir.txt

# ================================================================
# MENCARI BACKDOOR DAN AKTIVITAS MENCURIGAKAN
# ================================================================
echo "Mencari backdoor dan aktivitas mencurigakan..."

grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *(" /home/ > $sysDir/21.Backdoor-Homedir.txt
grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *(" /var/www/ > $sysDir/22.Backdoor-VarWWWdir.txt

grep -Rinw /home -e "slot" -e "gacor" -e "maxwin" -e "thailand" -e "sigmaslot" -e "zeus" -e "cuan" -e "casino" -e "judi" -e "poker" -e "togel" -e "jackpot" -e "hoki" -e "dewa" -e "topedslot" > $sysDir/23.ListSlot.txt
echo "Pencarian selesai."

# ================================================================
# MENGIRIMKAN NOTIFIKASI KE TELEGRAM
# ================================================================
message="CyberSec Incident Response Toolkit v2.3 telah selesai untuk server $SERVER_NAME. Hasil:\n- Backdoor: $(wc -l < $sysDir/21.Backdoor-Homedir.txt) ditemukan.\n- Slot: $(wc -l < $sysDir/23.ListSlot.txt) ditemukan."
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message"
echo "Notifikasi Telegram dikirim."

# ================================================================
# MEMBUAT FILE KOMPRESI DARI HASIL PEMINDAIAN DAN AUDIT
# ================================================================
echo "Mengarsipkan hasil pengumpulan data..."
tar -czf CyberSecIR-$SERVER_NAME.tar.gz --remove-files CyberSecIR-$SERVER_NAME

# ================================================================
# MENGIRIMKAN FILE HASIL KE TELEGRAM
# ================================================================
echo "Mengirim hasil ke Telegram..."
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
     -F chat_id="$TELEGRAM_CHAT_ID" \
     -F document="@CyberSecIR-$SERVER_NAME.tar.gz"
echo "File hasil pemindaian dikirim ke Telegram."

echo "************************************************************"
echo "Proses selesai, hasil telah dikirim ke Telegram."
echo "************************************************************"

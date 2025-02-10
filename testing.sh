#! /bin/bash

# *****************************************************************
# CyberSec Incident Response Toolkit v2.2
# *****************************************************************
# Script ini digunakan untuk mengumpulkan informasi terkait keamanan sistem,
# mencari backdoor, mendeteksi aktivitas mencurigakan, serta melakukan audit keamanan.
# Sekarang dengan fitur notifikasi ke Telegram dan pemindaian malware dengan YARA.

# Meminta input manual untuk Nama Server, Telegram Bot Token, dan Chat ID
echo -n "Masukkan Nama Server: "
read SERVER_NAME
echo -n "Masukkan Telegram Bot Token: "
read -s TELEGRAM_BOT_TOKEN
echo -n "Masukkan Telegram Chat ID: "
read TELEGRAM_CHAT_ID

echo "Memulai proses pada server: $SERVER_NAME ..."

# Membaca direktori saat ini
curr=${PWD}

# Membuat direktori utama untuk menyimpan hasil
mkdir -p $curr/CyberSecIR-$SERVER_NAME/{SystemInfo,MalwareScan,Audit}

# Menyesuaikan direktori
sysDir=$curr/CyberSecIR-$SERVER_NAME/SystemInfo
malwareDir=$curr/CyberSecIR-$SERVER_NAME/MalwareScan
auditDir=$curr/CyberSecIR-$SERVER_NAME/Audit

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

grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *\(" /home/ > $sysDir/21.Backdoor-Homedir.txt
grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *\(" /var/www/ > $sysDir/22.Backdoor-VarWWWdir.txt

grep -Rinw /home -e "slot" -e "gacor" -e "maxwin" -e "thailand" -e "sigmaslot" -e "zeus" -e "cuan" -e "casino" -e "judi" -e "poker" -e "togel" -e "jackpot" -e "hoki" -e "dewa" -e "topedslot" > $sysDir/23.ListSlot.txt
echo "Pencarian selesai."

# ================================================================
# SCANNING MALWARE DENGAN YARA
# ================================================================
echo "Menjalankan pemindaian malware dengan YARA..."
yara -r /usr/share/yara/rules.yar /home/ > $malwareDir/YaraScan_Home.txt
yara -r /usr/share/yara/rules.yar /var/www/ > $malwareDir/YaraScan_WWW.txt
echo "Pemindaian malware selesai."

# ================================================================
# AUDIT KEAMANAN SISTEM DENGAN LYNIS DAN LINPEAS
# ================================================================
echo "Melakukan audit sistem dengan Lynis dan LinPEAS..."
git clone https://github.com/CISOfy/lynis $auditDir
pushd $auditDir && ./lynis audit system > $auditDir/out-lynis.txt
popd

curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh > $auditDir/out-linpeas.txt
echo "Audit sistem selesai."

# ================================================================
# MENGIRIMKAN NOTIFIKASI KE TELEGRAM
# ================================================================
message="CyberSec Incident Response Toolkit v2.2 telah selesai untuk server $SERVER_NAME. Hasil:
- Backdoor: $(wc -l < $sysDir/21.Backdoor-Homedir.txt) ditemukan.
- Slot: $(wc -l < $sysDir/23.ListSlot.txt) ditemukan.
- Malware: $(wc -l < $malwareDir/YaraScan_Home.txt) indikasi.
Audit Lynis & LinPEAS selesai."
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message"
echo "Notifikasi Telegram dikirim."

# ================================================================
# MEMBUAT FILE KOMPRESI DARI HASIL PEMINDAIAN DAN AUDIT
# ================================================================
echo "Mengarsipkan hasil pengumpulan data..."
tar -czf CyberSecIR-$SERVER_NAME.tar.gz --remove-files CyberSecIR-$SERVER_NAME
echo "************************************************************"
echo "Proses selesai, hasil tersimpan di ./CyberSecIR-$SERVER_NAME.tar.gz"
echo "************************************************************"

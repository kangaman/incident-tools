#! /bin/bash

# *****************************************************************
# Compromised Assesment Incident Response Toolkit v2.1
# *****************************************************************
# Script ini digunakan untuk mengumpulkan informasi terkait keamanan sistem,
# mencari backdoor, mendeteksi aktivitas mencurigakan, serta melakukan audit keamanan.
# Sekarang dengan fitur notifikasi ke Telegram.
# hasil modifikasi dari script Automate Data Collection for Compromise Assessment Script v1.0 @adpermana

# Meminta input manual untuk Nama Server, Telegram Bot Token, dan Chat ID
echo "Masukkan Nama Server: "
read SERVER_NAME
echo "Masukkan Telegram Bot Token: "
read -s TELEGRAM_BOT_TOKEN
echo "Masukkan Telegram Chat ID: "
read TELEGRAM_CHAT_ID

echo "Memulai proses pada server: $SERVER_NAME ..."

# Membaca direktori saat ini
curr=${PWD}

# Membuat direktori utama untuk menyimpan hasil
mkdir -p $curr/CyberSecIR-$SERVER_NAME
mkdir -p $curr/CyberSecIR-$SERVER_NAME/SystemInfo
mkdir -p $curr/CyberSecIR-$SERVER_NAME/MalwareScan
mkdir -p $curr/CyberSecIR-$SERVER_NAME/Audit

# Menyesuaikan direktori
sysDir=$curr/CyberSecIR-$SERVER_NAME/SystemInfo
malwareDir=$curr/CyberSecIR-$SERVER_NAME/MalwareScan
auditDir=$curr/CyberSecIR-$SERVER_NAME/Audit

# ================================================================
# PENGUMPULAN INFORMASI SISTEM
# ================================================================
echo "Mengumpulkan informasi sistem..."

# Menyimpan tanggal dan waktu saat ini
date > $sysDir/0.DateTime.txt

# Mengumpulkan informasi versi sistem
uname -a > $sysDir/1.Versi_Kernel.txt
cat /etc/lsb-release > $sysDir/2.Versi_OS.txt

# Mengumpulkan daftar proses yang berjalan
ps -aux > $sysDir/3.Daftar_Proses.txt
top -b -n 1 > $sysDir/4.Daftar_Running_App.txt

# Mengumpulkan riwayat perintah root
cat /root/.bash_history > $sysDir/5.History.txt

# Mengumpulkan informasi cron jobs
ls -al /etc/cron* > $sysDir/6.Cron.txt
crontab -l > $sysDir/7.Crontab.txt

# Mengumpulkan informasi jaringan
netstat -tulnp > $sysDir/8.Inbound.txt
netstat -antup > $sysDir/9.Outbound.txt
netstat -antup | grep "ESTABLISHED" > $sysDir/10.Established_Conn.txt
w > $sysDir/11.Connected_to_PC.txt
cat /etc/resolv.conf > $sysDir/12.DNS.txt
cat /etc/hostname > $sysDir/13.Hostname.txt
cat /etc/hosts > $sysDir/14.Hosts.txt

# Mengumpulkan daftar pengguna
cat /etc/passwd > $sysDir/15.Daftar_User.txt
cat /etc/passwd | grep "bash"> $sysDir/16.Daftar_User_Bash.txt
lastlog > $sysDir/17.Lastlog.txt
last > $sysDir/18.Last.txt

# Mengumpulkan daftar direktori penting
ls -alrt -R /home > $sysDir/19.Homedir.txt
ls -alrt -R /var/www > $sysDir/20.VarWWWdir.txt

# ================================================================
# MENCARI BACKDOOR DAN AKTIVITAS MENCURIGAKAN
# ================================================================
echo "Mencari backdoor dan aktivitas mencurigakan..."

grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *\(" /home/ > $sysDir/21.Backdoor-Homedir.txt
grep -RPn "(passthru|shell_exec|system|phpinfo|base64_decode|chmod|mkdir|fopen|fclose|readfile) *\(" /var/www/ > $sysDir/22.Backdoor-VarWWWdir.txt

# Mencari indikasi file terkait judi online
grep -Rinw /home -e "slot" -e "gacor" -e "maxwin" -e "thailand" -e "sigmaslot" -e "zeus" -e "cuan" -e "casino" -e "judi" -e "poker" -e "togel" -e "jackpot" -e "hoki" -e "dewa" -e "topedslot" > $sysDir/23.ListSlot.txt
echo "Pencarian selesai."

# ================================================================
# SCANNING MALWARE DENGAN THOR-LITE
# ================================================================
echo "Menjalankan pemindaian malware dengan Thor-Lite..."
git clone https://github.com/adpermana/Thor-2.git $malwareDir
chmod +x $malwareDir/thor-lite-linux
cd $malwareDir && ./thor-lite-linux -a Filescan --intense --norescontrol --cross-platform --alldrives -p /home/
cd ../..

echo "Pemindaian malware selesai."

# ================================================================
# AUDIT KEAMANAN SISTEM DENGAN LYNIS DAN LINPEAS
# ================================================================
echo "Melakukan audit sistem dengan Lynis dan LinPEAS..."
git clone https://github.com/CISOfy/lynis $auditDir
cd $auditDir && ./lynis audit system > $auditDir/out-lynis.txt
cd ../..
mv lynis-report.dat $auditDir
mv lynis.log $auditDir

curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh > $auditDir/out-linpeas.txt
echo "Audit sistem selesai."

# ================================================================
# MENGIRIMKAN NOTIFIKASI KE TELEGRAM
# ================================================================
message="CyberSec Incident Response Toolkit v2.1 telah selesai untuk server $SERVER_NAME. Hasil telah dikompresi dan siap diunduh."
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message"
echo "Notifikasi Telegram dikirim."

# ================================================================
# MEMBUAT FILE KOMPRESI DARI HASIL PEMINDAIAN DAN AUDIT
# ================================================================
echo "Mengarsipkan hasil pengumpulan data..."
tar -czf CyberSecIR-$SERVER_NAME.tar.gz CyberSecIR-$SERVER_NAME
rm -rf CyberSecIR-$SERVER_NAME

echo "************************************************************"
echo "Proses selesai, hasil tersimpan di ./CyberSecIR-$SERVER_NAME.tar.gz"
echo "************************************************************"

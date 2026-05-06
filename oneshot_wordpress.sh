#!/bin/bash
# 1. 패키지 업데이트 및 아파치/PHP 설치
apt update
apt install -y apache2 ghostscript libapache2-mod-php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip mysql-server

# 2. 워드프레스 다운로드 및 배치
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz -C /var/www/html --strip-components=1
rm latest.tar.gz
rm /var/www/html/index.html

# 3. 권한 설정
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# 4. 로컬 DB 설정
mysql -u root <<EOF
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'wp_pass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# 5. wp-config.php 자동 생성 및 동적 IP 로직 삽입
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
sed -i "s/username_here/wp_user/" /var/www/html/wp-config.php
sed -i "s/password_here/wp_pass/" /var/www/html/wp-config.php

# wp-config.php의 require_once 바로 앞에 동적 URL define 삽입
# 반드시 require_once ABSPATH.'wp-settings.php' 보다 앞에 있어야
# WordPress 코어 로딩 전에 WP_HOME/WP_SITEURL이 적용됨
# (파일 끝에 append하면 require_once 이후가 되어 무시됨)
sed -i "s|require_once ABSPATH . 'wp-settings.php';|define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );\ndefine( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );\nrequire_once ABSPATH . 'wp-settings.php';|" /var/www/html/wp-config.php

# 6. 부팅 시 Apache 재시작 서비스 등록
# - DB URL 업데이트 로직 제거: wp-config.php의 동적 define과 충돌하며,
#   RDS offload 후 로컬 mysql이 꺼진 상태에서 DB 접속 시도 시 오류 발생
# - mysql.service 의존성 제거: RDS offload 이후에도 서비스가 정상 동작하도록
cat <<'EOF' > /etc/systemd/system/wp-update-ip.service
[Unit]
Description=Restart Apache on boot for WordPress
After=network-online.target apache2.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wp-update-ip.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' > /usr/local/bin/wp-update-ip.sh
#!/bin/bash
# wp-config.php에 WP_HOME/WP_SITEURL이 동적으로 정의되어 있으므로
# DB 업데이트 없이 Apache 재시작만으로 IP 변경에 대응 가능
systemctl restart apache2
echo "Apache restarted successfully"
exit 0
EOF

chmod +x /usr/local/bin/wp-update-ip.sh
systemctl enable wp-update-ip.service
systemctl start wp-update-ip.service
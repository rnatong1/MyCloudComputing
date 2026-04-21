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

# 파일 끝에 코드 추가
cat <<EOT >> /var/www/html/wp-config.php
define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
EOT

# 6. 부팅 시 WordPress DB의 IP 자동 업데이트 서비스 등록
cat <<'EOF' > /etc/systemd/system/wp-update-ip.service
[Unit]
Description=Update WordPress IP on boot
After=mysql.service apache2.service
Requires=mysql.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wp-update-ip.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' > /usr/local/bin/wp-update-ip.sh
#!/bin/bash
# EC2 현재 퍼블릭 IP 가져오기
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# WordPress DB IP 업데이트
mysql -u root <<MYSQL
USE wordpress;
UPDATE wp_options SET option_value='http://${PUBLIC_IP}' WHERE option_name='siteurl';
UPDATE wp_options SET option_value='http://${PUBLIC_IP}' WHERE option_name='home';
MYSQL
EOF

chmod +x /usr/local/bin/wp-update-ip.sh
systemctl enable wp-update-ip.service
systemctl start wp-update-ip.service
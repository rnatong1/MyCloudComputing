#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "ERROR: Illegal number of parameters"
    echo "Usage: ./oneshot.sh [Local_DB_PW] [RDS_PW] [RDS_Address]"
    exit
fi

WPW=$1       # 로컬 DB 비밀번호
RDBPW=$2     # RDS 비밀번호
RDBADDR=$3   # RDS 엔드포인트

echo "Starting DB Migration to RDS: $RDBADDR"

# 1. 로컬 DB를 RDS로 덤프 및 이전
# (우분투에서는 경로 없이 mysqldump, mysql 직접 사용)
mysqldump -u root -p$WPW --databases wordpress --single-transaction --compress --order-by-primary | \
mysql -u admin -h $RDBADDR -p$RDBPW --port=3306

# 2. wp-config.php 수정 (경로: /var/www/html)
# 백업 생성
cp /var/www/html/wp-config.php /home/ubuntu/wp-config.php.bak

# DB 호스트를 localhost에서 RDS 주소로 변경
sed -i "s/localhost/$RDBADDR/g" /var/www/html/wp-config.php

# 3. DB 비밀번호 추출 및 RDS 유저 생성
# 기존 코드의 변수 추출 방식 유지 (DB_PASSWORD 필드 확인 필요)
PW=$(grep "DB_PASSWORD" /var/www/html/wp-config.php | awk -F "'" '{print $4}')

echo "Extracted DB Password: $PW"

# RDS에 워드프레스용 유저 생성 및 권한 부여
mysql -h $RDBADDR -u admin -p$RDBPW -e "CREATE USER 'wp_user'@'%' IDENTIFIED BY '$PW'; GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'%'; FLUSH PRIVILEGES;"

# 4. 서비스 관리 (systemctl 사용)
echo "Restarting Apache..."
sudo systemctl stop apache2
# 우분투 패키지 설치 시 로컬 mysql은 더 이상 필요 없으므로 중지 가능
sudo systemctl stop mysql 
sudo systemctl start apache2

echo "Migration Complete!"
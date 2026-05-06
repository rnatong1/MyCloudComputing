#!/bin/bash

WP_CONFIG="/var/www/html/wp-config.php"

# 1. wp-config.php 존재 확인
if [ ! -f "$WP_CONFIG" ]; then
    echo "ERROR: $WP_CONFIG 파일이 없습니다."
    exit 1
fi

# 2. 이미 수정된 경우 중복 적용 방지
if grep -q "define( 'WP_HOME'" $WP_CONFIG; then
    # define이 있는데 require_once 뒤에 있는 경우 제거 후 재삽입
    DEFINE_LINE=$(grep -n "define( 'WP_HOME'" $WP_CONFIG | cut -d: -f1)
    REQUIRE_LINE=$(grep -n "require_once ABSPATH" $WP_CONFIG | cut -d: -f1)

    if [ "$DEFINE_LINE" -gt "$REQUIRE_LINE" ]; then
        echo "기존 define이 require_once 뒤에 있습니다. 수정합니다..."
        # 기존 define 두 줄 제거
        sed -i "/^define( 'WP_HOME'.*HTTP_HOST/d" $WP_CONFIG
        sed -i "/^define( 'WP_SITEURL'.*HTTP_HOST/d" $WP_CONFIG
    else
        echo "이미 올바르게 설정되어 있습니다. 종료합니다."
        exit 0
    fi
fi

# 3. require_once 앞에 define 삽입
sed -i "s|require_once ABSPATH . 'wp-settings.php';|define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );\ndefine( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );\nrequire_once ABSPATH . 'wp-settings.php';|" $WP_CONFIG

# 4. 결과 확인
echo "=== 수정 결과 ==="
grep -n "WP_HOME\|WP_SITEURL\|require_once" $WP_CONFIG

# 5. Apache 재시작
echo "=== Apache 재시작 ==="
sudo systemctl restart apache2
echo "완료!"

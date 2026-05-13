#!/bin/bash
# =====================================================
# 4차시 실습 setup.sh
# EC2에서 Docker 설치 → 이미지 빌드 → 로컬 테스트
# 실행 방법: bash setup.sh
# =====================================================

set -e  # 오류 발생 시 즉시 중단

# ── 0. .env 파일에서 환경변수 로드 ─────────────────
if [ -f ~/image_analyzer/.env ]; then
  set -a
  source ~/image_analyzer/.env
  set +a
  echo ".env 로드 완료"
fi

# ── 1. Docker 설치 ──────────────────────────────────
echo "[1/4] Docker 설치 중..."
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
echo "Docker 설치 완료"

# ── 2. 환경변수 확인 ────────────────────────────────
echo "[2/4] 환경변수 확인..."
if [ -z "$GEMINI_API_KEY" ]; then
  echo "오류: GEMINI_API_KEY 가 설정되지 않았습니다."
  echo "  export GEMINI_API_KEY=\"your_api_key\" 후 재실행하세요."
  exit 1
fi
if [ -z "$AWS_BUCKET_NAME" ]; then
  echo "오류: AWS_BUCKET_NAME 이 설정되지 않았습니다."
  echo "  export AWS_BUCKET_NAME=\"your_bucket_name\" 후 재실행하세요."
  exit 1
fi
echo "환경변수 확인 완료"

# ── 3. Docker 이미지 빌드 ───────────────────────────
echo "[3/4] Docker 이미지 빌드 중..."
cd ~/image_analyzer
# ec2-user 그룹 적용을 위해 newgrp 대신 sg 사용
sg docker -c "docker build -t ai-image-analyzer ."
echo "빌드 완료"

# ── 4. 로컬 실행 테스트 ─────────────────────────────
echo "[4/4] 컨테이너 실행 중... (Ctrl+C 로 중단)"
echo "브라우저에서 http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000/ 접속하여 확인"
sg docker -c "docker run -p 5000:5000 \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  -e AWS_BUCKET_NAME=$AWS_BUCKET_NAME \
  ai-image-analyzer"
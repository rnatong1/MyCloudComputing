#!/bin/bash
# =====================================================
# 4차시 실습 push_to_ecr.sh
# ECR 로그인 → 이미지 태그 → push
# 실행 방법: bash push_to_ecr.sh
# =====================================================

set -e

# ── ECR URI 입력 ────────────────────────────────────
# AWS 콘솔 → ECR → 리포지토리 → '푸시 명령 보기' 에서 확인
if [ -z "$1" ]; then
  echo "사용법: bash push_to_ecr.sh <ECR_URI>"
  echo "예시:   bash push_to_ecr.sh 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/ai-image-analyzer"
  exit 1
fi

ECR_URI=$1
REGION="ap-northeast-2"

echo "[1/3] ECR 로그인 중..."
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin \
  $(echo $ECR_URI | cut -d'/' -f1)

echo "[2/3] 이미지 태그 붙이기..."
docker tag ai-image-analyzer:latest $ECR_URI:latest

echo "[3/3] ECR 에 push 중..."
docker push $ECR_URI:latest

echo "완료! ECR URI: $ECR_URI:latest"

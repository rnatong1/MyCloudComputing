# 베이스 이미지 — Python 3.11 슬림 버전
FROM python:3.11-slim

WORKDIR /app

# 패키지 목록 복사 후 설치
COPY requirements.txt .
RUN pip install -r requirements.txt

# 앱 코드 전체 복사
COPY . .

# 포트 노출 및 실행 명령
EXPOSE 5000
CMD ["python3", "app.py"]

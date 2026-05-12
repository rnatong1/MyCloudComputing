from flask import Flask, request, render_template
from google import genai
from google.genai import types
from dotenv import load_dotenv
import boto3
import base64
import os
import uuid

load_dotenv()

app = Flask(__name__)

# Gemini 클라이언트
client = genai.Client(api_key=os.environ['GEMINI_API_KEY'])

# S3 클라이언트 — 버킷 이름으로 리전 자동 조회
BUCKET_NAME = os.environ['AWS_BUCKET_NAME']
_location = boto3.client('s3').get_bucket_location(Bucket=BUCKET_NAME)
BUCKET_REGION = _location['LocationConstraint'] or 'us-east-1'
s3 = boto3.client('s3', region_name=BUCKET_REGION)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/upload', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return render_template('result.html', error='이미지 파일이 없습니다.')

    file = request.files['image']
    if file.filename == '':
        return render_template('result.html', error='파일을 선택해주세요.')

    # 고유 파일명 생성
    ext = os.path.splitext(file.filename)[1].lower()
    filename = f"{uuid.uuid4().hex}{ext}"

    # 파일 내용을 메모리에 읽기
    file_bytes = file.read()
    mime_type = file.content_type

    # 1. S3에 업로드
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=filename,
        Body=file_bytes,
        ContentType=mime_type
    )

    # 2. Gemini Vision으로 이미지 분석
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            types.Part.from_bytes(data=file_bytes, mime_type=mime_type),
            "이 이미지를 한국어로 자세히 설명해줘."
        ]
    )

    # 3. 브라우저 표시용 base64 인코딩 (S3 퍼블릭 액세스 불필요)
    image_b64 = base64.b64encode(file_bytes).decode('utf-8')
    image_data_url = f"data:{mime_type};base64,{image_b64}"

    return render_template(
        'result.html',
        analysis=response.text,
        image_data_url=image_data_url,
        filename=filename
    )


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

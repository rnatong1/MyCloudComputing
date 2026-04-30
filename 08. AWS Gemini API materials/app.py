from flask import Flask, request, jsonify, render_template
from google import genai
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
client = genai.Client(api_key=os.environ['GEMINI_API_KEY'])

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get('message')
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=user_message
    )
    return jsonify({'reply': response.text})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
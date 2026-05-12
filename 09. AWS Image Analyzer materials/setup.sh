#!/bin/bash

BASE="https://raw.githubusercontent.com/rnatong1/MyCloudComputing/main/09.%20AWS%20Image%20Analyzer%20materials"

mkdir -p image_analyzer/templates

wget -O image_analyzer/app.py                  "$BASE/app.py"
wget -O image_analyzer/requirements.txt        "$BASE/requirements.txt"
wget -O image_analyzer/templates/index.html    "$BASE/index.html"
wget -O image_analyzer/templates/result.html   "$BASE/result.html"

pip install -r ./image_analyzer/requirements.txt
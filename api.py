from flask import Flask, request, jsonify
from config import (
    RULES_PATH,
    TESSERACT_CMD,
    TRAIN_FILE_PATH,
    TEXT_COL,
    LABEL_COL,
)
from services.rules_service import RulesService
from services.ocr_service import OCRService
from services.analyzer_service import AnalyzerService
from models.allergen_model import AllergenModel
import os
import tempfile

app = Flask(__name__)

# تحميل الخدمات مرة واحدة عند تشغيل السيرفر
rules_service = RulesService(RULES_PATH)
ocr_service = OCRService(TESSERACT_CMD)

allergen_model = AllergenModel(rules_service)
allergen_model.train_from_excel(TRAIN_FILE_PATH, TEXT_COL, LABEL_COL)

analyzer = AnalyzerService(
    ocr_service=ocr_service,
    rules_service=rules_service,
    allergen_model=allergen_model
)


@app.route("/analyze", methods=["POST"])
def analyze():
    if "image" not in request.files:
        return jsonify({
            "success": False,
            "message": "No image file provided"
        }), 400

    image_file = request.files["image"]

    if image_file.filename == "":
        return jsonify({
            "success": False,
            "message": "Empty filename"
        }), 400

    # نحفظ الصورة مؤقتًا
    suffix = os.path.splitext(image_file.filename)[1] or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        image_file.save(temp_file.name)
        temp_path = temp_file.name

    try:
        result = analyzer.analyze_image(temp_path)
        result["success"] = True
        return jsonify(result)
    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "SafeBite API is running"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
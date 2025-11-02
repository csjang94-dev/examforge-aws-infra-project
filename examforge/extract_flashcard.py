# extract_flashcard
from PyPDF2 import PdfReader
import re
import json

# PDF 경로
pdf_path = r"C:\Users\user\Downloads\AWS_SAA_Q&A156_FromBlog일본사는 감자옹.pdf"
output_path = r"C:\Users\user\Desktop\project_gakbang\flashcard.json"

reader = PdfReader(pdf_path)

# 254페이지부터 끝까지 읽기 (index 253부터)
text = ""
for page in reader.pages[253:]:
    page_text = page.extract_text()
    if page_text:
        text += page_text + "\n"

# ✅ AWS 서비스명 (영문 + 숫자 + 공백 + 하이픈 포함)
pattern = r"(AWS [A-Za-z0-9\-\s]+)\n(.*?)(?=\nAWS [A-Za-z0-9\-\s]+|$)"
matches = re.findall(pattern, text, re.S)

cards = []

for title, desc in matches:
    # 🧹 1️⃣ 불필요한 줄바꿈/공백 정리
    desc = re.sub(r"\s+", " ", desc.strip())

    # 🧹 2️⃣ 표, 목록, 불릿, 숫자 리스트 제거
    desc = re.sub(r"·.*?(?=AWS|$)", "", desc)  # 불릿 “·” 제거
    desc = re.sub(r"\d+\.\s*.*?(?=AWS|$)", "", desc)  # "1. " 목록 제거
    desc = re.sub(r"\([a-zA-Z0-9]\).*?(?=AWS|$)", "", desc)  # "(a)", "(1)" 등 제거
    desc = re.sub(r"\|.*?\|", "", desc)  # 표 형태 제거
    desc = re.sub(r"기능 및 이점.*", "", desc)  # “기능 및 이점” 이후 삭제

    # 🧹 3️⃣ 너무 짧거나 빈 내용 제외
    if len(desc) < 20:
        continue

    cards.append({
        "제목": title.strip(),
        "설명": desc.strip()
    })

# JSON 저장
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(cards, f, ensure_ascii=False, indent=2)

print(f"{len(cards)}개 서비스 개념 추출 완료 ✅")
print(f"저장 경로: {output_path}")

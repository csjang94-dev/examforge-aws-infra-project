# extract_aws_questions
from PyPDF2 import PdfReader
import re
import json
import os

# PDF 파일 경로
pdf_path = r"C:\Users\user\Downloads\AWS_SAA_Q&A156_FromBlog일본사는 감자옹.pdf"

# 출력 폴더 경로
output_dir = r"C:\Users\user\Desktop\project_gakbang"
os.makedirs(output_dir, exist_ok=True)  # 폴더가 없으면 자동 생성

# PDF 읽기
reader = PdfReader(pdf_path)
text = ""
for page in reader.pages:
    text += page.extract_text() + "\n"

# 문제별 패턴 (문제번호 ~ ▶정답)
pattern = r"문제(\d+)(.*?)(?=문제\d+|$)"
matches = re.findall(pattern, text, re.S)

problems = []

for num, content in matches:
    # 보기 추출 (A~D)
    choices = re.findall(r"([A-D])\.\s*(.*?)\n(?=[A-D]\.|▶정답|$)", content, re.S)
    choice_dict = {ch[0]: ch[1].strip() for ch in choices}

    # 정답 추출
    answer_match = re.search(r"▶정답\s*([A-D])", content)
    answer = answer_match.group(1) if answer_match else None

    # 질문 부분만 추출
    question_part = content.split("A.")[0].strip()

    problems.append({
        "문제번호": int(num),
        "질문": question_part,
        "보기": choice_dict,
        "정답": answer
    })

# 결과 저장 경로
output_path = os.path.join(output_dir, "aws_saa_questions.json")

# JSON 저장
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(problems, f, ensure_ascii=False, indent=2)

print(f"{len(problems)}개 문제 추출 완료 ✅")
print(f"저장 경로: {output_path}")

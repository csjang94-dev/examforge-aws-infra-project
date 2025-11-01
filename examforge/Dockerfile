# ---------------------------
# 1️⃣ Base Image
# ---------------------------
FROM node:lts-slim

# ---------------------------
# 2️⃣ 작업 디렉터리 설정
# ---------------------------
WORKDIR /app

# ---------------------------
# 3️⃣ package.json 감지 및 복사
# ---------------------------
# - examforge 내부에 있으면 그걸 복사
# - 없으면 상위(root)의 package.json을 복사
# (빌드 컨텍스트는 examforge 기준)

RUN if [ -f ./package.json ]; then \
      echo "✅ Found local package.json in ./examforge"; \
      cp ./package.json /tmp/package.json; \
    elif [ -f ../package.json ]; then \
      echo "✅ Found parent package.json in ../"; \
      cp ../package.json /tmp/package.json; \
    else \
      echo "❌ No package.json found"; \
      exit 1; \
    fi

# npm install을 위해 복사한 파일을 /app으로 이동
COPY --from=0 /tmp/package.json ./
RUN npm install --production || npm install --omit=dev

# ---------------------------
# 4️⃣ 애플리케이션 전체 복사
# ---------------------------
COPY . .

# ---------------------------
# 5️⃣ 실행 권한 및 환경 설정
# ---------------------------
RUN chmod +x /app/run_apache.sh
ENV PORT=3000
EXPOSE 3000

# ---------------------------
# 6️⃣ 시작 명령어
# ---------------------------
CMD ["/bin/bash", "/app/run_apache.sh"]

# Dockerfile (개선된 버전)
FROM node:18-slim 

WORKDIR /usr/src/app

# 1. package.json과 package-lock.json 둘 다 복사 (중요!)
COPY package*.json ./

# (디버깅용) 복사 확인
RUN ls -l

# 2. 의존성 설치 (package-lock.json이 있으면 npm ci 사용 권장)
RUN npm ci --only=production || npm install --production

# 3. 모든 애플리케이션 코드 복사
COPY . .

# 4. Express 서버 포트 노출
EXPOSE 3000

# 5. 헬스 체크 설정 (curl 설치 필요)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

# 6. 애플리케이션 실행
CMD ["node", "login_server.js"]

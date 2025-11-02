# Dockerfile (최종 개선 버전)
FROM node:18-slim 

WORKDIR /usr/src/app

# 1. package.json과 package-lock.json 복사
COPY package*.json ./

# 2. 의존성 설치
RUN npm ci --only=production || npm install --production

# 3. 모든 애플리케이션 코드 복사
COPY . .

# 4. 복사된 파일 확인 (디버깅용)
RUN ls -la

# 5. Express 서버 포트 노출
EXPOSE 3000

# 6. 헬스 체크 설정 (Node.js 내장 http 모듈 사용)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

# 7. 애플리케이션 실행
CMD ["node", "login_server.js"]

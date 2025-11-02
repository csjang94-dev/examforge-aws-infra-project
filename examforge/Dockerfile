# Dockerfile (수정된 버전)

FROM node:18-slim 

WORKDIR /usr/src/app

# 1. 의존성 파일 복사 및 설치
# package.json만 정확히 복사하도록 명시합니다.
COPY package.json ./

# (디버깅용) 복사 확인: 빌드 로그에서 파일이 잘 복사되었는지 확인합니다.
RUN ls -l

# 필요한 Node.js 모듈 설치 
RUN npm install --production 

# 2. 모든 애플리케이션 코드 복사
COPY . .

# 3. Express 서버 포트를 노출합니다.
EXPOSE 3000

# 4. 헬스 체크 설정
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# 5. 애플리케이션 실행 명령
CMD [ "node", "app.js" ]

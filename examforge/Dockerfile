# Dockerfile (Node.js/Express 서버용)

# Node.js LTS 버전을 기반 이미지로 사용합니다. (가장 중요)
FROM node:18-slim 

# 작업 디렉토리 설정
WORKDIR /usr/src/app

# 1. 의존성 파일 복사 및 설치
# 캐싱을 효율적으로 사용하기 위해 package.json과 package-lock.json만 먼저 복사합니다.
COPY package*.json ./

# 필요한 Node.js 모듈 설치 (npm install)
# 이 단계가 이전 ERR_CONNECTION_REFUSED 오류를 일으킨 'dotenv' 문제를 해결합니다.
RUN npm install

# 2. 모든 애플리케이션 코드 복사
COPY . .

# 3. Express 서버 포트를 노출합니다.
# app.js에서 설정한 PORT=3000과 일치해야 합니다.
EXPOSE 3000

# 4. 헬스 체크 설정 (Node.js 서버에 맞게 유지)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# 5. 애플리케이션 실행 명령
# 서버 시작 파일(app.js 또는 login_server.js)을 실행합니다.
CMD [ "node", "login_server.js" ] 
# 파일명이 login_server.js라면 CMD [ "node", "login_server.js" ] 로 변경해야 합니다.

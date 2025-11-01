# Base Image: 애플리케이션에 필요한 기본 이미지를 사용합니다. (예: node:lts-slim)
FROM node:lts-slim

# 작업 디렉터리 설정
WORKDIR /app

# 애플리케이션 파일 복사 (Docker 빌드 컨텍스트는 'examforge' 폴더입니다.)
# run_apache.sh가 examforge 폴더 안에 있다고 가정합니다.
COPY package.json ./
COPY package-lock.json ./

# 의존성 설치
RUN npm install

# 나머지 애플리케이션 코드 및 스크립트 파일 복사
COPY ./ ./

# 💡 [수정] run_apache.sh에 실행 권한을 부여합니다.
RUN chmod +x /app/run_apache.sh

# 컨테이너 시작 시 실행할 명령 설정 (Task Definition에서 덮어쓸 수 있음)
# ENTRYPOINT는 run_apache.sh의 경로가 /app/run_apache.sh라고 가정합니다.
ENTRYPOINT ["/app/run_apache.sh"]

# 컨테이너 포트 노출 (Task Definition의 portMappings와 일치해야 함)
EXPOSE 3000

#!/bin/bash
set -e

echo "🔧 Starting application on port ${PORT:-3000}..."

# (선택) Node 앱을 실행하는 경우:
# npm run start

# (선택) Express 앱이라면 보통 아래 명령어:
node app.js

# (참고) 만약 Apache를 함께 실행하고 싶다면:
# service apache2 start
# tail -f /var/log/apache2/access.log

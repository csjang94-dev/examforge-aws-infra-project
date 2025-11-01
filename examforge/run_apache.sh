#!/bin/bash
set -e

echo "🚀 Starting application on port ${PORT:-3000}..."

# Node 앱 실행 (예: Express 기반)
if [ -f "app.js" ]; then
  node app.js
elif [ -f "server.js" ]; then
  node server.js
else
  echo "❌ No entrypoint found (app.js or server.js missing)"
  exit 1
fi

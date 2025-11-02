// app.js

require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const AWS = require('aws-sdk');
const cors = require('cors');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// AWS 설정 - ECS 태스크 역할 자동 사용
AWS.config.update({
    region: process.env.AWS_REGION || 'ap-northeast-2'
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE || 'User-Data-Dev'; 

app.use(cors());
app.use(bodyParser.json());
app.use(express.static(__dirname));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// AWS 연결 테스트 엔드포인트
app.get('/api/test-connection', async (req, res) => {
    try {
        const result = await dynamoDB.listTables({}).promise();
        res.status(200).json({ 
            status: 'connected', 
            tables: result.TableNames,
            region: AWS.config.region 
        });
    } catch (err) {
        console.error('AWS 연결 테스트 실패:', err);
        res.status(500).json({ 
            status: 'error', 
            message: err.message,
            code: err.code 
        });
    }
});

// 회원가입 요청 처리
app.post('/signup', async (req, res) => {
    console.log('========================================');
    console.log('회원가입 요청 수신:', new Date().toISOString());
    console.log('요청 바디:', JSON.stringify(req.body, null, 2));

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        console.error('❌ 요청 데이터 누락');
        return res.status(400).send('회원가입 실패: 필수 정보 누락');
    }

    try {
        console.log('📝 이메일 중복 확인 중...');
        
        // 이메일 중복 확인
        const checkParams = {
            TableName: TABLE_NAME,
            FilterExpression: '#email = :email',
            ExpressionAttributeNames: { '#email': 'email' },
            ExpressionAttributeValues: { ':email': email }
        };
        
        const existingUsers = await dynamoDB.scan(checkParams).promise();
        console.log('중복 확인 결과:', existingUsers.Items.length, '개 발견');
        
        if (existingUsers.Items.length > 0) {
            console.error('❌ 이메일 중복');
            return res.status(409).send('회원가입 실패: 이미 존재하는 이메일입니다.');
        }

        console.log('🔐 비밀번호 해싱 중...');
        const hashedPassword = await bcrypt.hash(password, 10);
        console.log('✅ 비밀번호 해싱 완료');

        const userId = uuidv4();
        console.log('🆔 생성된 UserID:', userId);

        // ✅ 수정: DynamoDB 테이블의 키 이름과 일치시킴
        const params = {
            TableName: TABLE_NAME,
            Item: {
                UserID: userId,  // ← 대문자 ID로 변경!
                name: name,
                email: email,
                password: hashedPassword,
                createdAt: new Date().toISOString()
            }
        };

        console.log('💾 DynamoDB에 저장 중...');
        console.log('저장 파라미터:', JSON.stringify({
            ...params,
            Item: { ...params.Item, password: '[HIDDEN]' }
        }, null, 2));

        await dynamoDB.put(params).promise();
        
        console.log('✅ DynamoDB 저장 성공!');
        console.log('========================================');
        
        res.status(200).send('회원가입 성공');
    } catch (err) {
        console.error('========================================');
        console.error('❌ 회원가입 오류 발생!');
        console.error('에러 이름:', err.name);
        console.error('에러 메시지:', err.message);
        console.error('에러 코드:', err.code);
        console.error('스택:', err.stack);
        console.error('========================================');
        
        res.status(500).send(`회원가입 실패: ${err.message}`);
    }
});

// 로그인 요청 처리
app.post('/login', async (req, res) => {
    console.log('========================================');
    console.log('로그인 요청 수신:', new Date().toISOString());
    console.log('요청 바디:', JSON.stringify({ email: req.body.email, password: '[HIDDEN]' }));

    const { email, password } = req.body; 

    if (!email || !password) {
        console.error('❌ 요청 데이터 누락');
        return res.status(400).send('로그인 실패: 필수 정보 누락');
    }

    const params = {
        TableName: TABLE_NAME,
        FilterExpression: '#email = :email',
        ExpressionAttributeNames: { '#email': 'email' },
        ExpressionAttributeValues: { ':email': email }
    };

    try {
        console.log('🔍 사용자 검색 중...');
        const data = await dynamoDB.scan(params).promise();
        console.log('검색 결과:', data.Items.length, '명 발견');

        if (data.Items.length === 0) {
            console.error('❌ 사용자 없음');
            console.error('========================================');
            return res.status(404).send('로그인 실패: 사용자 없음 또는 이메일 불일치');
        }

        const user = data.Items[0];
        console.log('👤 사용자 발견:', user.email);
        
        console.log('🔐 비밀번호 확인 중...');
        const match = await bcrypt.compare(password, user.password); 

        if (!match) {
            console.error('❌ 비밀번호 불일치');
            console.error('========================================');
            return res.status(401).send('로그인 실패: 비밀번호 불일치');
        }

        console.log('✅ 로그인 성공!');
        console.log('========================================');
        res.status(200).send('로그인 성공');
    } catch (err) {
        console.error('========================================');
        console.error('❌ 로그인 오류 발생!');
        console.error('에러 이름:', err.name);
        console.error('에러 메시지:', err.message);
        console.error('에러 코드:', err.code);
        console.error('========================================');
        
        res.status(500).send(`로그인 실패: ${err.message}`);
    }
});

// 서버 시작
app.listen(PORT, () => {
    console.log('========================================');
    console.log('🚀 서버 시작!');
    console.log(`⏰ 시간: ${new Date().toISOString()}`);
    console.log(`🌐 포트: ${PORT}`);
    console.log(`📍 리전: ${AWS.config.region || 'ap-northeast-2'}`);
    console.log(`🗄️  테이블: ${TABLE_NAME}`);
    console.log('========================================');
});

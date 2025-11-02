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
const PORT = 3000;

// AWS 설정
AWS.config.update({
    region: 'ap-northeast-2',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = 'User-Data-Dev'; 

app.use(cors());
app.use(bodyParser.json());

// ✅ 수정: 정적 파일 제공 (현재 디렉토리에서 직접)
app.use(express.static(__dirname));

// 루트 경로에서 index.html 제공
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// 헬스체크 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// 회원가입 요청 처리
app.post('/signup', async (req, res) => {
    console.log('회원가입 요청 수신:', req.body);

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        console.error('요청 데이터 누락');
        return res.status(400).send('회원가입 실패: 필수 정보 누락');
    }

    try {
        // 이메일 중복 확인
        const checkParams = {
            TableName: TABLE_NAME,
            FilterExpression: '#email = :email',
            ExpressionAttributeNames: { '#email': 'email' },
            ExpressionAttributeValues: { ':email': email }
        };
        const existingUsers = await dynamoDB.scan(checkParams).promise();
        
        if (existingUsers.Items.length > 0) {
            console.error('이메일 중복');
            return res.status(409).send('회원가입 실패: 이미 존재하는 이메일입니다.');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const params = {
            TableName: TABLE_NAME,
            Item: {
                userId: uuidv4(), 
                name,
                email,
                password: hashedPassword
            }
        };

        await dynamoDB.put(params).promise();
        console.log('DynamoDB 저장 성공');
        res.status(200).send('회원가입 성공');
    } catch (err) {
        console.error('DynamoDB 저장 오류:', err);
        res.status(500).send('회원가입 실패: 서버 오류');
    }
});

// 로그인 요청 처리
app.post('/login', async (req, res) => {
    console.log('로그인 요청 수신:', req.body);

    const { email, password } = req.body; 

    if (!email || !password) {
        console.error('요청 데이터 누락');
        return res.status(400).send('로그인 실패: 필수 정보 누락');
    }

    const params = {
        TableName: TABLE_NAME,
        FilterExpression: '#email = :email',
        ExpressionAttributeNames: { '#email': 'email' },
        ExpressionAttributeValues: { ':email': email }
    };

    try {
        const data = await dynamoDB.scan(params).promise();

        if (data.Items.length === 0) {
            return res.status(404).send('로그인 실패: 사용자 없음 또는 이메일 불일치');
        }

        const user = data.Items[0];
        const match = await bcrypt.compare(password, user.password); 

        if (!match) {
            return res.status(401).send('로그인 실패: 비밀번호 불일치');
        }

        res.status(200).send('로그인 성공');
    } catch (err) {
        console.error('로그인 오류:', err);
        res.status(500).send('로그인 실패: 서버 오류');
    }
});

// 서버 시작
app.listen(PORT, () => {
    console.log('서버 시작 준비 중');
    console.log(`서버 실행 중: http://localhost:${PORT}`);
});

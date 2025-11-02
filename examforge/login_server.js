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
// 💡 수정 1: DynamoDB 테이블 이름을 'User-Data-Dev'로 변경
const TABLE_NAME = 'User-Data-Dev'; 

app.use(cors());
app.use(bodyParser.json());

// 정적 파일 제공 (public 폴더)
app.use(express.static(path.join(__dirname, 'public')));

// 루트 경로에서 index.html 제공
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
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
        // 이메일 중복 확인 (DynamoDB scan은 비효율적이나, email 필드에 GSI가 없으면 불가피)
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
                // DynamoDB 기본 키 필드 이름을 userId로 사용
                userId: uuidv4(), 
                name,
                email, // 이메일을 저장
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

// 💡 수정 2: 'name' 기반 로그인에서 'email' 기반 로그인으로 변경
app.post('/login', async (req, res) => {
    console.log('로그인 요청 수신:', req.body);

    // 클라이언트에서 'email'과 'password'를 받도록 변경
    const { email, password } = req.body; 

    if (!email || !password) {
        console.error('요청 데이터 누락');
        return res.status(400).send('로그인 실패: 필수 정보 누락');
    }

    // ⚠️ 경고: email 필드에 GSI가 없다면, 이 scan 작업은 매우 비효율적입니다.
    // 대량의 사용자가 있을 경우 반드시 email에 Global Secondary Index (GSI)를 만드세요.
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
        // 저장된 해시된 비밀번호와 입력된 비밀번호 비교
        const match = await bcrypt.compare(password, user.password); 

        if (!match) {
            return res.status(401).send('로그인 실패: 비밀번호 불일치');
        }

        // 비밀번호를 제외한 사용자 정보로 로그인 성공 응답
        // 이 부분에서 세션/JWT 토큰을 발급하는 것이 일반적입니다.
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

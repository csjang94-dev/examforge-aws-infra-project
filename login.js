// login.js

function showSignup() { 
    document.getElementById('login-form').style.display = 'none'; 
    document.getElementById('signup-form').style.display = 'block'; 
} 

function showLogin() { 
    document.getElementById('signup-form').style.display = 'none'; 
    document.getElementById('login-form').style.display = 'block'; 
} 

async function signup(e) { 
    e.preventDefault();

    // 회원가입 필드: name, email, password
    const name = document.getElementById('signup-name').value; // HTML 폼 ID 확인 필요
    const email = document.getElementById('signup-email').value; // HTML 폼 ID 확인 필요
    const password = document.getElementById('signup-password').value; // HTML 폼 ID 확인 필요
    
    if (!name || !email || !password) { 
        alert('모든 필드를 입력해주세요.'); 
        return; 
    } 
    
    try { 
        const res = await fetch('http://localhost:3000/signup', { 
            method: 'POST', 
            headers: { 'Content-Type': 'application/json' }, 
            body: JSON.stringify({ name, email, password }) 
        }); 
        
        const result = await res.text(); 
        
        alert(result); 
        
        if (res.ok) {
             // 회원가입 성공 시 로그인 폼으로 전환
             showLogin(); 
        }
    } catch (err) { 
        console.error('회원가입 오류:', err); 
        alert('회원가입 실패: 서버 오류'); 
    } 
} 
                
async function login(e) { 
    e.preventDefault(); 
    
    // 💡 수정: 'name' 대신 'email'을 받도록 변경 (HTML 폼 ID 확인 필요)
    const email = document.getElementById('login-email').value; 
    const password = document.getElementById('login-password').value; 
    
    if (!email || !password) { 
        alert('이메일과 비밀번호를 입력해주세요.'); 
        return; 
    } 
    
    try { 
        const res = await fetch('http://localhost:3000/login', { 
            method: 'POST', 
            headers: { 'Content-Type': 'application/json' }, 
            // 💡 수정: name 대신 email을 서버로 전송
            body: JSON.stringify({ email, password }) 
        }); 
        
        const result = await res.text(); 
        
        alert(result); 
        
        if (res.ok && result === '로그인 성공') { 
            // 로그인 성공 시 페이지 이동 
            // index.html은 보통 로그인 폼이 있는 페이지이므로, 
            // 실제 서비스 페이지(예: /main.html)로 변경해야 할 수 있습니다.
            window.location.href = '/index.html'; 
        } 
    } catch (err) { 
        console.error('로그인 오류:', err); 
        alert('로그인 실패: 서버 오류'); 
    } 
}

// ⚠️ 참고: HTML 파일에서 'signup'과 'login' 함수를 폼의 submit 이벤트에 연결해야 하며,
// 다음 ID들이 정확히 일치해야 합니다.
// 회원가입: signup-name, signup-email, signup-password
// 로그인: login-email, login-password

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

    // 💡 수정 1: HTML의 새로운 ID 사용
    const name = document.getElementById('signup-name').value; 
    const email = document.getElementById('signup-email').value; 
    const password = document.getElementById('signup-password').value; 
    
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
             showLogin(); 
        }
    } catch (err) { 
        console.error('회원가입 오류:', err); 
        alert('회원가입 실패: 서버 오류'); 
    } 
} 
                
async function login(e) { 
    e.preventDefault(); 
    
    // 💡 수정 2: HTML의 새로운 ID 사용 (email 기반 로그인)
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
            // 💡 수정 3: name 대신 email을 서버로 전송
            body: JSON.stringify({ email, password }) 
        }); 
        
        const result = await res.text(); 
        
        alert(result); 
        
        if (res.ok && result === '로그인 성공') { 
            // 로그인 성공 시 페이지 이동
            window.location.href = '/index.html'; 
        } 
    } catch (err) { 
        console.error('로그인 오류:', err); 
        alert('로그인 실패: 서버 오류'); 
    } 
}

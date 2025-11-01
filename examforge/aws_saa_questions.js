// JSON 파일 불러오기
  fetch("aws_saa_questions.json")
    .then(res => res.json())
    .then(data => {
      const container = document.getElementById("questions");
      container.innerHTML = "";

      data.forEach(item => {
        const div = document.createElement("div");
        div.className = "question";

        const title = document.createElement("h2");
        title.textContent = `문제 ${item.문제번호}`;
        div.appendChild(title);

        const question = document.createElement("p");
        question.textContent = item.질문;
        div.appendChild(question);

        // 보기 목록
        for (const [key, value] of Object.entries(item.보기)) {
          const choice = document.createElement("div");
          choice.className = "choice";
          choice.textContent = `${key}. ${value}`;
          div.appendChild(choice);
        }

        const answer = document.createElement("div");
        answer.className = "answer";
        answer.textContent = `정답: ${item.정답}`;
        div.appendChild(answer);

        container.appendChild(div);
      });
    })
    .catch(err => {
      document.getElementById("questions").textContent = "❌ 문제 데이터를 불러올 수 없습니다.";
      console.error(err);
    });
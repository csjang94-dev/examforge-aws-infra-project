let cards = [];
let index = 0;
let flipped = false;

fetch("flashcard.json")
  .then(res => res.json())
  .then(data => {
    cards = data;
    showCard();
  })
  .catch(err => {
    document.getElementById("question").textContent = "❌ 데이터를 불러올 수 없습니다.";
    document.getElementById("desc").textContent = err.message;
  });

function showCard() {
  const card = document.getElementById("card");
  flipped = false;
  card.classList.remove("flipped");

  document.getElementById("completeMessage").style.display = "none";

  if (!cards.length) {
    document.getElementById("question").textContent = "카드를 불러올 수 없습니다.";
    document.getElementById("desc").textContent = "";
    document.getElementById("answer").textContent = "";
    return;
  }

  const current = cards[index];
  const fullDesc = current.설명 || current.desc || "";
  const sentences = fullDesc.split(/(?<=[.!?])\s+/);
  const limitedDesc = sentences.slice(0, 3).join(" ");

  document.getElementById("question").textContent = "이 서비스는 무엇일까요?";
  document.getElementById("desc").textContent = limitedDesc;
  document.getElementById("answer").textContent = "정답: " + (current.제목 || current.title);
}

function flipCard() {
  const card = document.getElementById("card");
  flipped = !flipped;
  card.classList.toggle("flipped");
}

document.getElementById("flipBtn").addEventListener("click", flipCard);
document.getElementById("card").addEventListener("click", flipCard);

document.getElementById("nextBtn").addEventListener("click", () => {
  if (index < cards.length - 1) {
    index++;
    showCard();
  } else {
    // 마지막 카드 이후 완료 메시지 표시
    document.getElementById("completeMessage").style.display = "block";
  }
});

document.getElementById("prevBtn").addEventListener("click", () => {
  if (index > 0) {
    index--;
    showCard();
  }
});

LocalTime = {
  mounted() {
    // 요소의 textContent(UTC 시간)를 가져와서 Date 객체로 변환
    // 서버에서 "2025-11-19T10:30:00Z" 형식으로 내려준다고 가정
    const dt = new Date(this.el.getAttribute("datetime"));

    // 옵션 설정: 초(second)를 제외하고 시, 분까지만 설정
    const options = {
      year: 'numeric',   // 2025년
      month: 'numeric',  // 11월
      day: 'numeric',    // 20일
      hour: '2-digit',   // 10시
      minute: '2-digit', // 51분
      // second: '2-digit' // <-- 이 줄이 없으면 초는 안 나옵니다!
    };

    // 첫 번째 인자에 undefined를 넣으면 브라우저 기본 언어 설정(사용자 로케일)을 따릅니다.
    // 한국어 강제 설정을 원하시면 'ko-KR'을 넣으세요.
    this.el.textContent = dt.toLocaleString(undefined, options);

    this.el.classList.remove("invisible")
  }
}
export default LocalTime;

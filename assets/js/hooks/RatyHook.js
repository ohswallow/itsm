// import Raty from "../vendor/raty";

// const RatyHook = {
//   mounted() {
//     this.initRaty();
//   },

//   updated() {
//     this.initRaty();
//   },

//   initRaty() {
//     const el = this.el;
//     const score = parseFloat(el.dataset.score) || 0;

//     // 기존에 초기화된 거 있으면 제거 (중복 방지)
//     if (el.ratyInstance) {
//       el.innerHTML = "";
//     }

//     const raty = new Raty(el, {
//       score: score,
//       readOnly: true,
//       half: true,
//       path: "/images", // raty 이미지 폴더 경로
//       starHalf: "star-half.png",
//       starOff: "star-off.png",
//       starOn: "star-on.png",
//     });

//     raty.init();

//     // 나중에 필요하면 destroy 할 수 있게 보관
//     el.ratyInstance = raty;
//   },
// };

// export default RatyHook;

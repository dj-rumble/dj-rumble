import confetti from "canvas-confetti";

let confettiAlreadyFalling = false
let randomConfettiWasUsedByMap = {}

export const dropConfetti = () => {
  if (!confettiAlreadyFalling) {
    confettiAlreadyFalling = true
    let duration = 3 * 1000;
    let animationEnd = Date.now() + duration;
    // let skew = 1;
    (function frame() {
      let timeLeft = animationEnd - Date.now();
      // launch a few confetti from the left edge
      confetti({
        angle: 60,
        origin: { x: 0, y: 0.6 },
        particleCount: 8,
        scalar: randomInRange(0.7, 1.4),
        spread: 75
      });
      // and launch a few from the right edge
      confetti({
        angle: 120,
        origin: { x: 1, y: 0.6 },
        particleCount: 8,
        scalar: randomInRange(0.7, 1.4),
        spread: 75
      });

      confetti({
        angle: -90,
        origin: { x: 0.5, y: -0.2 },
        particleCount: 4,
        scalar: randomInRange(0.7, 1.4),
        spread: 75
      });

      // keep going until we are out of time
      if (timeLeft > 0) {
        requestAnimationFrame(frame);
      } else {
        confettiAlreadyFalling = false
      }
    }());
  }
}

export const randomConfetti = (username) => {
  if (!randomConfettiWasUsedBy(username)) {
    randomConfettiWasUsedByMap[username] = true
    let cooldown = 3 * 1000;

    (function frame() {
      confetti({
        decay: 0.92,
        origin: { x: randomInRange(0.3, 0.7), y: randomInRange(0.3, 0.7) },
        particleCount: 200,
        scalar: randomInRange(1.4, 1.8),
        spread: 360,
        startVelocity: 20
      });

      setTimeout(() => {
        randomConfettiWasUsedByMap[username] = false
      }, cooldown)
    }());
  }
}

function randomConfettiWasUsedBy(username) {
  return randomConfettiWasUsedByMap[username]
}

function randomInRange(min, max) {
  return Math.random() * (max - min) + min;
}

// (function frame() {
    //   var timeLeft = animationEnd - Date.now();
    //   var ticks = Math.max(1000, 500 * (timeLeft / duration));
    //   skew = Math.max(0.8, skew - 0.001);

    //   confetti({
    //     particleCount: 1,
    //     startVelocity: 0,
    //     ticks: ticks,
    //     origin: {
    //       x: Math.random(),
    //       // since particles fall down, skew start toward the top
    //       y: (Math.random() * skew) - 0.2
    //     },
    //     colors: [ Math.floor(Math.random()*16777215).toString(16) ],
    //     gravity: randomInRange(0.4, 1.9),
    //     scalar: randomInRange(0.4, 2),
    //     drift: randomInRange(-0.4, 0.4)
    //   });

    //   if (timeLeft > 0) {
    //     requestAnimationFrame(frame);
    //   }
    // }())

    // let canvas = document.getElementById('confetti-canvas');
    // let confettiSettings =
    //   {
    //     clock: 30,
    //     max: 333,
    //     props: ['circle', 'square', 'triangle'],
    //     rotate: true,
    //     size: 1.3,
    //     target: confettiElement
    //   };
    // let confetti = new ConfettiGenerator(confettiSettings);
    // confetti.render();

    // setTimeout(() => {
    //   confetti.clear()
    // }, 10000)

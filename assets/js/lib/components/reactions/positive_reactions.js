import { prepareContainer, teardownContainer } from '../../element-utils'
import { CANVAS_ID } from '../../constants/elements'
import confetti from "canvas-confetti";
import sprinkler from 'sprinkler';

let confettiAlreadyFalling = false

export const dropConfetti = () => {
  if (!confettiAlreadyFalling) {
    confettiAlreadyFalling = true
    const duration = 3 * 1000;
    const animationEnd = Date.now() + duration;
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

export const randomShootingStars = () => {
  const canvas = document.getElementById(CANVAS_ID);
  prepareContainer(canvas)

  const _sprinkler = sprinkler.create(canvas)

  const opts = {
    aMax: 0.7, aMin: 0.9,
    angle: -7 * Math.PI / 6,
    ddxMax: -10, ddxMin: 10,
    ddyMax: 250, ddyMin: 400,
    drMax: 0, drMin: 0,
    dyMax: 1000, dyMin: 1500,
    imagesInSecond: 10,
    rMax: Math.PI, rMin: Math.PI,
    tail: {
      decay: 1,
      imageUrls: [
        '../images/spacex-rockets/flames/flame.png',
        '../images/spacex-rockets/flames/flameb.png'
      ],
      length: 1,
      x: 0,
      xOff: 0,
      y: 0
    },
    zMax: 0.15, zMin: 0.2
  }

  const stop = _sprinkler.start({
    '../images/star.svg': 5 // 5 v1.0
  }, Object.assign({}, opts, {
    imagesInSecond: opts.imagesInSecond * 5 / 30,
    tail: Object.assign({}, opts.tail, {
      yOff: -140
    })
  }))

  teardownContainer(canvas, 2500)
  setTimeout(stop, 2500)
}

function randomInRange(min, max) {
  return Math.random() * (max - min) + min;
}

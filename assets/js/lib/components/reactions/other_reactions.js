import confetti from "canvas-confetti";
import sprinkler from 'sprinkler';

let randomConfettiWasUsedByMap = {}

export const showLonelyAtmosphere = () => {
  setTimeout(() => {
    let stopRain = startRain()

    showDesertRollingPlant(stopRain)
  }, 1000)
}

export const showDesertRollingPlant = (stopRain) => {
    let desertContainer = document.getElementById('desert-container')

    const tumbleweed = document.createElement('div')
    tumbleweed.classList.add('tumbleweed')
    desertContainer.appendChild(tumbleweed)


    setTimeout(() => {
      desertContainer.removeChild(tumbleweed)
      tumbleweed.remove()
      stopRain()
    }, 5000)
}

export const startRain = () => {
  let canvas = document.getElementById('animations-canvas');
  let s = sprinkler.create(canvas)

  let stopRain = s.start(['../images/droplet.png'], {
    aMax: 1, aMin: 1,
    angle: Math.PI / 12,
    daMax: 0, daMin: 0,
    drMax: 0, drMin: 0,
    dyMax: 1500, dyMin: 1800,
    imagesInSecond: 50,
    rMax: 0, rMin: 0,
    zMax: 0.5, zMin: 0.5
  })

  return stopRain
}

export const randomSpaceXRocket = () => {
  let canvas = document.getElementById('animations-canvas');

  let s = sprinkler.create(canvas)

  let opts = {
    angle: 7 * Math.PI / 6,
    burnInSeconds: 20,
    ddxMax: 0, ddxMin: 0,
    ddyMax: 100, ddyMin: 200,
    drMax: 0, drMin: 0,
    dxMax: 0, dxMin: 0,
    dyMax: 0, dyMin: 0,
    imagesInSecond: 2,
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
    zMax: 0.5, zMin: 0.5
  }

  s.start({
    '../images/spacex-rockets/falcon9-v10.png': 5 // 5 v1.0
  }, Object.assign({}, opts, {
    imagesInSecond: opts.imagesInSecond * 5 / 78,
    tail: Object.assign({}, opts.tail, {
      yOff: -485
    })
  }))

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

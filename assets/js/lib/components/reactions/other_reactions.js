import {
  addClasslists,
  prepareContainer,
  teardownContainer
} from '../../element-utils'
import { CANVAS_ID } from '../../constants/elements'
import confetti from "canvas-confetti";
import sprinkler from 'sprinkler';

const randomConfettiWasUsedByMap = {}

export const showLonelyAtmosphere = () => {
  setTimeout(() => {
    const stopRain = startRain()

    showDesertRollingPlant(stopRain)
  }, 1000)
}

const showDesertRollingPlant = (stopRain) => {
  const desertGhostContainer = document.getElementById('desert-ghost-container')
  addClasslists(
    desertGhostContainer,
    ['absolute', 'bottom-96', 'w-11/12', 'z-999']
  )

  const tumbleweed = document.createElement('div')
  tumbleweed.classList.add('tumbleweed')
  desertGhostContainer.appendChild(tumbleweed)

  setTimeout(() => {
    desertGhostContainer.removeChild(tumbleweed)
    tumbleweed.remove()
    stopRain()
  }, 5000)
}

const startRain = () => {
  const canvas = document.getElementById(CANVAS_ID);
  prepareContainer(canvas)

  const _sprinkler = sprinkler.create(canvas)

  const stopRain = _sprinkler.start(['../images/droplet.png'], {
    aMax: 1, aMin: 1,
    angle: Math.PI / 12,
    daMax: 0, daMin: 0,
    drMax: 0, drMin: 0,
    dyMax: 1500, dyMin: 1800,
    imagesInSecond: 50,
    rMax: 0, rMin: 0,
    zMax: 0.5, zMin: 0.5
  })

  teardownContainer(canvas)

  return stopRain
}

export const randomSpaceXRocket = () => {
  const canvas = document.getElementById(CANVAS_ID);
  prepareContainer(canvas)
  const _sprinkler = sprinkler.create(canvas)

  const opts = {
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

  _sprinkler.start({
    '../images/spacex-rockets/falcon9-v10.png': 5 // 5 v1.0
  }, Object.assign({}, opts, {
    imagesInSecond: opts.imagesInSecond * 5 / 78,
    tail: Object.assign({}, opts.tail, {
      yOff: -485
    })
  }))

  teardownContainer(canvas)
}

export const randomConfetti = (username) => {
  if (!randomConfettiWasUsedBy(username)) {
    randomConfettiWasUsedByMap[username] = true
    const cooldown = 3000;

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

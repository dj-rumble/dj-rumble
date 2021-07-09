import ConfettiGenerator from "confetti-js";
import sprinkler from 'sprinkler';


export const dropTomatoes = () => {
  let canvas = document.getElementById('animations-canvas');

  let confettiSettings =
    {
      clock: 200,
      max: 15,
      props: [
        { src: "../images/tomatoes/tomato-1-m.svg", type: "svg" },
        { src: "../images/beer/beer-1.svg", type: "svg" },
        { src: "../images/poo-1.svg", type: "svg" },
        { src: "../images/tomatoes/tomato-2-m.svg", type: "svg" },
        { src: "../images/beer/beer-2.svg", type: "svg" }
      ],
      respawn: false,
      rotate: true,
      size: 6,
      start_from_edge: true,
      target: canvas
    };
  let confetti = new ConfettiGenerator(confettiSettings);
  confetti.render();

  setTimeout(() => {
    confetti.clear()
  }, 8000)
}

export const dropOneTomato = () => {
  let canvas = document.getElementById('animations-canvas');

  let confettiSettings =
  {
      clock: 200,
      max: 1,
      props: [
        {
          src: "../images/tomatoes/tomato-1-m.svg", type: "svg"
        },
        {
          src: "../images/tomatoes/tomato-2-m.svg", type: "svg"
        }
      ],
      respawn: false,
      rotate: true,
      size: 10,
      start_from_edge: true,
      target: canvas
    }
  let confetti = new ConfettiGenerator(confettiSettings);
  confetti.render();
}

export const dropTomatoesWithSprinkler = () => {
  let canvas = document.getElementById('animations-canvas');
  let rain = sprinkler.create(canvas)

  let images = [
    '../images/tomatoes/tomato-1-m.svg',
    '../images/tomatoes/tomato-2-m.svg'
  ]

  // Start the animation
  let stop = rain.start(images, {
    aMax: 1, aMin: 1,
    burnInSeconds: 20,
    daMax: 0, daMin: 0,
    drMax: 5, drMin: 2,
    dxMax: 1, dxMin: -1,
    dyMax: 250, dyMin: 150,
    dzMax: 0, dzMin: 0,
    imagesInSecond: 2,
    rMax: 2 * Math.PI, rMin: 0,
    zMax: 0.25, zMin: 0.1
  })

  setTimeout(stop, 4000)
}

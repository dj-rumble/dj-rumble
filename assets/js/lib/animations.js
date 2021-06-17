import ConfettiGenerator from "confetti-js";

export const spawnHeart = (container, voteType) => {
  const iconContainer = document.createElement('div')
  iconContainer.classList.add('hearts-wrapper')

  const icon = document.createElement('div')
  icon.classList.add('altheart')
  icon.classList.add('heart')
  icon.classList.add(voteType)
  icon.classList.add('wave')
  iconContainer.appendChild(icon)

  container.appendChild(iconContainer)

  setTimeout(() => {
    iconContainer.removeChild(icon)
    container.removeChild(iconContainer)
  }, 3000)
}

export const dropConfetti = () => {
  let confettiElement = document.getElementById('confetti-canvas');
  let confettiSettings =
  {
    clock: 30,
    max: 333,
    props: ['circle', 'square', 'triangle'],
    rotate: true,
    size: 1.3,
    target: confettiElement
  };
  let confetti = new ConfettiGenerator(confettiSettings);
  confetti.render();

  // setTimeout(() => {
  //   confetti.clear()
  // }, 10000)
}

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

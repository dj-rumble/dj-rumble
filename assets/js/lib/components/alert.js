import { addClasslists } from '../element-utils'

export const spawnAlert = (
  alertElement,
  alertContent,
  backgroundContent,
  alertText
) => {

  backgroundContent.classList.remove("opacity-100")
  backgroundContent.classList.add("opacity-30")
  alertElement.classList.remove('invisible')

  addClasslists(
    alertElement,
    [
      'visible',
      'transition',
      'duration-500',
      'ease-in-out',
      'transform',
      'translate-y-8',
      'opacity-100'
    ]
  )

  const text = document.createElement('p')
  addClasslists(
    text,
    [
      'text-red-500',
      'self-start',
      'pt-6',
      'font-street-ruler',
      'text-5xl',
      'animate-pulse'
    ]
  )

  text.innerHTML = alertText
  alertContent.replaceChildren(text)
}

export const destroyAlert = (alertElement, alertContent, backgroundContent) => {
  backgroundContent.classList.remove("opacity-30")
  backgroundContent.classList.add("opacity-100")
  const text = document.createElement('p')


  setTimeout(() => {
    text.innerHTML = ''
    alertContent.replaceChildren(text)
    alertElement.classList.remove('visible')
    alertElement.classList.add('invisible')
  }, 1000)
}

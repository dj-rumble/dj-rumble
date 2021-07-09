export const addClasslists = (element, classes) => {
  classes.forEach(cssClass => {
    element.classList.add(cssClass)
  });
}

export const removeClasslists = (element, classes) => {
  classes.forEach(cssClass => {
    element.classList.remove(cssClass)
  });
}

export const prepareContainer = element => {
  addClasslists(element, ['w-full', 'h-full', 'z-999'])
  element
}

export const teardownContainer = (element, timeout = 5000) => {
  setTimeout(() => {
    removeClasslists(element, ['w-full', 'h-full', 'z-999'])
    element.width = 0
    element.height = 0
  }, timeout)
}

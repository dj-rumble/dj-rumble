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

export const handleNotification = async args => {
  if (Notification.permission !== 'denied') {
    const permission = await Notification.requestPermission()
    if (permission === "granted") {
      const notification = spawnNotification(args)
      teardownNotification(notification)
    }
  }
}

const spawnNotification = ({ body, title, img, tag }) => {
  const options = {
    badge: img,
    body,
    icon: img,
    tag
  }
  return new Notification(title, options)
}

const teardownNotification = notification => {
  setTimeout(() => {
    notification.close()
  }, 5000)
}

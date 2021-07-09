import { handleNotification } from "../handlers/notification-handler"

const NotificationsHandling = () => ({
  mounted() {
    this.handleEvent('receive_notification', args => {
      handleNotification(args)
    })
  }
})

export default NotificationsHandling

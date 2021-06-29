import { destroyAlert, spawnAlert } from '../components/alert'
import topbar from "topbar"

const TOPBAR_CONFIG = {
  autoRun: true,
  barColors: {
  '.3': 'rgba(41,  128, 185, .7)',
  '0': 'rgba(26,  188, 156, .7)',
  '1.0': 'rgba(231, 76,  60,  .7)'
  },
  barThickness: 5,
  className: 'topbar',
  shadowBlur: 5,
  shadowColor: 'rgba(0, 0, 0, .5)'
}

const GLOBAL_ALERT_ID = 'dj-rumble-alert'
const GLOBAL_ALERT_CONTENT_ID = 'dj-rumble-alert-container'
const GLOBAL_INNER_CONTENT_ID = 'dj-rumble-inner-content'

export const handlePageLoadingStart = info => {
  if (info.detail && info.detail.kind && info.detail.kind === "error") {

    const texts = [
      "The bits are breeding...",
      "Swapping time and space...",
      "Entangling superstrings...",
      "Pushing pixels...",
      "Grabbing extra minions",
      'Plugging services...',
      'Connecting to the server...'
    ]
    const alertText = texts[Math.floor(Math.random() * texts.length)]
    const alertElement = document.getElementById(GLOBAL_ALERT_ID)
    const alertContent = document.getElementById(GLOBAL_ALERT_CONTENT_ID)
    const backgroundContent = document.getElementById(GLOBAL_INNER_CONTENT_ID)

    spawnAlert(alertElement, alertContent, backgroundContent, alertText)
  }

  topbar.config(TOPBAR_CONFIG)
  topbar.show()
}

export const handlePageLoadingStop = () => {
  const alertElement = document.getElementById(GLOBAL_ALERT_ID)
  const alertContent = document.getElementById(GLOBAL_ALERT_CONTENT_ID)
  const backgroundContent = document.getElementById(GLOBAL_INNER_CONTENT_ID)

  destroyAlert(alertElement, alertContent, backgroundContent)

  topbar.hide()
}

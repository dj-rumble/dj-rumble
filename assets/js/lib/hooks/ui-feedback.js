import { dropConfetti, randomConfetti } from '../../lib/components/confetti'
// import { dropReactionTo } from '../../lib/components/reactions'
import {
  handlePageLoadingStart,
  handlePageLoadingStop
} from '../../lib/handlers/connection-lost.js'
import { spawnHeart } from '../../lib/components/heart'
import topbar from "topbar"

const UiFeedback = () => ({
  mounted() {
    this.handleEvent('receive_score', ({ type }) => {
      const elementId = `djrumble-score-${type}`
      const container = document.getElementById(elementId)

      spawnHeart(container, type)

      // dropReactionTo(type)
    })

    this.handleEvent('drop_confetti', () => {
      dropConfetti()
    })

    this.handleEvent('throw_confetti_interaction', (byUser) => {
      randomConfetti(byUser.user)
    })

    // Show progress bar on live navigation and form submits
    topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
    window.addEventListener("phx:page-loading-start", handlePageLoadingStart)
    window.addEventListener("phx:page-loading-stop", handlePageLoadingStop)
  }
})

export default UiFeedback

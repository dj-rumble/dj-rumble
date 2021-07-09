import {
  dropConfetti,
  randomShootingStars
} from '../components/reactions/positive_reactions'
import {
  dropOneTomato,
  dropTomatoes
} from '../components/reactions/negative_reactions'
import {
  handlePageLoadingStart,
  handlePageLoadingStop
} from '../../lib/handlers/connection-lost.js'
import {
  randomConfetti,
  showLonelyAtmosphere
} from '../components/reactions/other_reactions'
import topbar from "topbar"

const UiFeedback = () => ({
  mounted() {
    this.handleEvent('receive_score', ({ type }) => {
      if (type === "positive") {
        randomShootingStars()
      } else {
        dropOneTomato()
      }
    })

    this.handleEvent('drop_confetti', () => {
      dropConfetti()
    })

    this.handleEvent('drop_tomatoes', () => {
      dropTomatoes()
    })

    this.handleEvent('show_desert_rolling_plant', () => {
      showLonelyAtmosphere()
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

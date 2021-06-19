import { dropConfetti, randomConfetti, spawnHeart } from '../lib/animations'

const UiFeedback = () => ({
  mounted() {
    this.handleEvent('receive_score', ({ type }) => {
      const elementId = `djrumble-score-${type}`
      const container = document.getElementById(elementId)

      spawnHeart(container, type)
    })

    this.handleEvent('drop_confetti', () => {
      dropConfetti()
    })

    this.handleEvent('throw_confetti_interaction', (byUser) => {
      randomConfetti(byUser.user)
    })
  }
})

export default UiFeedback

import { spawnHeart } from '../lib/animations'

const UiFeedback = () => ({
  mounted() {
    this.handleEvent('receive_score', ({ type }) => {
      const elementId = `djrumble-score-${type}`
      const container = document.getElementById(elementId)

      spawnHeart(container)
    })
  }
})

export default UiFeedback

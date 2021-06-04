const UiFeedback = () => ({
  mounted() {

    this.handleEvent('receive_score', ({type}) => {
      console.log(`Score: ${type}`)
    })
  }
})

export default UiFeedback

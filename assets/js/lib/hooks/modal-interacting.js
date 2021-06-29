
const ModalInteracting = () => ({
  mounted() {
    const handleOpenCloseEvent = ({ id: id, opened: opened }) => {
      if (opened) {
        const modalDialog = document.getElementById(id)
        modalDialog.classList.add('bg-black')
        modalDialog.classList.add('bg-opacity-50')

        const modal = document.getElementById(`${id}-dialog`)
        modal.classList.add('animated-bounce')

        setTimeout(() => {
          modal.classList.remove('animated-bounce')
        }, 1000);
      }
    }

    this.handleEvent('modal-changed', handleOpenCloseEvent)
  }
})

export default ModalInteracting

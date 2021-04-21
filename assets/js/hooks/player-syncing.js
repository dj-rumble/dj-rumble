import { secondsToTime } from '../lib/date-utils'

const updateTimeDisplay = (timeTrackerElem, time) => {
  const videoTime = (time === 0 || time === undefined)
    ? '-'
    : secondsToTime(parseInt(time))
  timeTrackerElem.innerText = videoTime
}

const updateVideoSlider = (
  timeSliderElem,
  playerCurrentTime,
  playerTotalTime,
) => {
  timeSliderElem.min = 0
  timeSliderElem.max = playerTotalTime
  timeSliderElem.value = playerCurrentTime
}


const udpateTimeDisplays = (startTimeTrackerElem, endTimeTrackerElem, timeSliderElem, player) => {
  const currentTime = player.getCurrentTime()
  const totalTime = player.getDuration()
  updateTimeDisplay(startTimeTrackerElem, currentTime)
  updateTimeDisplay(endTimeTrackerElem, totalTime)
  updateVideoSlider(timeSliderElem, currentTime, totalTime)
}

const onStateChange = (
  hookContext,
  startTimeTrackerElem,
  endTimeTrackerElem,
  timeSliderElem
) => event => {
  switch (event.data) {
    case -1: {
      break
    }
    case 0: {
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      break
    }
    case 1: {
      const { target: player } = event
      const trackTimeInterval = setInterval(() => {
        udpateTimeDisplays(
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem,
          player,
        )
      }, 1000)
      hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
      break
    }
    case 2: {
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      const { target: player } = event
      udpateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player,
      )
      break
    }
    case 3: {
      break
    }
    case 5: {
      break
    }
  }
}

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const startTimeTrackerElem = document.getElementById('yt-video-start-time')
    const endTimeTrackerElem = document.getElementById('yt-video-end-time')
    const timeSliderElem = document.getElementById('video-time-control')
    const player = await initPlayer(
      onStateChange(
        this,
        startTimeTrackerElem, endTimeTrackerElem, timeSliderElem
      ),
    )
    player.playVideo()
  }
})

export default PlayerSyncing

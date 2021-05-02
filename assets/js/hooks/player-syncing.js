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
  playerTotalTime
) => {
  timeSliderElem.min = 0
  timeSliderElem.max = playerTotalTime
  timeSliderElem.value = playerCurrentTime
}


const updateTimeDisplays = (
  startTimeTrackerElem,
  endTimeTrackerElem,
  timeSliderElem,
  player
) => {
  const currentTime = player.getCurrentTime()
  const totalTime = player.getDuration()
  updateTimeDisplay(startTimeTrackerElem, currentTime)
  updateTimeDisplay(endTimeTrackerElem, totalTime)
  updateVideoSlider(timeSliderElem, currentTime, totalTime)
}

const playNextVideo = (hookContext) => {
  hookContext.pushEvent('next_video')
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
      playNextVideo(hookContext)
      break
    }
    case 1: {
      const { target: player } = event
      const trackTimeInterval = setInterval(() => {
        updateTimeDisplays(
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem,
          player
        )
      }, 1000)
      hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
      break
    }
    case 2: {
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      const { target: player } = event
      updateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player
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

    const onPlayerReady = () => {
      /**
       * player_is_ready
       * 
       * Tells the server the player is ready to receive events
       */
      this.pushEvent('player_is_ready')
    }

    const player = await initPlayer(
      onStateChange(
        this,
        startTimeTrackerElem, endTimeTrackerElem, timeSliderElem
      ),
      onPlayerReady
    )

    /**
     * receive_player_state
     * 
     * Receives an update state of the video player
     */
    this.handleEvent('receive_player_state', ({
      shouldPlay,
      time = 0,
      videoId
    }) => {
      player.loadVideoById({ startSeconds: time, videoId })
      updateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player
      )
      !shouldPlay && player.pauseVideo()
    })
  }
})

export default PlayerSyncing

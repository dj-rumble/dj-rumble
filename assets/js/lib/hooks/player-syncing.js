import { secondsToTime } from '../../lib/date-utils'

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
     * playback_details_request
     *
     * Receives a request to answer with the total duration of a video
     */
    this.handleEvent('playback_details_request', ({
      time = 0,
      videoId = ''
    }) => {
      player.loadVideoById({ startSeconds: time, videoId })
      player.mute()
      player.playVideo()
      const getTotalDurationInterval = setInterval(() => {
        let duration = player.getDuration()

        if (duration !== undefined && duration !== 0) {
          clearInterval(getTotalDurationInterval)

          this.pushEvent('receive_video_time', {duration})
          player.pauseVideo()
          player.seekTo(0)
        }
      }, 150)
    })

    /**
     * receive_player_state
     *
     * Receives a video to play
     */
    this.handleEvent('receive_player_state', ({
      time = 0,
      videoId = ''
    }) => {
      player.loadVideoById({ startSeconds: time, videoId })
      player.unMute()
      player.playVideo()
      player.set
      updateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player
      )
    })
  }
})

export default PlayerSyncing

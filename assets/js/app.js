// Used to support async/wait functions
import "regenerator-runtime/runtime"
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for
// example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import ChatSyncing from "./lib/hooks/chat-syncing"
import {LiveSocket} from "phoenix_live_view"
import LoadYTIframeAPI from './deps/yt-iframe-api'
import ModalInteracting from "./lib/hooks/modal-interacting"
import PlayerSyncing from "./lib/hooks/player-syncing"
import {Socket} from "phoenix"
import UiFeedback from "./lib/hooks/ui-feedback"
import createPlayer from './lib/player'


function onIframeReady() {
  initLiveview()
}

function initPlayer(onStateChange, onPlayerReady) {
  const playerContainer = document.getElementById("video-player")
  return createPlayer(playerContainer, {onPlayerReady, onStateChange})
}

function initLiveview() {
  let csrfToken = document.querySelector("meta[name='csrf-token']")
    .getAttribute("content")

  const hooks = {
    ChatSyncing: ChatSyncing(),
    ModalInteracting: ModalInteracting(),
    PlayerSyncing: PlayerSyncing(initPlayer),
    UiFeedback: UiFeedback()
  }

  let liveSocket = new LiveSocket("/live", Socket, {
    hooks,
    params: {
      _csrf_token: csrfToken,
      locale: Intl.NumberFormat().resolvedOptions().locale,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      timezone_offset: -(new Date().getTimezoneOffset() / 60)
    }
  })
  // connect if there are any LiveViews on the page
  liveSocket.connect()
  // expose liveSocket on window for web console debug logs and latency
  // simulation:
  // >> liveSocket.enableDebug()
  // >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser
  //    session
  // >> liveSocket.disableLatencySim()
  window.liveSocket = liveSocket
}

LoadYTIframeAPI(onIframeReady)

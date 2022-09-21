// https://github.com/maxogden/websocket-stream/blob/48dc3ddf943e5ada668c31ccd94e9186f02fafbd/ws-fallback.js
let WebWS = null

if (typeof WebSocket !== 'undefined') {
  WebWS = WebSocket
} else if (typeof MozWebSocket !== 'undefined') {
  WebWS = MozWebSocket
} else if (typeof global !== 'undefined') {
  WebWS = global.WebSocket || global.MozWebSocket
} else if (typeof window !== 'undefined') {
  WebWS = window.WebSocket || window.MozWebSocket
} else if (typeof self !== 'undefined') {
  WebWS = self.WebSocket || self.MozWebSocket
}

module.exports = {
  setupBaseWS: () => {
    if (!WebWS) {
      return null
    }
    const server = window.location.host
    const ws = new WebWS(`ws://${server}/websocket/base-info`)

    ws.addEventListener('message', (data) => {
      console.log('received: ', data)
    })

    ws.addEventListener('close', () => {
      console.log('ws close unexpected!')
    })

    ws.sendJSON = (data) => {
      if (typeof data === 'object') {
        data = JSON.stringify(data)
      }
      ws.send(data)
    }
    return ws
  }
}

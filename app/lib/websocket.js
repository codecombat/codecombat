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
const subOrUnsub = (type, topics, ws) => {
  if (!Array.isArray(topics) && typeof topics === 'string') {
    topics = [topics] // always send array
  }
  const msg = {
    type,
    topics
  }
  ws.send(JSON.stringify(msg))
}

module.exports = {
  websocketUrl: (path) => {
    const server = window.location.host
    let url = `wss://${server}/websocket`
    if (window.location.protocol !== 'https:') {
      url = `ws://${server}/websocket`
    }
    return url + path
  },
  setupBaseWS: () => {
    if (!WebWS) {
      console.log('WebSocket not found!')
      return null
    }
    const url = module.exports.websocketUrl('/base-info')
    const ws = new WebWS(url)

    ws.sendJSON = (data) => {
      if (typeof data === 'object') {
        data = JSON.stringify(data)
      }
      ws.send(data)
    }

    ws.subscribe = topics => subOrUnsub('subscribe', topics, ws)
    ws.unsubscribe = topics => subOrUnsub('unsubscribe', topics, ws)

    ws.publish = (topics, info) => {
      if (!Array.isArray(topics) && typeof topics === 'string') {
        topics = [topics] // always send array
      }
      const msg = {
        type: 'publish',
        topics,
        info
      }
      ws.send(JSON.stringify(msg))
    }

    ws.topicName = (topic, id) => `${topic}-${id}`
    return ws
  }
}

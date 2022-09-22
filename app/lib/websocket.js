const globalVar = require('core/globalVar')
const _ = require('lodash')
const Backbone = require('backbone')

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

const baseInfoHandler = {
  online: () => true, // when a user recieves a message, the user is online anyway
  'play-level': () => {
    const curView = globalVar.currentView
    if (curView.id === 'level-view' && curView.constructor.name === 'PlayLevelView') {
      return {
        levelID: curView.levelID,
        sessionID: curView.session.id.toString()
      }
    } else {
      return false
    }
  }
}

module.exports = {
  setupBaseWS: () => {
    if (!WebWS) {
      return null
    }
    const server = window.location.host
    const ws = new WebWS(`ws://${server}/websocket/base-info`)

    ws.addEventListener('message', (msg) => {
      let data = msg.data
      console.log('received: ', data)
      try {
        data = JSON.parse(data)
      } catch (e) {}

      if (data.type === 'fetch') {
        const obj = {
          to: data.from,
          type: 'send',
          infos: {}
        }
        data.infos.forEach(info => {
          obj.infos[info] = baseInfoHandler[info]()
        })
        console.log('send?', obj)
        ws.sendJSON(obj)
      } else if (data.type === 'send') {
        console.log('get infos from other user')
        globalVar.wsInfos = _.assign({}, globalVar.wsInfos, data.infos)
        console.log('trigger?')
        Backbone.Mediator.publish('websocket:update-infos')
        // globalVar.currentView.trigger('websocket:update-infos')
      }
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

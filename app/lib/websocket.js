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

const initWSInfos = {
  teacher: {
    students: {}, // student id as key so that easy to visit
    friends: {}
  },
  student: {
    teachers: {},
    friends: {}
  },
  home: {
    friends: {}
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


      switch (data.type) {
      case 'fetch':  // return infos
        const obj = {
          to: data.from,
          type: 'send',
          infos: {}
        }
        data.infos.forEach(info => {
          obj.infos[info] = baseInfoHandler[info]()
        })
        ws.sendJSON(obj)
        break
      case 'send': // receive infos
        // globalVar.wsInfos = _.assign({}, globalVar.wsInfos, data.infos)
        Backbone.Mediator.publish('websocket:update-infos')
        // globalVar.currentView.trigger('websocket:update-infos')
        break
      case 'pong': // check alive
        if (window.me.isStudent() && data.from in globalVar.wsInfos.teachers) {
          globalVar.wsInfos.teachers[data.from].alive = true
        } else if (window.me.isTeacher() && data.from in globalVar.wsInfos.students) {
          globalVar.wsInfos.students[data.from].alive = true
        }

        if (data.from in globalVar.wsInfos.friends) {
          globalVar.wsInfos.friends[data.from].alive = true
        }
        break

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
  },
  setupWSInfos: (me) => {
    if (me.isStudent()) {
      globalVar.wsInfos = initWSInfos.student
    } else if (me.isTeacher()) {
      globalVar.wsInfos = initWSInfos.teacher
    } else {
      globalVar.wsInfos = initWSInfos.home
    }
  },
  pingFriends: (me) => {
    let friends = []
    if (me.isStudent()) {
      friends = Object.keys(globalVar.wsInfos.teachers)
    } else if (me.isTeacher()) {
      friends = Object.keys(globalVar.wsInfos.students)
    }
    friends = [...friends, ...Object.keys(globalVar.wsInfos.friends)]

    globalVar.ws.sendJSON({
      to: friends,
      type: 'ping'
    })
  }
}

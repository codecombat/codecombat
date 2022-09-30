const _ = require('lodash')
const Backbone = require('backbone')
const CocoClass = require('core/CocoClass')
const websocket = require('lib/websocket')
const globalVar = require('core/globalVar')

let wsBus

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

module.exports = wsBus = class WsBus extends CocoClass {
  constructor (...args) {
    wsBus.prototype.subscriptions = {
      'auth:me-synced': 'onMeSynced'
    }
    super() // make sure we set prototype.subscriptions first

    this.ws = null
    this.wsInfos = { inited: false, friends: {} }
    this.connected = false
    this.reconnectInterval = undefined
    this.init()
  }

  init () {
    this.ws = websocket.setupBaseWS()
    this.ws.addEventListener('message', (msg) => {
      let data = msg.data
      console.log('received: ', data)
      try {
        data = JSON.parse(data)
      } catch (e) {}

      switch (data.type) {
      case 'fetch': // return infos
        this.onFetchMessage(data)
        break
      case 'send': // receive infos
        this.onSendMessage(data)
        // globalVar.currentView.trigger('websocket:update-infos')
        break
      case 'ping': // check alive
      case 'pong': // check alive
        this.updateFriend(data.from, { online: true })
        break
      }
    })
    this.ws.addEventListener('open', () => {
      this.connected = true
      if (this.reconnectInterval) {
        clearInterval(this.reconnectInterval)
      }
    })
    this.ws.addEventListener('close', () => {
      console.log('ws close unexpected! try reconnect in 10 secnds...')
      this.connected = false
      this.reconnectInterval = setInterval(() => this.ws = websocket.setupBaseWS(), 10000)
    })
  }

  onFetchMessage (data) {
    const obj = {
      to: data.from,
      type: 'send',
      infos: {}
    }
    data.infos.forEach(info => {
      obj.infos[info] = baseInfoHandler[info]()
    })
    this.ws.sendJSON(obj)
  }

  onSendMessage (data) {
    const newInfos = _.assign({},
                              this.wsInfos.friends[data.from].infos,
                              data.infos)
    this.wsInfos.friends[data.from].infos = newInfos
    Backbone.Mediator.publish('websocket:update-infos')
  }

  resetWSInfos () {
    this.wsInfos = {
      inited: false,
      friends: {} // role: friends | teacher | student
    }
  }

  onMeSynced () {
    this.ws.send('me synced') // ping to make sure server websocket has correct user id
    this.resetWSInfos()

    if (me.isAnonymous()) {
      this.wsInfos.inited = true // anonymous user do not have friends feature
    } else {
      const friends = me.get('friends') || [] // TODO: to setup true friends feature
      friends.forEach(f => {
        this.addFriend(f)
      })
    }
  }

  addFriend (id, state = { role: 'friend', online: false }) {
    console.log(`add friends ${id}`)
    let oldFriend = {}
    if (id in this.wsInfos.friends) {
      oldFriend = this.wsInfos.friends[id]
    }
    this.wsInfos.friends[id] = _.assign(state, oldFriend)
  }

  updateFriend (id, state) {
    console.log(`${id} is online`)
    if (!(id in this.wsInfos.friends)) {
      return
    }
    this.wsInfos.friends[id] = _.assign(this.wsInfos.friends[id], state)
  }

  pingFriends (friendList = undefined) {
    console.log('ping friends')
    const friends = friendList || Object.keys(this.wsInfos.friends)
    this.ws.sendJSON({
      to: friends,
      type: 'ping'
    })
  }
}
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
      // console.log('received: ', data)
      try {
        data = JSON.parse(data)
      } catch (e) {}

      switch (data.type) {
        case 'fetch': // return infos
          this.getFetchMessage(data)
          break
        case 'send': // receive infos
          this.getSendMessage(data)
          // globalVar.currentView.trigger('websocket:update-infos')
          break
        case 'publish':
          this.getPublishMessage(data)
          break
        // TODO: ping pong is not used now, can clean later (when websocket things almost finished)
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
      this.resetWSInfos()
    })
    this.ws.addEventListener('close', () => {
      console.log('ws close unexpected! try reconnect in 10 secnds...')
      this.connected = false
      this.reconnectInterval = setInterval(() => this.ws = websocket.setupBaseWS(), 10000)
    })
  }

  getFetchMessage (data) {
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

  getSendMessage (data) {
    const newInfos = _.assign({},
                              this.wsInfos.friends[data.from].infos,
                              data.infos)
    this.wsInfos.friends[data.from].infos = newInfos
    Backbone.Mediator.publish('websocket:update-infos')
  }

  getPublishMessage (data) {
    const [topic, id] = data.topic.split('-')
    switch (topic) {
      case 'user':
        this.updateFriend(id, data.info)
        break
    }
  }

  async resetWSInfos () {
    this.wsInfos = {
      inited: false,
      friends: {} // role: friends | teacher | student
    }

    if (me.isAnonymous()) {
      this.wsInfos.inited = true // anonymous user do not have friends feature
    } else {
      this.ws.publish(this.ws.topicName('user', me.id.toString()), { online: true }) // tell others you're online
      const friends = me.get('friends') || [] // TODO: to setup true friends feature
      const friendTopics = []
      friends.forEach(f => {
        this.addFriend(f.userId.toString(), { role: f.role })
        friendTopics.push(`user-${f.userId.toString()}`)
      })
      this.ws.subscribe(friendTopics)
      const onlineFriends = await me.fetchOnlineFriends() // fetch online friends
      onlineFriends.forEach(f => {
        this.updateFriend(f, { online: true })
      })
      this.wsInfos.inited = true
    }
    // console.log('wsInfos reset success')
  }

  async onMeSynced () {
    // this.ws.send('me synced') // ping to make sure server websocket has correct user id
    await this.resetWSInfos()
  }

  addFriend (id, { role = 'friend', online = false } = {}) {
    const state = { role, online }
    let oldFriend = {}
    if (id in this.wsInfos.friends) {
      oldFriend = this.wsInfos.friends[id]
    }
    this.wsInfos.friends[id] = _.assign(state, oldFriend) // do not override the friend here
  }

  updateFriend (id, state) {
    if (!(id in this.wsInfos.friends)) {
      return
    }
    this.wsInfos.friends[id] = _.assign(this.wsInfos.friends[id], state) // override friend here
  }
}
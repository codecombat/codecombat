// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Bus;
const CocoClass = require('core/CocoClass');

const {me} = require('core/auth');

const CHAT_SIZE_LIMIT = 500; // no more than 500 messages

module.exports = (Bus = (Bus = (function() {
  Bus = class Bus extends CocoClass {
    static initClass() {
      this.prototype.joined = null;
      this.prototype.players = null;
      this.activeBuses = {};
      this.fireHost = 'https://codecombat.firebaseio.com';

      this.prototype.subscriptions =
        {'auth:me-synced': 'onMeSynced'};
    }

    static get(docName) { return this.getFromCache || new Bus(docName); }
    static getFromCache(docName) { return Bus.activeBuses[docName]; }

    constructor(docName) {
      super();
      this.onFireOpen = this.onFireOpen.bind(this);
      this.onChatAdded = this.onChatAdded.bind(this);
      this.onPlayerJoined = this.onPlayerJoined.bind(this);
      this.onPlayerLeft = this.onPlayerLeft.bind(this);
      this.onPlayerChanged = this.onPlayerChanged.bind(this);
      this.docName = docName;
      this.players = {};
      Bus.activeBuses[this.docName] = this;
    }

    connect() {
      // Put Firebase back in bower if you want to use this
      Backbone.Mediator.publish('bus:connecting', {bus: this});
      Firebase.goOnline();
      this.fireRef = new Firebase(Bus.fireHost + '/' + this.docName);
      return this.fireRef.once('value', this.onFireOpen);
    }

    onFireOpen(snapshot) {
      if (this.destroyed) {
        console.log(`Leaving '${this.docName}' because class has been destroyed.`);
        return;
      }
      this.init();
      return Backbone.Mediator.publish('bus:connected', {bus: this});
    }

    disconnect() {
      if (this.fireRef != null) {
        this.fireRef.off();
      }
      this.fireRef = null;
      if (this.fireChatRef != null) {
        this.fireChatRef.off();
      }
      this.fireChatRef = null;
      if (this.firePlayersRef != null) {
        this.firePlayersRef.off();
      }
      this.firePlayersRef = null;
      if (this.myConnection != null) {
        this.myConnection.off();
      }
      this.myConnection = null;
      this.joined = false;
      return Backbone.Mediator.publish('bus:disconnected', {bus: this});
    }

    init() {
      `\
Init happens when we're connected.\
`;
      this.fireChatRef = this.fireRef.child('chat');
      this.firePlayersRef = this.fireRef.child('players');
      this.join();
      this.listenForChanges();
      return this.sendMessage('/me joined.', true);
    }

    join() {
      this.joined = true;
      this.myConnection = this.firePlayersRef.child(me.id);
      this.myConnection.set({id: me.id, name: me.get('name'), connected: true});
      this.onDisconnect = this.myConnection.child('connected').onDisconnect();
      return this.onDisconnect.set(false);
    }

    listenForChanges() {
      this.fireChatRef.limit(CHAT_SIZE_LIMIT).on('child_added', this.onChatAdded);
      this.firePlayersRef.on('child_added', this.onPlayerJoined);
      this.firePlayersRef.on('child_removed', this.onPlayerLeft);
      return this.firePlayersRef.on('child_changed', this.onPlayerChanged);
    }

    onChatAdded(snapshot) {
      return Backbone.Mediator.publish('bus:new-message', {message: snapshot.val(), bus: this});
    }

    onPlayerJoined(snapshot) {
      const player = snapshot.val();
      if (!player.connected) { return; }
      this.players[player.id] = player;
      return Backbone.Mediator.publish('bus:player-joined', {player, bus: this});
    }

    onPlayerLeft(snapshot) {
      const val = snapshot.val();
      if (!val) { return; }
      const player = this.players[val.id];
      if (!player) { return; }
      delete this.players[player.id];
      return Backbone.Mediator.publish('bus:player-left', {player, bus: this});
    }

    onPlayerChanged(snapshot) {
      const player = snapshot.val();
      const wasConnected = this.players[player.id] != null ? this.players[player.id].connected : undefined;
      this.players[player.id] = player;
      if (wasConnected && !player.connected) { this.onPlayerLeft(snapshot); }
      if (player.connected && !wasConnected) { this.onPlayerJoined(snapshot); }
      return Backbone.Mediator.publish('bus:player-states-changed', {states: this.players, bus: this});
    }

    onMeSynced() {
      return (this.myConnection != null ? this.myConnection.child('name').set(me.get('name')) : undefined);
    }

    countPlayers() { return _.size(this.players); }

    onPoint() {
      // simple way to elect somone to do jobs that don't need to be done by each player
      const ids = _.keys(this.players);
      ids.sort();
      return ids[0] === me.id;
    }

    // MESSAGING

    sendSystemMessage(content) {
      return this.sendMessage(content, true);
    }

    sendMessage(content, system) {
      if (system == null) { system = false; }
      const MAX_MESSAGE_LENGTH = 400;
      const message = {
        content: content.slice(0,  MAX_MESSAGE_LENGTH),
        authorName: me.displayName(),
        authorID: me.id,
        dateMade: new Date()
      };
      if (system) { message.system = system; }
      return this.fireChatRef.push(message);
    }

    // TEARDOWN

    destroy() {
      if (this.joined) { this.sendMessage('/me left.', true); }
      if (this.docName in Bus.activeBuses) { delete Bus.activeBuses[this.docName]; }
      this.disconnect();
      return super.destroy();
    }
  };
  Bus.initClass();
  return Bus;
})()));

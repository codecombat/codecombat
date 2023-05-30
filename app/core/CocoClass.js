// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Template for classes with common functions, like hooking into the Mediator.
let CocoClass;
import utils from './../core/utils';
let classCount = 0;
const makeScopeName = () => `class-scope-${classCount++}`;
const doNothing = function() {};

export default CocoClass = (function() {
  CocoClass = class CocoClass {
    static initClass() {
      this.nicks = [];
      this.nicksUsed = {};
      this.remainingNicks = [];
  
      this.prototype.subscriptions = {};
      this.prototype.shortcuts = {};
    }
    static nextNick() {
      let nick;
      if (!this.nicks.length) { return (this.name || 'CocoClass') + ' ' + classCount; }
      this.remainingNicks = this.remainingNicks.length ? this.remainingNicks : this.nicks.slice();
      const baseNick = this.remainingNicks.splice(Math.floor(Math.random() * this.remainingNicks.length), 1)[0];
      let i = 0;
      while (true) {
        nick = i ? `${baseNick} ${i}` : baseNick;
        if (!this.nicksUsed[nick]) { break; }
        i++;
      }
      this.nicksUsed[nick] = true;
      return nick;
    }

    // setup/teardown

    constructor() {
      this.nick = this.constructor.nextNick();
      this.subscriptions = utils.combineAncestralObject(this, 'subscriptions');
      this.shortcuts = utils.combineAncestralObject(this, 'shortcuts');
      this.listenToSubscriptions();
      this.scope = makeScopeName();
      this.listenToShortcuts();
      if (typeof Backbone !== 'undefined' && Backbone !== null) { _.extend(this, Backbone.Events); }
    }

    destroy() {
      // teardown subscriptions, prevent new ones
      if (typeof this.stopListening === 'function') {
        this.stopListening();
      }
      if (typeof this.off === 'function') {
        this.off();
      }
      this.unsubscribeAll();
      this.stopListeningToShortcuts();
      this.constructor.nicksUsed[this.nick] = false;
      for (var key in this) { this[key] = undefined; }
      this.destroyed = true;
      this.off = doNothing;
      return this.destroy = doNothing;
    }

    // subscriptions

    listenToSubscriptions() {
      // for initting subscriptions
      if ((typeof Backbone !== 'undefined' && Backbone !== null ? Backbone.Mediator : undefined) == null) { return; }
      return (() => {
        const result = [];
        for (var channel in this.subscriptions) {
          var func = this.subscriptions[channel];
          func = utils.normalizeFunc(func, this);
          result.push(Backbone.Mediator.subscribe(channel, func, this));
        }
        return result;
      })();
    }

    addNewSubscription(channel, func) {
      // this is for adding subscriptions on the fly, rather than at init
      if ((typeof Backbone !== 'undefined' && Backbone !== null ? Backbone.Mediator : undefined) == null) { return; }
      if (this.destroyed) { return; }
      if (this.subscriptions[channel] !== undefined) { return; }
      func = utils.normalizeFunc(func, this);
      this.subscriptions[channel] = func;
      return Backbone.Mediator.subscribe(channel, func, this);
    }

    unsubscribeAll() {
      if ((typeof Backbone !== 'undefined' && Backbone !== null ? Backbone.Mediator : undefined) == null) { return; }
      return (() => {
        const result = [];
        for (var channel in this.subscriptions) {
          var func = this.subscriptions[channel];
          func = utils.normalizeFunc(func, this);
          result.push(Backbone.Mediator.unsubscribe(channel, func, this));
        }
        return result;
      })();
    }

    // keymaster shortcuts

    listenToShortcuts() {
      if (typeof key === 'undefined' || key === null) { return; }
      return (() => {
        const result = [];
        for (var shortcut in this.shortcuts) {
          var func = this.shortcuts[shortcut];
          func = utils.normalizeFunc(func, this);
          result.push(key(shortcut, this.scope, _.bind(func, this)));
        }
        return result;
      })();
    }

    stopListeningToShortcuts() {
      if (typeof key === 'undefined' || key === null) { return; }
      return key.deleteScope(this.scope);
    }

    playSound(trigger, volume) {
      if (volume == null) { volume = 1; }
      return Backbone.Mediator.publish('audio-player:play-sound', {trigger, volume});
    }

    wait(event) { return new Promise(resolve => this.once(event, resolve)); }
  };
  CocoClass.initClass();
  return CocoClass;
})();

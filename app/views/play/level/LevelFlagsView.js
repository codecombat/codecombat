/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelFlagsView;
require('app/styles/play/level/level-flags-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-flags-view');
const {me} = require('core/auth');

module.exports = (LevelFlagsView = (function() {
  LevelFlagsView = class LevelFlagsView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-flags-view';
      this.prototype.template = template;
      this.prototype.className = 'secret';
  
      this.prototype.subscriptions = {
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
        'surface:stage-mouse-down': 'onStageMouseDown',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'surface:remove-flag': 'onRemoveFlag'
      };
  
      this.prototype.events = {
        'click .green-flag'() { return this.onFlagSelected({color: 'green', source: 'button'}); },
        'click .black-flag'() { return this.onFlagSelected({color: 'black', source: 'button'}); },
        'click .violet-flag'() { return this.onFlagSelected({color: 'violet', source: 'button'}); }
      };
  
      this.prototype.shortcuts = {
        'g'() { return this.onFlagSelected({color: 'green', source: 'shortcut'}); },
        'b'() { return this.onFlagSelected({color: 'black', source: 'shortcut'}); },
        'v'() { return this.onFlagSelected({color: 'violet', source: 'shortcut'}); },
        'esc'() { return this.onFlagSelected({color: null, source: 'shortcut'}); },
        'delete, del, backspace': 'onDeletePressed'
      };
    }

    constructor(options) {
      super(options);
      this.levelID = options.levelID;
      this.world = options.world;
    }

    onRealTimePlaybackStarted(e) {
      this.realTime = true;
      this.$el.show();
      this.flags = {};
      return this.flagHistory = [];
    }

    onRealTimePlaybackEnded(e) {
      this.onFlagSelected({color: null});
      this.realTime = false;
      return this.$el.hide();
    }

    onFlagSelected(e) {
      if (!this.realTime) { return; }
      if (e.color) { this.playSound('menu-button-click'); }
      const color = e.color === this.flagColor ? null : e.color;
      this.flagColor = color;
      Backbone.Mediator.publish('level:flag-color-selected', {color});
      this.$el.find('.flag-button').removeClass('active');
      if (color) { return this.$el.find(`.${color}-flag`).addClass('active'); }
    }

    onStageMouseDown(e) {
      if (!this.flagColor || !this.realTime) { return; }
      this.playSound('menu-button-click');  // TODO: different flag placement sound?
      const pos = {x: e.worldPos.x, y: e.worldPos.y};
      const now = this.world.dt * this.world.frames.length;
      const flag = {player: me.id, team: me.team, color: this.flagColor, pos, time: now, active: true, source: 'click'};
      this.flags[this.flagColor] = flag;
      this.flagHistory.push(flag);
      if (this.realTimeFlags != null) {
        this.realTimeFlags.create(flag);
      }
      return Backbone.Mediator.publish('level:flag-updated', flag);
    }
      //console.log 'trying to place flag at', @world.age, 'and think it will happen by', flag.time

    onDeletePressed(e) {
      if (!this.realTime) { return; }
      return Backbone.Mediator.publish('surface:remove-selected-flag', {});
    }

    onRemoveFlag(e) {
      delete this.flags[e.color];
      const now = this.world.dt * this.world.frames.length;
      const flag = {player: me.id, team: me.team, color: e.color, time: now, active: false, source: 'click'};
      this.flagHistory.push(flag);
      return Backbone.Mediator.publish('level:flag-updated', flag);
    }
      //console.log e.color, 'deleted at time', flag.time

    onNewWorld(event) {
      if (event.world.name !== this.world.name) { return; }
      return this.world = (this.options.world = event.world);
    }
  };
  LevelFlagsView.initClass();
  return LevelFlagsView;
})());

/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelDialogueView;
require('app/styles/play/level/level-dialogue-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-dialogue-view');
const DialogueAnimator = require('./DialogueAnimator');
const PlayItemsModal = require('views/play/modal/PlayItemsModal');

module.exports = (LevelDialogueView = (function() {
  LevelDialogueView = class LevelDialogueView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-dialogue-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'sprite:speech-updated': 'onSpriteDialogue',
        'level:sprite-clear-dialogue': 'onSpriteClearDialogue',
        'level:shift-space-pressed': 'onShiftSpacePressed',
        'level:escape-pressed': 'onEscapePressed',
        'sprite:dialogue-sound-completed': 'onDialogueSoundCompleted',
        'level:open-items-modal': 'openItemsModal'
      };

      this.prototype.events = {
        'click': 'onClick',
        'click a': 'onClickLink'
      };
    }

    constructor(options) {
      super(options);
      this.addMoreMessage = this.addMoreMessage.bind(this);
      this.animateEnterButton = this.animateEnterButton.bind(this);
      this.level = options.level;
      this.sessionID = options.sessionID;
    }

    onClick(e) {
      return Backbone.Mediator.publish('tome:focus-editor', {});
    }

    onClickLink(e) {
      const route = $(e.target).attr('href');
      if (route && /item-store/.test(route)) {
        this.openModalView(new PlayItemsModal({supermodel: this.supermodal}));
        return e.stopPropagation();
      }
    }

    openItemsModal(e) {
      return this.openModalView(new PlayItemsModal({supermodel: this.supermodal}));
    }

    onSpriteDialogue(e) {
      if (!e.message) { return; }
      this.$el.addClass('active speaking');
      $('body').addClass('dialogue-view-active');
      return this.setMessage(e.message, e.mood, e.responses);
    }

    onDialogueSoundCompleted() {
      return this.$el.removeClass('speaking');
    }

    onSpriteClearDialogue() {
      this.$el.removeClass('active speaking');
      $('body').removeClass('dialogue-view-active');
      if (this.lastMood) { return this.$el.removeClass(this.lastMood); }
    }

    setMessage(message, mood, responses) {
      message = marked(message);
      // Fix old HTML icons like <i class='icon-play'></i> in the Markdown
      message = message.replace(/&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>");
      if (this.messageInterval) { clearInterval(this.messageInterval); }
      this.bubble = $('.dialogue-bubble', this.$el);
      if (this.lastMood) { this.$el.removeClass(this.lastMood); }
      this.$el.addClass(mood);
      this.lastMood = mood;
      this.bubble.text('');
      const group = $('<div class="enter secret" dir="ltr"></div>');
      this.bubble.append(group);
      if (responses) {
        this.lastResponses = responses;
        for (var response of Array.from(responses)) {
          var button = $('<button class="btn btn-small banner"></button>').text(response.text);
          if (response.buttonClass) { button.addClass(response.buttonClass); }
          group.append(button);
          response.button = $('button:last', group);
        }
      } else {
        const s = $.i18n.t('common.continue', {defaultValue: 'Continue'});
        const sk = $.i18n.t('play_level.skip_tutorial', {defaultValue: 'skip: esc'});
        if (!this.escapePressed && !this.isFullScreen()) {
          group.append('<span class="hud-hint">' + sk + '</span>');
        }
        group.append($('<button class="btn btn-small banner with-dot">' + s + ' <div class="dot"></div></button>'));
        this.lastResponses = null;
      }
      this.animator = new DialogueAnimator(message, this.bubble);
      return this.messageInterval = setInterval(this.addMoreMessage, 1000 / 30);  // 30 FPS
    }

    isFullScreen() {
      return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
    }

    addMoreMessage() {
      if (this.animator.done()) {
        clearInterval(this.messageInterval);
        this.messageInterval = null;
        $('.enter', this.bubble).removeClass('secret').css('opacity', 0.0).delay(500).animate({opacity: 1.0}, 500, this.animateEnterButton);
        if (this.lastResponses) {
          const buttons = $('.enter button');
          for (let i = 0; i < this.lastResponses.length; i++) {
            var response = this.lastResponses[i];
            var channel = response.channel.replace('level-set-playing', 'level:set-playing');  // Easier than migrating all those victory buttons.
            var f = r => () => setTimeout((() => Backbone.Mediator.publish(channel, r.event || {})), 10);
            $(buttons[i]).click(f(response));
          }
        } else {
          $('.enter', this.bubble).click(() => Backbone.Mediator.publish('script:end-current-script', {}));
        }
        return;
      }
      return this.animator.tick();
    }

    onShiftSpacePressed(e) {
      this.shiftSpacePressed = (this.shiftSpacePressed || 0) + 1;
      // We don't need to handle script:end-current-script--that's done--but if we do have
      // custom buttons, then we need to trigger the one that should fire (the last one).
      // If we decide that always having the last one fire is bad, we should make it smarter.
      if (!(this.lastResponses != null ? this.lastResponses.length : undefined)) { return; }
      const r = this.lastResponses[this.lastResponses.length - 1];
      const channel = r.channel.replace('level-set-playing', 'level:set-playing');
      return _.delay((() => Backbone.Mediator.publish(channel, r.event || {})), 10);
    }

    onEscapePressed(e) {
      return this.escapePressed = true;
    }

    animateEnterButton() {
      if (!this.bubble) { return; }
      const button = $('.enter', this.bubble);
      const dot = $('.dot', button);
      return dot.animate({opacity: 0.2}, 300).animate({opacity: 1.9}, 600, this.animateEnterButton);
    }

    destroy() {
      if (this.messageInterval) { clearInterval(this.messageInterval); }
      return super.destroy();
    }
  };
  LevelDialogueView.initClass();
  return LevelDialogueView;
})());

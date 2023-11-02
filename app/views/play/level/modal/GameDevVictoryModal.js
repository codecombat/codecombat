/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GameDevVictoryModal;
require('app/styles/play/level/modal/game-dev-victory-modal.sass');
const ModalView = require('views/core/ModalView');

const category = 'Play GameDev Level';

module.exports = (GameDevVictoryModal = (function() {
  GameDevVictoryModal = class GameDevVictoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'game-dev-victory-modal';
      this.prototype.template = require('app/templates/play/level/modal/game-dev-victory-modal');
  
      this.prototype.events = {
        'click #replay-game-btn': 'onClickReplayButton',
        'click #copy-url-btn': 'onClickCopyURLButton',
        'click #play-more-codecombat-btn': 'onClickPlayMoreCodeCombatButton'
      };
    }

    initialize({shareURL, eventProperties, victoryMessage}) {
      this.shareURL = shareURL;
      this.eventProperties = eventProperties;
      this.victoryMessage = victoryMessage;
    }

    getVictoryMessage() {
      return this.victoryMessage != null ? this.victoryMessage : "You beat the game!";
    }

    onClickReplayButton() {
      return this.trigger('replay');
    }

    onClickCopyURLButton() {
      this.$('#copy-url-input').val(this.shareURL).select();
      this.tryCopy();
      return (window.tracker != null ? window.tracker.trackEvent('Play GameDev Victory Modal - Copy URL', this.eventProperties) : undefined);
    }

    onClickPlayMoreCodeCombatButton() {
      return (window.tracker != null ? window.tracker.trackEvent('Play GameDev Victory Modal - Click Play More CodeCombat', this.eventProperties) : undefined);
    }
  };
  GameDevVictoryModal.initClass();
  return GameDevVictoryModal;
})());

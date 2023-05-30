/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LadderSubmissionView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/common/ladder_submission');
const {createAetherOptions} = require('lib/aether_utils');
const LevelSession = require('models/LevelSession');

module.exports = (LadderSubmissionView = (function() {
  LadderSubmissionView = class LadderSubmissionView extends CocoView {
    static initClass() {
      this.prototype.className = 'ladder-submission-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .rank-button': 'rankSession',
        'click .help-simulate': 'onHelpSimulate'
      };
    }

    constructor(options) {
      super(options);
      this.session = options.session;
      this.mirrorSession = options.mirrorSession;
      this.level = options.level;
    }

    getRenderData() {
      let submitDate;
      const ctx = super.getRenderData();
      ctx.readyToRank = this.session != null ? this.session.readyToRank() : undefined;
      ctx.isRanking = this.session != null ? this.session.get('isRanking') : undefined;
      ctx.simulateURL = `/play/ladder/${this.level.get('slug')}#simulate`;
      if (submitDate = this.session != null ? this.session.get('submitDate') : undefined) { ctx.lastSubmitted = moment(submitDate).fromNow(); }
      return ctx;
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.rankButton = this.$el.find('.rank-button');
      return this.updateButton();
    }

    updateButton() {
      let rankingState = 'unavailable';
      if (this.session != null ? this.session.readyToRank() : undefined) {
        rankingState = 'rank';
      } else if (this.session != null ? this.session.get('isRanking') : undefined) {
        rankingState = 'ranking';
      }
      return this.setRankingButtonText(rankingState);
    }

    setRankingButtonText(spanClass) {
      this.rankButton.find('span').hide();
      this.rankButton.find(`.${spanClass}`).show();
      this.rankButton.toggleClass('disabled', spanClass !== 'rank');
      const helpSimulate = ['submitted', 'ranking'].includes(spanClass);
      this.$el.find('.help-simulate').toggle(helpSimulate, 'slow');
      const showLastSubmitted = !(['submitting'].includes(spanClass));
      return this.$el.find('.last-submitted').toggle(showLastSubmitted);
    }

    showApologeticSignupModal() {
      const CreateAccountModal = require('views/core/CreateAccountModal');
      return this.openModalView(new CreateAccountModal({showRequiredError: true}));
    }

    rankSession(e) {
      if (!this.session.readyToRank()) { return; }
      if (me.get('anonymous')) { return this.showApologeticSignupModal(); }
      this.playSound('menu-button-click');
      this.setRankingButtonText('submitting');
      const success = () => {
        if (!this.destroyed) { this.setRankingButtonText('submitted'); }
        return Backbone.Mediator.publish('ladder:game-submitted', {session: this.session, level: this.level});
      };
      const failure = (jqxhr, textStatus, errorThrown) => {
        console.log(jqxhr.responseText);
        if (!this.destroyed) { return this.setRankingButtonText('failed'); }
      };
      return this.session.save(null, { success: () => {
        const ajaxData = {
          session: this.session.id,
          levelID: this.level.id,
          originalLevelID: this.level.get('original'),
          levelMajorVersion: this.level.get('version').major
        };
        const ajaxOptions = {
          type: 'POST',
          data: ajaxData,
          success,
          error: failure
        };
        if (this.mirrorSession) {
          // Also submit the mirrorSession after the main session submits successfully.
          let left;
          const mirrorAjaxData = _.clone(ajaxData);
          mirrorAjaxData.session = this.mirrorSession.id;
          const mirrorCode = (left = this.mirrorSession.get('code')) != null ? left : {};
          if (this.session.get('team') === 'humans') {
            mirrorCode['hero-placeholder-1'] = this.session.get('code')['hero-placeholder'];
          } else {
            mirrorCode['hero-placeholder'] = this.session.get('code')['hero-placeholder-1'];
          }
          const mirrorAjaxOptions = _.clone(ajaxOptions);
          mirrorAjaxOptions.data = mirrorAjaxData;
          ajaxOptions.success = () => {
            const patch = {code: mirrorCode, codeLanguage: this.session.get('codeLanguage')};
            const tempSession = new LevelSession({_id: this.mirrorSession.id});
            return tempSession.save(patch, { patch: true, type: 'PUT', success() {
              return $.ajax('/queue/scoring', mirrorAjaxOptions);
            }
          }
            );
          };
        }

        return $.ajax('/queue/scoring', ajaxOptions);
      }
    }
      );
    }

    onHelpSimulate() {
      this.playSound('menu-button-click');
      return $('a[href="#simulate"]').tab('show');
    }
  };
  LadderSubmissionView.initClass();
  return LadderSubmissionView;
})());

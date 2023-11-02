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
      window.nextURL = `/play/ladder/${this.level.get('slug')}?submit=true`;
      const CreateAccountModal = require('views/core/CreateAccountModal');
      return this.openModalView(new CreateAccountModal({accountRequiredMessage: $.i18n.t('signup.create_account_to_submit_multiplayer')}));  // Note: may destroy `this` if we were living in another modal
    }

    rankSession(e) {
      let code, currentAge;
      if (!this.session.readyToRank()) { return; }
      if (me.get('anonymous')) { return this.showApologeticSignupModal(); }
      this.playSound('menu-button-click');
      this.setRankingButtonText('submitting');
      if (currentAge = me.age()) {
        this.session.set('creatorAge', currentAge);
      }
      const success = () => {
        if (!this.destroyed) { this.setRankingButtonText('submitted'); }
        Backbone.Mediator.publish('ladder:game-submitted', {session: this.session, level: this.level});
        this.submittingInProgress = false;
        if (this.destroyed) {
          return this.session = (this.level = (this.mirrorSession = (this.submittingInProgress = undefined)));
        }
      };
      const failure = (jqxhr, textStatus, errorThrown) => {
        console.log(jqxhr.responseText);
        if (!this.destroyed) { this.setRankingButtonText('failed'); }
        this.submittingInProgress = false;
        if (this.destroyed) {
          return this.session = (this.level = (this.mirrorSession = (this.submittingInProgress = undefined)));
        }
      };
      this.submittingInProgress = true;
      const tempSession = this.session.clone(); // do not modify @session here
      if (this.level.isType('ladder') && (tempSession.get('team') === 'ogres')) {
        let left;
        code = (left = tempSession.get('code')) != null ? left : {'hero-placeholder': {plan:''}, 'hero-placeholder-1': {plan: ''}};
        tempSession.set('team', 'humans');
        code['hero-placeholder'] = _.clone(code['hero-placeholder-1']);
        tempSession.set('code', code);
      }
      return tempSession.save(null, { success: () => {
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
          let left1;
          const mirrorAjaxData = _.clone(ajaxData);
          mirrorAjaxData.session = this.mirrorSession.id;
          const mirrorCode = (left1 = this.mirrorSession.get('code')) != null ? left1 : {};
          if (tempSession.get('team') === 'humans') {
            mirrorCode['hero-placeholder-1'] = tempSession.get('code')['hero-placeholder'];
          } else {
            mirrorCode['hero-placeholder'] = tempSession.get('code')['hero-placeholder-1'];
          }
          const mirrorAjaxOptions = _.clone(ajaxOptions);
          mirrorAjaxOptions.data = mirrorAjaxData;
          ajaxOptions.success = () => {
            const patch = {code: mirrorCode, codeLanguage: tempSession.get('codeLanguage')};
            const tempMirrorSession = new LevelSession({_id: this.mirrorSession.id});
            return tempMirrorSession.save(patch, { patch: true, type: 'PUT', success() {
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

    destroy() {
      // Atypical: if we are destroyed mid-submission, keep a few locals around to be able to finish it
      let level, mirrorSession, session;
      if (this.submittingInProgress) {
        ({
          session
        } = this);
        ({
          level
        } = this);
        ({
          mirrorSession
        } = this);
      }
      super.destroy();
      if (session) {
        this.session = session;
        this.level = level;
        this.mirrorSession = this.mirrorSession;
        return this.submittingInProgress = true;
      }
    }
  };
  LadderSubmissionView.initClass();
  return LadderSubmissionView;
})());

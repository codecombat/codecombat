/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LeaderboardTabView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/modal/leaderboard-tab-view');
const CocoCollection = require('collections/CocoCollection');
const LevelSession = require('models/LevelSession');
const fetchJson = require('core/api/fetch-json');

class TopScoresCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = LevelSession;
  }

  constructor(level, scoreType, timespan) {
    super();
    this.level = level;
    this.scoreType = scoreType;
    this.timespan = timespan;
    this.url = `/db/level/${this.level.get('original')}/top_scores/${this.scoreType}/${this.timespan}`;
  }
}
TopScoresCollection.initClass();

module.exports = (LeaderboardTabView = (function() {
  LeaderboardTabView = class LeaderboardTabView extends CocoView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.className = 'leaderboard-tab-view';

      this.prototype.events = {
        'click tbody tr.viewable': 'onClickRow',
        'click tbody tr.viewable .nuke-button': 'onClickNukeButton'
      };
    }

    constructor(options) {
      super(options);
      this.level = this.options.level;
      this.scoreType = this.options.scoreType != null ? this.options.scoreType : 'time';
      this.timespan = this.options.timespan;
    }

    destroy() {
      return super.destroy();
    }

    getRenderData() {
      const c = super.getRenderData();
      c.scoreType = this.scoreType;
      c.timespan = this.timespan;
      c.topScores = this.formatTopScores();
      c.loading = !this.sessions || this.sessions.loading;
      c._ = _;
      return c;
    }

    afterRender() {
      super.afterRender();
      return this.$('[data-toggle="tooltip"]').tooltip({placement: 'bottom', html: true, animation: false, container: '.modal-content'});
    }

    formatTopScores() {
      if (!(this.sessions != null ? this.sessions.models : undefined)) { return []; }
      const rows = [];
      for (var s of Array.from(this.sessions.models)) {
        var row = {};
        var score = _.find(s.get('state').topScores, {type: this.scoreType});
        var scoreDate = new Date(score.date);
        if (((scoreDate - 1) > (new Date() - 1)) && !me.isAdmin()) {
          scoreDate = new Date(new Date() - (12 * 60 * 60 * 1000));  // Make up 12 hours ago time for bogus dates in the future
        }
        row.ago = moment(scoreDate).fromNow();
        row.score = this.formatScore(score);
        row.creatorName = s.get('creatorName');
        row.creator = s.get('creator');
        row.session = s.id;
        row.codeLanguage = s.get('codeLanguage');
        row.hero = __guard__(s.get('heroConfig'), x => x.thangType);
        row.inventory = __guard__(s.get('heroConfig'), x1 => x1.inventory);
        row.code = __guard__(__guard__(s.get('code'), x3 => x3['hero-placeholder']), x2 => x2.plan);
        rows.push(row);
      }
      return rows;
    }

    formatScore(score) {
      switch (score.type) {
        case 'time': return -score.score.toFixed(2) + 's';
        case 'damage-taken': return -Math.round(score.score);
        case 'damage-dealt': case 'gold-collected': case 'difficulty': return Math.round(score.score);
        default: return score.score;
      }
    }

    onShown() {
      if (this.hasShown) { return; }
      this.hasShown = true;
      const topScores = new TopScoresCollection(this.level, this.scoreType, this.timespan);
      return this.sessions = this.supermodel.loadCollection(topScores, 'sessions', {cache: false}, 0).model;
    }

    onClickRow(e) {
      const sessionID = $(e.target).closest('tr').data('session-id');
      const url = `/play/level/${this.level.get('slug')}?session=${sessionID}&observing=true`;
      return window.open(url, '_blank');
    }

    onClickNukeButton(e) {
      e.stopImmediatePropagation();
      const sessionID = $(e.target).closest('tr').data('session-id');
      this.playSound('menu-button-click');
      return fetchJson('/db/level.session/unset-scores', {method: 'POST', json: {session: sessionID}}).then(response => {
        return this.$(`tr[data-session-id=${sessionID}]`).tooltip('destroy').remove();
      });
    }
  };
  LeaderboardTabView.initClass();
  return LeaderboardTabView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
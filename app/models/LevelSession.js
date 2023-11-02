// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSession;
const CocoModel = require('./CocoModel');
const api = require('core/api');
const LevelConstants = require('lib/LevelConstants');
const {teamSpells, commentStarts} = require('core/utils');

module.exports = (LevelSession = (function() {
  LevelSession = class LevelSession extends CocoModel {
    static initClass() {
      this.className = 'LevelSession';
      this.schema = require('schemas/models/level_session');
      this.prototype.urlRoot = '/db/level.session';
  
      this.fakeID = 'ateacherfakesessionidval';
    }

    initialize() {
      super.initialize();
      return this.on('sync', e => {
        const state = this.get('state') || {};
        if (state.scripts == null) { state.scripts = {}; }
        return this.set('state', state);
      });
    }

    updatePermissions() {
      let permissions = this.get('permissions', true);
      permissions = (Array.from(permissions).filter((p) => p.target !== 'public'));
      return this.set('permissions', permissions);
    }

    getSourceFor(spellKey) {
      // spellKey ex: 'hero-placeholder/plan'
      const code = this.get('code');
      const parts = spellKey.split('/');
      return __guard__(code != null ? code[parts[0]] : undefined, x => x[parts[1]]);
    }

    readyToRank() {
      let c1, c2, team;
      if (!this.get('levelID')) { return false; }  // If it hasn't been denormalized, then it's not ready.
      if (!(c1 = this.get('code'))) { return false; }
      if (!(team = this.get('team'))) { return false; }
      if (!(c2 = this.get('submittedCode'))) { return true; }
      const thangSpellArr = (Array.from(teamSpells[team]).map((s) => s.split('/')));
      for (var item of Array.from(thangSpellArr)) {
        var thang = item[0];
        var spell = item[1];
        if (c1[thang][spell] !== (c2[thang] != null ? c2[thang][spell] : undefined)) { return true; }
      }
      return false;
    }

    isMultiplayer() {
      return (this.get('submittedCodeLanguage') != null) && (this.get('team') != null);
    }

    completed() {
      return __guard__(this.get('state'), x => x.complete) || false;
    }

    increaseDifficulty(callback) {
      let left;
      const state = (left = this.get('state')) != null ? left : {};
      state.difficulty = (state.difficulty != null ? state.difficulty : 0) + 1;
      delete state.lastUnsuccessfulSubmissionTime;
      this.set('state', state);
      this.trigger('change-difficulty');
      return this.save(null, {success: callback});
    }

    timeUntilResubmit() {
      let last, left;
      const state = (left = this.get('state')) != null ? left : {};
      if (!(last = state.lastUnsuccessfulSubmissionTime)) { return 0; }
      if (_.isString(last)) { last = new Date(last); }
      // Wait at least this long before allowing submit button active again.
      let wait = (last - new Date()) + (22 * 60 * 60 * 1000);
      if (wait > (24 * 60 * 60 * 1000)) {
        // System clock must've gotten busted; max out at one day's wait.
        wait = 24 * 60 * 60 * 1000;
        state.lastUnsuccessfulSubmissionTime = new Date();
        this.set('state', state);
      }
      return wait;
    }

    recordScores(scores, level) {
      let left;
      if (!scores) { return; }
      const state = this.get('state');
      const oldTopScores = state.topScores != null ? state.topScores : [];
      const newTopScores = [];
      const now = new Date();
      for (var scoreType of Array.from((left = level.get('scoreTypes')) != null ? left : [])) {
        if (scoreType.type) { scoreType = scoreType.type; }
        var oldTopScore = _.find(oldTopScores, {type: scoreType});
        var newScore = scores[scoreType];
        if (newScore == null) {
          if (oldTopScore) { newTopScores.push(oldTopScore); }
          continue;
        }
        if (Array.from(LevelConstants.lowerIsBetterScoreTypes).includes(scoreType)) { newScore *= -1; }  // Index relies on "top" scores being higher numbers
        if ((oldTopScore == null) || (newScore > oldTopScore.score)) {
          newTopScores.push({type: scoreType, date: now, score: newScore});
        } else {
          newTopScores.push(oldTopScore);
        }
      }
      state.topScores = newTopScores;
      this.set('state', state);
      scores = LevelSession.getTopScores({level: level.toJSON(), session: this.toJSON()});
      return Backbone.Mediator.publish('level:top-scores-updated', {scores});
    }

    static getTopScores({level, session}) {
      let score;
      const Level = require('models/Level');
      const scores = ((() => {
        const result = [];
        for (score of Array.from((session.state != null ? session.state.topScores : undefined) != null ? (session.state != null ? session.state.topScores : undefined) : [])) {           result.push(_.clone(score));
        }
        return result;
      })());
      for (score of Array.from(scores)) { if (Array.from(LevelConstants.lowerIsBetterScoreTypes).includes(score.type)) { score.score *= -1; } }  // Undo negative storage for display
      if (level) {
        for (var sessionScore of Array.from(scores)) {
          var thresholdAchieved = Level.thresholdForScore(_.assign(_.pick(sessionScore, 'score', 'type'), {level}));
          if (thresholdAchieved) {
            sessionScore.thresholdAchieved = thresholdAchieved;
          }
        }
      }
      return scores;  // 24 characters like other IDs for schema validation
    }
    isFake() { return this.id === LevelSession.fakeID; }

    inLeague(leagueId) {
      if (!this.get('leagues')) { return false; }
      for (var league of Array.from(this.get('leagues'))) {
        if (league.leagueID === leagueId) { return true; }
      }
      return false;
    }

    updateKeyValueDb(keyValueDb) {
      let left;
      const oldDb = (left = this.get('keyValueDb')) != null ? left : {};
      if (this.originalKeyValueDb == null) { this.originalKeyValueDb = oldDb; }
      if (_.size(keyValueDb)) { return this.set('keyValueDb', keyValueDb); }
    }

    saveKeyValueDb() {
      let left;
      const keyValueDb = (left = this.get('keyValueDb')) != null ? left : {};
      if (!this.originalKeyValueDb) { return; }
      if (this.isFake()) { return; }
      for (var key in keyValueDb) {
        var value = keyValueDb[key];
        var oldValue = this.originalKeyValueDb[key];
        if (value === oldValue) { continue; }
        if ((oldValue == null) || (typeof(oldValue) === 'string') || (typeof(value) === 'string')) {
          api.levelSessions.setKeyValue({ sessionID: this.id, key, value});
        } else if ((typeof(oldValue) === 'number') && (typeof(value) === 'number')) {
          var increment = value - oldValue;
          api.levelSessions.incrementKeyValue({ sessionID: this.id, key, value: increment});
        }
      }

      if (_.size(keyValueDb)) { this.set('keyValueDb', keyValueDb); }
      return delete this.originalKeyValueDb;
    }

    countOriginalLinesOfCode(level) {
      // Count non-whitespace, non-comment lines starting at first unique code line
      // TODO: diff better to find truly changed lines
      let left, left1, left2, left3;
      const sampleCodeByLanguage = level.getSampleCode(this.get('team'));
      let sampleCode = (left = (left1 = (left2 = sampleCodeByLanguage[this.get('codeLanguage')]) != null ? left2 : sampleCodeByLanguage.html) != null ? left1 : sampleCodeByLanguage.python) != null ? left : '';
      sampleCode = sampleCode.replace(this.singleLineCommentOnlyRegex(), '');
      let sampleCodeLines = sampleCode.split(/\n+/);
      sampleCodeLines = _.filter(sampleCodeLines);

      const thang = this.get('team') === 'ogres' ? 'hero-placeholder-1' : 'hero-placeholder';
      let code = (left3 = this.getSourceFor(`${thang}/plan`)) != null ? left3 : '';
      code = code.replace(this.singleLineCommentOnlyRegex(), '');
      let codeLines = code.split(/\n+/);
      codeLines = _.filter(codeLines);

      let i = 0;
      while ((i < codeLines.length) && (i < sampleCodeLines.length)) {
        if (codeLines[i] !== sampleCodeLines[i]) { break; }
        ++i;
      }
      const count = codeLines.length - i;
      //console.log "Got", count, "original lines from\n", code, "\n-----------\n", sampleCode
      return Math.min(count, 1000);
    }

    singleLineCommentOnlyRegex() {
      let commentStart;
      if (this.get('codeLanguage') === 'html') {
        commentStart = `${commentStarts.html}|${commentStarts.css}|${commentStarts.javascript}`;
      } else {
        commentStart = commentStarts[this.get('codeLanguage')] || '#';
      }
      return new RegExp(`^[ \t]*(${commentStart}).*$`, 'gm');
    }
  };
  LevelSession.initClass();
  return LevelSession;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
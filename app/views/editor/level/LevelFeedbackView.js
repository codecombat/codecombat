// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelFeedbackView;
require('app/styles/editor/level/level-feedback-view.sass');
const CocoView = require('views/core/CocoView');
const CocoCollection = require('collections/CocoCollection');
const template = require('app/templates/editor/level/level-feedback-view');
const Level = require('models/Level');
const LevelFeedback = require('models/LevelFeedback');

class LevelFeedbackCollection extends CocoCollection {
  static initClass() {
    this.prototype.model = LevelFeedback;
  }
  initialize(models, options) {
    super.initialize(models, options);
    return this.url = `/db/level/${options.level.get('slug')}/all_feedback`;
  }

  comparator(a, b) {
    let score = 0;
    if (a.get('creator') === me.id) { score -= 9001900190019001; }
    if (b.get('creator') === me.id) { score += 9001900190019001; }
    score -= new Date(a.get('created'));
    score -= -(new Date(b.get('created')));
    if (a.get('review')) { score -= 900190019001; }
    if (b.get('review')) { score += 900190019001; }
    if (score < 0) { return -1; } else { if (score > 0) { return 1; } else { return 0; } }
  }
}
LevelFeedbackCollection.initClass();

module.exports = (LevelFeedbackView = (function() {
  LevelFeedbackView = class LevelFeedbackView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-feedback-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';
  
      this.prototype.subscriptions =
        {'editor:view-switched': 'onViewSwitched'};
    }

    constructor(options) {
      super(options);
    }

    getRenderData(context) {
      let m;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.moment = moment;
      context.allFeedback = [];
      context.averageRating = 0;
      context.totalRatings = 0;
      if (this.allFeedback != null ? this.allFeedback.models.length : undefined) {
        context.allFeedback = ((() => {
          const result = [];
          for (m of Array.from(this.allFeedback.models)) {             if ((this.allFeedback.models.length < 20) || m.get('review')) {
              result.push(m.attributes);
            }
          }
          return result;
        })());
        context.averageRating = _.reduce(((() => {
          const result1 = [];
          for (m of Array.from(this.allFeedback.models)) {             result1.push(m.get('rating'));
          }
          return result1;
        })()), (acc, x) => acc + (x != null ? x : 5)) / (this.allFeedback.models.length);
        context.totalRatings = this.allFeedback.models.length;
      } else {
        context.loading = true;
      }
      return context;
    }

    onViewSwitched(e) {
      // Lazily load.
      if (e.targetURL !== '#level-feedback-view') { return; }
      if (!this.allFeedback) {
        this.allFeedback = this.supermodel.loadCollection(new LevelFeedbackCollection(null, {level: this.options.level}), 'feedback').model;
        return this.render();
      }
    }
  };
  LevelFeedbackView.initClass();
  return LevelFeedbackView;
})());

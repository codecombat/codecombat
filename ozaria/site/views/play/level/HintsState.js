/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HintsState;
const Article = require('models/Article');

module.exports = (HintsState = class HintsState extends Backbone.Model {

  initialize(attributes, options) {
    ({ level: this.level, session: this.session, supermodel: this.supermodel } = options);
    this.listenTo(this.level, 'change:documentation', this.update);
    this.update();
  }

  getHint(index) {
    return __guard__(this.get('hints'), x => x[index]);
  }

  update() {
    let left;
    let doc;
    const articles = this.supermodel.getModels(Article);
    const docs = (left = this.level.get('documentation')) != null ? left : {};
    const general = _.filter(((() => {
      const result = [];
      for (doc of Array.from(docs.generalArticles || [])) {         result.push(__guard__(_.find(articles, article => article.get('original') === doc.original), x => x.attributes));
      }
      return result;
    })()));
    const specific = docs.specificArticles || [];
    let hints = (docs.hintsB || docs.hints || []).concat(specific).concat(general);
    hints = _.sortBy(hints, function(doc) {
      if (doc.name === 'Intro') { return -1; }
      return 0;
    });

    const total = _.size(hints);
    return this.set({
      hints,
      total
    });
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
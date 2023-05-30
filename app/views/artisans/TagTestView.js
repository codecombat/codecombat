// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTasksView;
require('app/styles/artisans/tag-test-view.sass');
const RootView = require('views/core/RootView');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/artisans/tag-test-view');
const tagger = require('lib/SolutionConceptTagger');
const conceptList =require('schemas/concepts');

const ThangType = require('models/ThangType');

const ThangTypes = require('collections/ThangTypes');
const ace = require('lib/aceContainer');

class ActualTagView extends CocoView {
  static initClass() {
    this.prototype.template = require('app/templates/artisans/tag-test-tags-view');
    this.prototype.id = 'tag-test-tags-view';
  }
}
ActualTagView.initClass();

module.exports = (ThangTasksView = (function() {
  ThangTasksView = class ThangTasksView extends RootView {
    constructor(...args) {
      this.updateTags = this.updateTags.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'tag-test-view';
      this.prototype.events = {
        'input input': 'processThangs',
        'change input': 'processThangs'
      };
    }

    initialize() {
      this.tags = [];
      console.log("Hello");
      return this.debouncedUpdateTags = _.debounce(this.updateTags, 1000);
    }

    afterRender() {
      this.insertSubView(this.tagView = new ActualTagView());
      const ta = this.$el.find('#tag-test-editor');
      this.editor = ace.edit(ta[0]);
      this.editor.resize();
      this.editor.getSession().setMode("ace/mode/javascript");
      this.editor.getSession().on('change', () => {
        this.tagView.tags = [];
        this.tagView.error = undefined;
        this.tagView.render();
        return this.debouncedUpdateTags();
      });

      this.editor.setValue(localStorage.code||'');
      this.editor.focus();
      return this.updateTags();
    }

    updateTags() {
      const code = this.editor.getValue();
      this.tagView.tags = [];
      this.tagView.error = undefined;
      localStorage.code = code;
      try {
        this.tagView.tags = _.map(tagger({source: code}), t => __guard__(_.find(conceptList, e => e.concept === t), x => x.name));
      } catch (error) {
        const e = error;
        this.tagView.error = e.stack;
      }

      this.tagView.render();
      return console.log("Update tags");
    }
  };
  ThangTasksView.initClass();
  return ThangTasksView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
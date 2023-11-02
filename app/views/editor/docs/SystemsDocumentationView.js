/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SystemsDocumentationView;
require('app/styles/docs/systems-documentation-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/docs/systems-documentation-view');
const CocoCollection = require('collections/CocoCollection');
const LevelSystem = require('models/LevelSystem');

class SystemDocsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '/db/level.system?project=name,description,code';
    this.prototype.model = LevelSystem;
    this.prototype.comparator = 'name';
  }
}
SystemDocsCollection.initClass();

module.exports = (SystemsDocumentationView = (function() {
  SystemsDocumentationView = class SystemsDocumentationView extends CocoView {
    static initClass() {
      this.prototype.id = 'systems-documentation-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';
      this.prototype.collapsed = true;
  
      this.prototype.events =
        {'click #toggle-all-system-code': 'onToggleAllCode'};
  
      this.prototype.subscriptions =
        {'editor:view-switched': 'onViewSwitched'};
    }

    constructor(options) {
      super(options);
      this.systemDocs = new SystemDocsCollection();
      if (!options.lazy) { this.loadDocs(); }
    }

    loadDocs() {
      if (this.loadingDocs) { return; }
      this.supermodel.loadCollection(this.systemDocs, 'systems');
      this.loadingDocs = true;
      return this.render();
    }

    getRenderData() {
      let left;
      const c = super.getRenderData();
      c.systems = this.systemDocs.models;
      c.marked = marked;
      c.codeLanguage = (left = __guard__(me.get('aceConfig'), x => x.language)) != null ? left : 'python';
      return c;
    }

    onToggleAllCode(e) {
      this.collapsed = !this.collapsed;
      this.$el.find('.collapse').collapse(this.collapsed ? 'hide' : 'show');
      return this.$el.find('#toggle-all-system-code').toggleClass('active', !this.collapsed);
    }

    onViewSwitched(e) {
      if (e.targetURL !== '#editor-level-documentation') { return; }
      return this.loadDocs();
    }
  };
  SystemsDocumentationView.initClass();
  return SystemsDocumentationView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
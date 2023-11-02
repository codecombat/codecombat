/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ComponentsDocumentationView;
require('app/styles/docs/components-documentation-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/docs/components-documentation-view');
const CocoCollection = require('collections/CocoCollection');
const LevelComponent = require('models/LevelComponent');
const utils = require('core/utils');

class ComponentDocsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '/db/level.component?project=system,name,description,dependencies,propertyDocumentation,code';
    this.prototype.model = LevelComponent;
    this.prototype.comparator = 'system';
  }
}
ComponentDocsCollection.initClass();

module.exports = (ComponentsDocumentationView = (function() {
  ComponentsDocumentationView = class ComponentsDocumentationView extends CocoView {
    static initClass() {
      this.prototype.id = 'components-documentation-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';
      this.prototype.collapsed = true;
  
      this.prototype.events =
        {'click #toggle-all-component-code': 'onToggleAllCode'};
  
      this.prototype.subscriptions =
        {'editor:view-switched': 'onViewSwitched'};
    }

    constructor(options) {
      super(options);
      this.componentDocs = new ComponentDocsCollection();
      if (utils.isOzaria) {
        this.componentDocs.url += '&archived=false';
      }
      if (!options.lazy) { this.loadDocs(); }
    }

    loadDocs() {
      if (this.loadingDocs) { return; }
      this.supermodel.loadCollection(this.componentDocs, 'components');
      this.loadingDocs = true;
      return this.render();
    }

    getRenderData() {
      let left;
      const c = super.getRenderData();
      c.components = this.componentDocs.models;
      c.marked = marked;
      c.codeLanguage = (left = __guard__(me.get('aceConfig'), x => x.language)) != null ? left : 'python';
      return c;
    }

    onToggleAllCode(e) {
      this.collapsed = !this.collapsed;
      this.$el.find('.collapse').collapse(this.collapsed ? 'hide' : 'show');
      return this.$el.find('#toggle-all-component-code').toggleClass('active', !this.collapsed);
    }

    onViewSwitched(e) {
      if (e.targetURL !== '#editor-level-documentation') { return; }
      return this.loadDocs();
    }
  };
  ComponentsDocumentationView.initClass();
  return ComponentsDocumentationView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
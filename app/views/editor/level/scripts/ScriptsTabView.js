// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ScriptsTabView;
require('app/styles/editor/level/scripts_tab.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/scripts_tab');
const Level = require('models/Level');
const Surface = require('lib/surface/Surface');
const nodes = require('./../treema_nodes');
const defaultScripts = require('lib/DefaultScripts');
const utils = require('core/utils');
require('lib/setupTreema');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');

module.exports = (ScriptsTabView = (function() {
  ScriptsTabView = class ScriptsTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'editor-level-scripts-tab-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';

      this.prototype.subscriptions = {
        'editor:level-loaded': 'onLevelLoaded',
        'editor:thangs-edited': 'onThangsEdited'
      };
    }

    constructor(options) {
      super(options);
      this.onScriptsChanged = this.onScriptsChanged.bind(this);
      this.onScriptSelected = this.onScriptSelected.bind(this);
      this.onNewScriptAdded = this.onNewScriptAdded.bind(this);
      this.onScriptDeleted = this.onScriptDeleted.bind(this);
      this.onScriptChanged = this.onScriptChanged.bind(this);
      this.onWindowResize = this.onWindowResize.bind(this);
      this.world = options.world;
      this.files = options.files;
      $(window).on('resize', this.onWindowResize);
    }

    destroy() {
      if (this.scriptTreema != null) {
        this.scriptTreema.destroy();
      }
      if (this.scriptTreemas != null) {
        this.scriptTreemas.destroy();
      }
      $(window).off('resize', this.onWindowResize);
      return super.destroy();
    }

    onLoaded() {}
    onLevelLoaded(e) {
      let left;
      this.level = e.level;
      this.dimensions = this.level.dimensions();
      let scripts = $.extend(true, [], (left = this.level.get('scripts')) != null ? left : []);
      if (scripts.length === 0) {
        scripts = $.extend(true, [], defaultScripts);
      }
      const treemaOptions = {
        schema: Level.schema.properties.scripts,
        data: scripts,
        callbacks: {
          change: this.onScriptsChanged,
          select: this.onScriptSelected,
          addChild: this.onNewScriptAdded,
          removeChild: this.onScriptDeleted
        },
        nodeClasses: {
          array: ScriptsNode,
          object: ScriptNode
        },
        view: this
      };
      this.scriptsTreema = this.$el.find('#scripts-treema').treema(treemaOptions);
      this.scriptsTreema.build();
      if (this.scriptsTreema.childrenTreemas[0] != null) {
        this.scriptsTreema.childrenTreemas[0].select();
        return this.scriptsTreema.childrenTreemas[0].broadcastChanges(); // can get rid of this after refactoring treema
      }
    }

    onScriptsChanged(e) {
      return this.level.set('scripts', this.scriptsTreema.data);
    }

    onScriptSelected(e, selected) {
      selected = selected.length > 1 ? selected[0].getLastSelectedTreema() : selected[0];
      if (!selected) {
        this.$el.find('#script-treema').replaceWith($('<div id="script-treema"></div>'));
        this.selectedScriptPath = null;
        return;
      }

      this.thangIDs = this.getThangIDs();
      const treemaOptions = {
        world: this.world,
        filePath: `db/level/${this.level.get('original')}`,
        files: this.files,
        view: this,
        schema: Level.schema.properties.scripts.items,
        data: selected.data,
        thangIDs: this.thangIDs,
        dimensions: this.dimensions,
        supermodel: this.supermodel,
        readOnly: me.get('anonymous'),
        callbacks: {
          change: this.onScriptChanged
        },
        nodeClasses: {
          object: PropertiesNode,
          'event-value-chain': EventPropsNode,
          'event-prereqs': EventPrereqsNode,
          'event-prereq': EventPrereqNode,
          'event-channel': ChannelNode,
          'thang': nodes.ThangNode,
          'milliseconds': nodes.MillisecondsNode,
          'seconds': nodes.SecondsNode,
          'point2d': nodes.WorldPointNode,
          'viewport': nodes.WorldViewportNode,
          'bounds': nodes.WorldBoundsNode
        }
      };

      const newPath = selected.getPath();
      if (newPath === this.selectedScriptPath) { return; }
      //@scriptTreema?.destroy() # TODO: get this to work
      this.scriptTreema = this.$el.find('#script-treema').treema(treemaOptions);
      this.scriptTreema.build();
      __guard__(this.scriptTreema.childrenTreemas != null ? this.scriptTreema.childrenTreemas.noteChain : undefined, x => x.open(5));
      return this.selectedScriptPath = newPath;
    }

    getThangIDs() {
      let left;
      return (Array.from((left = this.level.get('thangs')) != null ? left : []).map((t) => t.id));
    }

    onNewScriptAdded(scriptNode) {
      if (!scriptNode) { return; }
      if (scriptNode.data.id === undefined) {
        scriptNode.disableTracking();
        scriptNode.set('/id', 'Script-' + this.scriptsTreema.data.length);
        return scriptNode.enableTracking();
      }
    }

    onScriptDeleted() {
      return (() => {
        const result = [];
        for (var key in this.scriptsTreema.childrenTreemas) {
          var treema = this.scriptsTreema.childrenTreemas[key];
          key = parseInt(key);
          treema.disableTracking();
          if (/Script-[0-9]*/.test(treema.data.id)) {
            var existingKey = parseInt(treema.data.id.substr(7));
            if (existingKey !== (key+1)) {
              treema.set('id', 'Script-' + (key+1));
            }
          }
          result.push(treema.enableTracking());
        }
        return result;
      })();
    }

    onScriptChanged() {
      if (!this.selectedScriptPath) { return; }
      return this.scriptsTreema.set(this.selectedScriptPath, this.scriptTreema.data);
    }

    onThangsEdited(e) {
      // Update in-place so existing Treema nodes refer to the same array.
      return (this.thangIDs != null ? this.thangIDs.splice(0, this.thangIDs.length, ...Array.from(this.getThangIDs())) : undefined);
    }

    onWindowResize(e) {
      if ($('body').width() > 800) { return this.$el.find('#scripts-treema').collapse('show'); }
    }
  };
  ScriptsTabView.initClass();
  return ScriptsTabView;
})());

class ScriptsNode extends TreemaArrayNode {
  static initClass() {
    this.prototype.nodeDescription = 'Script';
  }
  addNewChild() {
    const newTreema = super.addNewChild();
    if (this.callbacks.addChild) {
      this.callbacks.addChild(newTreema);
    }
    return newTreema;
  }
}
ScriptsNode.initClass();

class ScriptNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-script';
    this.prototype.collection = false;
  }
  buildValueForDisplay(valEl, data) {
    const val = data.id || data.channel;
    const s = `${val}`;
    return this.buildValueForDisplaySimply(valEl, s);
  }

  onTabPressed(e) {
    this.tabToCurrentScript();
    return e.preventDefault();
  }

  onDeletePressed(e) {
    const returnVal = super.onDeletePressed(e);
    if (this.callbacks.removeChild) {
      this.callbacks.removeChild();
    }
    return returnVal;
  }

  onRightArrowPressed() {
    return this.tabToCurrentScript();
  }

  tabToCurrentScript() {
    if (this.settings.view.scriptTreema != null) {
      this.settings.view.scriptTreema.keepFocus();
    }
    const firstRow = this.settings.view.scriptTreema != null ? this.settings.view.scriptTreema.$el.find('.treema-node:visible').data('instance') : undefined;
    if (firstRow == null) { return; }
    return firstRow.select();
  }
}
ScriptNode.initClass();

class PropertiesNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.nodeDescription = 'Script Property';
  }
}
PropertiesNode.initClass();

class EventPropsNode extends TreemaNode.nodeMap.string {
  static initClass() {
    this.prototype.valueClass = 'treema-event-props';
  }

  arrayToString() { return (this.getData() || []).join('.'); }

  buildValueForDisplay(valEl, data) {
    let joined = this.arrayToString();
    if (!joined.length) { joined = '(unset)'; }
    return this.buildValueForDisplaySimply(valEl, joined);
  }

  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, (data || []).join('.'));
    const {
      channel
    } = this.getRoot().data;
    const channelSchema = Backbone.Mediator.channelSchemas[channel];
    // The note system adds a 'codeLanguage' property to any events
    // triggered by the level. This provides an additional way to filter
    // scripts. This property is not part of the events schema as events
    // only gain this property through the script/note system.
    const autocompleteValues = ['codeLanguage'];
    for (var key in (channelSchema != null ? channelSchema.properties : undefined)) { var val = (channelSchema != null ? channelSchema.properties : undefined)[key]; autocompleteValues.push(key); }
    valEl.find('input').autocomplete({source: autocompleteValues, minLength: 0, delay: 0, autoFocus: true}).autocomplete('search');
    return valEl;
  }

  saveChanges(valEl) {
    return this.data = (Array.from($('input', valEl).val().split('.')).filter((s) => s.length));
  }
}
EventPropsNode.initClass();

class EventPrereqsNode extends TreemaNode.nodeMap.array {
  open(depth) {
    if (depth == null) { depth = 2; }
    return super.open(depth);
  }

  addNewChild() {
    const newTreema = super.addNewChild(arguments);
    if (newTreema == null) { return; }
    newTreema.open();
    return (newTreema.childrenTreemas.eventProps != null ? newTreema.childrenTreemas.eventProps.edit() : undefined);
  }
}

class EventPrereqNode extends TreemaNode.nodeMap.object {
  buildValueForDisplay(valEl, data) {
    let eventProp = (data.eventProps || []).join('.');
    if (!eventProp.length) { eventProp = '(unset)'; }
    let statements = [];
    for (var key in data) {
      var value = data[key];
      if (key === 'eventProps') { continue; }
      var comparison = this.workingSchema.properties[key].title;
      value = value.toString();
      statements.push(`${comparison} ${value}`);
    }
    statements = statements.join(', ');
    const s = `${eventProp} ${statements}`;
    return this.buildValueForDisplaySimply(valEl, s);
  }
}

class ChannelNode extends TreemaNode.nodeMap.string {
  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, data);
    const autocompleteValues = ((() => {
      const result = [];
      for (var key in Backbone.Mediator.channelSchemas) {
        var val = Backbone.Mediator.channelSchemas[key];
        result.push({label: (val != null ? val.title : undefined) || key, value: key});
      }
      return result;
    })());
    valEl.find('input').autocomplete({source: autocompleteValues, minLength: 0, delay: 0, autoFocus: true});
    return valEl;
  }
}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AccelerationNode, AIDocumentLinkNode, ChatMessageLinkNode, ChatMessageParentLinkNode, ItemThangTypeNode, KilogramsNode, MetersNode, MillisecondsNode, RadiansNode, SateNode, SecondsNode, SpeedNode, StateNode, SuperteamNode, TeamNode, ThangNode, ThangTypeNode, WorldBoundsNode, WorldPointNode, WorldViewportNode;
const WorldSelectModal = require('./modals/WorldSelectModal');
const ThangType = require('models/ThangType');
const AIChatMessage = require('models/AIChatMessage');
const AIScenario = require('models/AIScenario');
const AIProject = require('models/AIProject');
const LevelComponent = require('models/LevelComponent');
const CocoCollection = require('collections/CocoCollection');
const entities = require('entities');
require('lib/setupTreema');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');
const utils = require('core/utils');

const makeButton = () => $('<a class="btn btn-primary btn-xs treema-map-button"><span class="glyphicon glyphicon-screenshot"></span></a>');
const shorten = f => parseFloat(f.toFixed(1));
const WIDTH = 924;

module.exports.WorldPointNode = (WorldPointNode = class WorldPointNode extends TreemaNode.nodeMap.point2d {
  constructor(...args) {
    super(...Array.from(args || []));
    this.callback = this.callback.bind(this);
    if (this.settings.world == null) { console.error('Point Treema node needs a World included in the settings.'); }
    if (this.settings.view == null) { console.error('Point Treema node needs a RootView included in the settings.'); }
  }

  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  onClick(e) {
    const btn = $(e.target).closest('.treema-map-button');
    if (btn.length) { return this.openMap(); } else { return super.onClick(...arguments); }
  }

  openMap() {
    const modal = new WorldSelectModal({world: this.settings.world, dataType: 'point', default: this.getData(), supermodel: this.settings.supermodel});
    modal.callback = this.callback;
    return this.settings.view.openModalView(modal);
  }

  callback(e) {
    if ((e != null ? e.point : undefined) == null) { return; }
    this.data.x = shorten(e.point.x);
    this.data.y = shorten(e.point.y);
    return this.refreshDisplay();
  }
});

class WorldRegionNode extends TreemaNode.nodeMap.object {
  // this class is not yet used, later will be used to configure the Physical component

  constructor(...args) {
    this.callback = this.callback.bind(this);
    super(...Array.from(args || []));
    if (this.settings.world == null) { console.error('Region Treema node needs a World included in the settings.'); }
    if (this.settings.view == null) { console.error('Region Treema node needs a RootView included in the settings.'); }
  }

  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  onClick(e) {
    const btn = $(e.target).closest('.treema-map-button');
    if (btn.length) { return this.openMap(); } else { return super.onClick(...arguments); }
  }

  openMap() {
    const modal = new WorldSelectModal({world: this.settings.world, dataType: 'region', default: this.createWorldBounds(), supermodel: this.settings.supermodel});
    modal.callback = this.callback;
    return this.settings.view.openModalView(modal);
  }

  callback(e) {
    const x = Math.min(e.points[0].x, e.points[1].x);
    const y = Math.min(e.points[0].y, e.points[1].y);
    this.data.pos = {x, y, z: 0};
    this.data.width = Math.abs(e.points[0].x - e.points[1].x);
    this.data.height = Math.min(e.points[0].y - e.points[1].y);
    return this.refreshDisplay();
  }

  createWorldBounds() {}
}
    // not yet written

module.exports.WorldViewportNode = (WorldViewportNode = class WorldViewportNode extends TreemaNode.nodeMap.object {
  // selecting ratio'd dimensions in the world, ie the camera in level scripts
  constructor(...args) {
    this.callback = this.callback.bind(this);
    super(...Array.from(args || []));
    if (this.settings.world == null) { console.error('Viewport Treema node needs a World included in the settings.'); }
    if (this.settings.view == null) { console.error('Viewport Treema node needs a RootView included in the settings.'); }
  }

  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, data);
    return valEl.find('.treema-shortened').prepend(makeButton());
  }

  onClick(e) {
    const btn = $(e.target).closest('.treema-map-button');
    if (btn.length) { return this.openMap(); } else { return super.onClick(...arguments); }
  }

  openMap() {
    // can't really get the bounds from this data, so will have to hack this solution
    const options = {world: this.settings.world, dataType: 'ratio-region'};
    const data = this.getData();
    if (__guard__(data != null ? data.target : undefined, x => x.x) != null) { options.defaultFromZoom = data; }
    options.supermodel = this.settings.supermodel;
    const modal = new WorldSelectModal(options);
    modal.callback = this.callback;
    return this.settings.view.openModalView(modal);
  }

  callback(e) {
    if (!e) { return; }
    const target = {
      x: shorten((e.points[0].x + e.points[1].x) / 2),
      y: shorten((e.points[0].y + e.points[1].y) / 2)
    };
    this.set('target', target);
    const bounds = e.camera.normalizeBounds(e.points);
    this.set('zoom', shorten(WIDTH / bounds.width));
    return this.refreshDisplay();
  }
});

module.exports.WorldBoundsNode = (WorldBoundsNode = (function() {
  WorldBoundsNode = class WorldBoundsNode extends TreemaNode.nodeMap.array {
    static initClass() {
      // selecting camera boundaries for a world
      this.prototype.dataType = 'region';
    }

    constructor(...args) {
      this.callback = this.callback.bind(this);
      super(...Array.from(args || []));
      if (this.settings.world == null) { console.error('Bounds Treema node needs a World included in the settings.'); }
      if (this.settings.view == null) { console.error('Bounds Treema node needs a RootView included in the settings.'); }
    }

    buildValueForDisplay(valEl, data) {
      super.buildValueForDisplay(valEl, data);
      return valEl.find('.treema-shortened').prepend(makeButton());
    }

    buildValueForEditing(valEl, data) {
      super.buildValueForEditing(valEl, data);
      return valEl.find('.treema-shortened').prepend(makeButton());
    }

    onClick(e) {
      const btn = $(e.target).closest('.treema-map-button');
      if (btn.length) { return this.openMap(); } else { return super.onClick(...arguments); }
    }

    openMap() {
      const bounds = this.getData() || [{x: 0, y: 0}, {x: 100, y: 80}];
      const modal = new WorldSelectModal({world: this.settings.world, dataType: 'region', default: bounds, supermodel: this.settings.supermodel});
      modal.callback = this.callback;
      return this.settings.view.openModalView(modal);
    }

    callback(e) {
      if (!e) { return; }
      this.set('/0', {x: shorten(e.points[0].x), y: shorten(e.points[0].y)});
      return this.set('/1', {x: shorten(e.points[1].x), y: shorten(e.points[1].y)});
    }
  };
  WorldBoundsNode.initClass();
  return WorldBoundsNode;
})());

module.exports.ThangNode = (ThangNode = class ThangNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    valEl.find('input').autocomplete({source: this.settings.thangIDs, minLength: 0, delay: 0, autoFocus: true});
    return valEl;
  }
});

module.exports.TeamNode = (TeamNode = class TeamNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    valEl.find('input').autocomplete({source: this.settings.teams, minLength: 0, delay: 0, autoFocus: true});
    return valEl;
  }
});

module.exports.SuperteamNode = (SuperteamNode = class SuperteamNode extends TreemaNode.nodeMap.string {
  buildValueForEditing(valEl, data) {
    super.buildValueForEditing(valEl, data);
    valEl.find('input').autocomplete({source: this.settings.superteams, minLength: 0, delay: 0, autoFocus: true});
    return valEl;
  }
});

module.exports.RadiansNode = (RadiansNode = class RadiansNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    const deg = (data / Math.PI) * 180;
    return valEl.text(valEl.text() + `rad (${deg.toFixed(0)}˚)`);
  }
});

module.exports.MetersNode = (MetersNode = class MetersNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 'm');
  }
});

module.exports.KilogramsNode = (KilogramsNode = class KilogramsNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 'kg');
  }
});

module.exports.SecondsNode = (SecondsNode = class SecondsNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 's');
  }
});

module.exports.MillisecondsNode = (MillisecondsNode = class MillisecondsNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 'ms');
  }
});

module.exports.SpeedNode = (SpeedNode = class SpeedNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 'm/s');
  }
});

module.exports.AccelerationNode = (AccelerationNode = class AccelerationNode extends TreemaNode.nodeMap.number {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return valEl.text(valEl.text() + 'm/s^2');
  }
});

module.exports.ThangTypeNode = (ThangTypeNode = (function() {
  ThangTypeNode = class ThangTypeNode extends TreemaNode.nodeMap.string {
    static initClass() {
      this.prototype.valueClass = 'treema-thang-type';
      this.thangTypes = null;
      this.thangTypesCollection = null;
    }

    constructor(...args) {
      super(...Array.from(args || []));
      const data = this.getData();
      this.thangType = _.find(this.settings.supermodel.getModels(ThangType), m => { if (data) { return m.get('original') === data; } });
    }

    buildValueForDisplay(valEl) {
      return this.buildValueForDisplaySimply(valEl, (this.thangType != null ? this.thangType.get('name') : undefined) || 'None');
    }

    buildValueForEditing(valEl, data) {
      super.buildValueForEditing(valEl, data);
      const thangTypeNames = (Array.from(this.settings.supermodel.getModels(ThangType)).map((m) => m.get('name')));
      const input = valEl.find('input').autocomplete({source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true});
      input.val((this.thangType != null ? this.thangType.get('name') : undefined) || 'None');
      return valEl;
    }

    saveChanges() {
      const thangTypeName = this.$el.find('input').val();
      this.thangType = _.find(this.settings.supermodel.getModels(ThangType), m => m.get('name') === thangTypeName);
      if (this.thangType) {
        return this.data = this.thangType.get('original');
      } else {
        return this.data = null;
      }
    }
  };
  ThangTypeNode.initClass();
  return ThangTypeNode;
})());

module.exports.ThangTypeNode = (ThangTypeNode = (ThangTypeNode = (function() {
  ThangTypeNode = class ThangTypeNode extends TreemaNode.nodeMap.string {
    static initClass() {
      this.prototype.valueClass = 'treema-thang-type';
      this.thangTypesCollection = null;  // Lives in ThangTypeNode parent class
      this.thangTypes = null;
        // Lives in ThangTypeNode or subclasses
    }

    constructor() {
      super(...arguments);
      this.getThangTypes();
      if (!ThangTypeNode.thangTypesCollection.loaded) {
        const f = function() {
          if (!this.isEditing()) { this.refreshDisplay(); }
          return this.getThangTypes();
        };
        ThangTypeNode.thangTypesCollection.once('sync', f, this);
      }
    }

    buildValueForDisplay(valEl, data) {
      this.buildValueForDisplaySimply(valEl, this.getCurrentThangType() || '');
      return valEl;
    }

    buildValueForEditing(valEl, data) {
      super.buildValueForEditing(valEl, data);
      const input = valEl.find('input');
      const source = (req, res) => {
        let { term } = req;
        term = term.toLowerCase();
        if (!this.constructor.thangTypes) { return res([]); }
        return res((() => {
          const result = [];
          for (var thangType of Array.from(this.constructor.thangTypes)) {             if (_.string.contains(thangType.name.toLowerCase(), term)) {
              result.push(thangType.name);
            }
          }
          return result;
        })());
      };
      input.autocomplete({source, minLength: 0, delay: 0, autoFocus: true});
      input.val(this.getCurrentThangType() || '');
      return valEl;
    }

    filterThangType(thangType) { return true; }

    getCurrentThangType() {
      let original;
      if (!this.constructor.thangTypes) { return null; }
      if (!(original = this.getData())) { return null; }
      const thangType = _.find(this.constructor.thangTypes, { original });
      return (thangType != null ? thangType.name : undefined) || '...';
    }

    getThangTypes() {
      if (ThangTypeNode.thangTypesCollection) {
        if (!this.constructor.thangTypes) {
          this.processThangTypes(ThangTypeNode.thangTypesCollection);
        }
        return;
      }
      ThangTypeNode.thangTypesCollection = new CocoCollection([], {
        url: '/db/thang.type',
        project:['name', 'components', 'original'],
        model: ThangType
      });
      const res = ThangTypeNode.thangTypesCollection.fetch();
      return ThangTypeNode.thangTypesCollection.once('sync', () => this.processThangTypes(ThangTypeNode.thangTypesCollection));
    }

    processThangTypes(thangTypeCollection) {
      this.constructor.thangTypes = [];
      return Array.from(thangTypeCollection.models).map((thangType) => this.processThangType(thangType));
    }

    processThangType(thangType) {
      return this.constructor.thangTypes.push({name: thangType.get('name'), original: thangType.get('original')});
    }

    saveChanges() {
      const thangTypeName = this.$el.find('input').val();
      const thangType = _.find(this.constructor.thangTypes, {name: thangTypeName});
      if (!thangType) { return this.remove(); }
      return this.data = thangType.original;
    }
  };
  ThangTypeNode.initClass();
  return ThangTypeNode;
})()));

module.exports.ItemThangTypeNode = (ItemThangTypeNode = (ItemThangTypeNode = (function() {
  ItemThangTypeNode = class ItemThangTypeNode extends ThangTypeNode {
    static initClass() {
      this.prototype.valueClass = 'treema-item-thang-type';
    }

    filterThangType(thangType) {
      return Array.from(thangType.slots).includes(this.keyForParent);
    }

    processThangType(thangType) {
      let itemComponent;
      if (!(itemComponent = _.find(thangType.get('components'), {original: LevelComponent.ItemID}))) { return; }
      return this.constructor.thangTypes.push({name: thangType.get('name'), original: thangType.get('original'), slots: (itemComponent.config != null ? itemComponent.config.slots : undefined) != null ? (itemComponent.config != null ? itemComponent.config.slots : undefined) : ['right-hand']});
    }
  };
  ItemThangTypeNode.initClass();
  return ItemThangTypeNode;
})()));

module.exports.ChatMessageLinkNode = (ChatMessageLinkNode = (ChatMessageLinkNode = class ChatMessageLinkNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);

    this.$el.find('.ai-chat-message-link').remove();
    this.$el.find('.treema-row').prepend($(`<span class='ai-chat-message-link'><a href='/editor/ai-chat-message/${data}' target='_blank' title='Edit'>(e)</a>&nbsp;</span>`));

    const chatMessageCollection = new CocoCollection([], {
      url: '/db/ai_chat_message',
      project:['actor', 'text'],
      model: AIChatMessage
    });
    const res = chatMessageCollection.fetch({url: `/db/ai_chat_message/${data}`});
    return chatMessageCollection.once('sync', () => this.processChatMessages(chatMessageCollection));
  }

  processChatMessages(chatMessageCollection) {
    const text = __guard__(chatMessageCollection.models != null ? chatMessageCollection.models[0] : undefined, x => x.get('text'));
    if (text) {
      const htmlText = entities.decodeHTML(text.substring(0, 60));
      this.$el.find('.ai-chat-message-link-text').remove();
      this.$el.find('.treema-row').append($("<span class='ai-chat-message-link-text'></span>").text(htmlText));
    }

    const actor = __guard__(chatMessageCollection.models != null ? chatMessageCollection.models[0] : undefined, x1 => x1.get('actor'));
    if (actor) {
      this.$el.find('.ai-chat-message-actor').remove();
      return this.$el.find('.treema-row').append($(`<span class='ai-chat-message-actor'>&nbsp;<sub>actor:</sub> ${actor}&nbsp;</span>`));
    }
  }
}));

module.exports.ChatMessageParentLinkNode = (ChatMessageParentLinkNode = (ChatMessageParentLinkNode = class ChatMessageParentLinkNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    if (!data) { return; }

    const {
      parentKind
    } = this.parent.data;

    if (!parentKind) { return; }

    this.$el.find('.ai-chat-message-link').remove();
    this.$el.find('.treema-row').prepend($(`<span class='ai-chat-message-link'><a href='/editor/ai-${parentKind}/${data}' title='Edit' target='_blank'>(e)</a>&nbsp;</span>`));

    const parentCollection = new CocoCollection([], {
      url: `/db/ai_${parentKind}`,
      project:['name'],
      model: parentKind === 'project' ? AIProject : AIScenario
    });
    const res = parentCollection.fetch({url: `/db/ai_${parentKind}/${data}`});
    return parentCollection.once('sync', () => this.processParent(parentCollection));
  }

  processParent(parentCollection) {
    const text = __guard__(parentCollection.models != null ? parentCollection.models[0] : undefined, x => x.get('name'));
    if (text) {
      const htmlText = entities.decodeHTML(text.substring(0, 60));
      this.$el.find('.ai-chat-message-parent-name').remove();
      return this.$el.find('.treema-row').append($("<span class='ai-chat-message-parent-name'></span>").text(htmlText));
    }
  }
}));



module.exports.AIDocumentLinkNode = (AIDocumentLinkNode = (AIDocumentLinkNode = class AIDocumentLinkNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    if (!data) { return; }

    this.$el.find('.ai-document-link').remove();
    return this.$el.find('.treema-row').prepend($(`<span class='ai-document-link'><a href='/editor/ai-document/${data}' title='Edit' target='_blank'>(e)</a>&nbsp;</span>`));
  }
}));

module.exports.StateNode = (StateNode = (SateNode = class SateNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    let state;
    super.buildValueForDisplay(valEl, data);
    if (!data) { return; }
    if (!(state = utils.usStateCodes.getStateNameByStateCode(this.data))) { return console.error(`Couldn't find state ${this.data}`); }

    const stateElement = () => $(`<span> - <i>${state}</i></span>`);
    return valEl.find('.treema-shortened').append(stateElement());
  }
}));

module.exports.conceptNodes = function(concepts) {
  class ConceptNode extends TreemaNode.nodeMap.string {
    buildValueForDisplay(valEl, data) {
      let concept;
      super.buildValueForDisplay(valEl, data);
      if (!data) { return; }
      const conceptList = concepts.map(i => i.toJSON());
      if (!(concept = _.find(conceptList, {key: this.data}))) { return console.error(`Couldn't find concept ${this.data}`); }
      let description = `${concept.name} -- ${concept.description}`;
      if (concept.deprecated) { description = description + " (Deprecated)"; }
      if (concept.automatic) { description = "AUTO | " + description; }
      this.$el.find('.treema-row').css('float', 'left');
      if (concept.automatic) { this.$el.addClass('concept-automatic'); }
      if (concept.deprecated) { this.$el.addClass('concept-deprecated'); }
      this.$el.find('.treema-description').remove();
      return this.$el.append($(`<span class='treema-description'>${description}</span>`).show());
    }

    limitChoices(options) {
      let o, c;
      if ((this.parent.keyForParent === 'concepts') && (!this.parent.parent)) {
        options = ((() => {
          const result = [];
          for (o of Array.from(options)) {             if (_.find(concepts, c => (c.get('key') === o) && !c.get('automatic') && !c.get('deprecated'))) {
              result.push(o);
            }
          }
          return result;
        })());  // Allow manual, not automatic
      } else {
        options = ((() => {
          const result1 = [];
          for (o of Array.from(options)) {             if (_.find(concepts, c => (c.get('key') === o) && !c.get('deprecated'))) {
              result1.push(o);
            }
          }
          return result1;
        })());  // Allow both
      }
      return super.limitChoices(options);
    }

    onClick(e) {
      if ((this.parent.keyForParent === 'concepts') && (!this.parent.parent) && this.$el.hasClass('concept-automatic')) { return; }  // Don't allow editing of automatic concepts
      return super.onClick(e);
    }
  }

  class ConceptsListNode extends TreemaNode.nodeMap.array {
    static initClass() {
      this.prototype.sort = true;
    }

    sortFunction(a, b) {
      const aAutomatic = _.find(concepts, c => (c.get('key') === a) && c.get('automatic'));
      const bAutomatic = _.find(concepts, c => (c.get('key') === b) && c.get('automatic'));
      if (bAutomatic && !aAutomatic) { return 1; }  // Auto before manual
      if (aAutomatic && !bAutomatic) { return -1; }  // Auto before manual
      if (!aAutomatic && !bAutomatic) { return 0; }  // No ordering within manual
      return super.sortFunction(a, b);
    }
  }
  ConceptsListNode.initClass();  // Alpha within auto
  return {
    ConceptsListNode,
    ConceptNode
  };
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
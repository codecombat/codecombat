/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteView;
require('app/styles/play/level/tome/spell-palette-view.sass');
const CocoView = require('views/core/CocoView');
const {me} = require('core/auth');
const filters = require('lib/image_filter');
const SpellPaletteEntryView = require('./SpellPaletteEntryView');
const SpellPaletteThangEntryView = require('./SpellPaletteThangEntryView');
const LevelComponent = require('models/LevelComponent');
const ThangType = require('models/ThangType');
const GameMenuModal = require('views/play/menu/GameMenuModal');
const LevelSetupManager = require('lib/LevelSetupManager');
const ace = require('lib/aceContainer');
const aceUtils = require('core/aceUtils');

const N_ROWS = 4;

module.exports = (SpellPaletteView = (function() {
  SpellPaletteView = class SpellPaletteView extends CocoView {
    static initClass() {
      this.prototype.id = 'spell-palette-view';
      this.prototype.template = require('app/templates/play/level/tome/spell-palette-view-mid');
      this.prototype.controlsEnabled = true;
      this.prototype.position = 'mid';

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'surface:frame-changed': 'onFrameChanged',
        'tome:change-language': 'onTomeChangedLanguage',
        'tome:palette-clicked': 'onPaletteClick',
        'surface:stage-mouse-down': 'hide',
        'level:gather-chat-message-context': 'onGatherChatMessageContext'
      };

      this.prototype.events = {
        'click .closeBtn': 'onClickClose',
        'click .section-header': 'onSectionHeaderClick'
      };
    }

    constructor (options) {
      super(options)
      this.onResize = this.onResize.bind(this)
      this.hide = this.hide.bind(this);
      ({level: this.level, session: this.session, thang: this.thang, useHero: this.useHero} = options);
      this.aceEditors = []
      const docs = options.level.get('documentation') || {}
      this.createPalette()
      $(window).on('resize', this.onResize)
    }

    getRenderData() {
      const c = super.getRenderData();
      c.entryGroups = this.entryGroups;
      c.tabbed = _.size(this.entryGroups) > 1;
      c.tabs = this.tabs;  // For hero-based, non-this-owned tabs like Vector, Math, etc.
      c.thisName = {coffeescript: '@', lua: 'self', python: 'self', java: 'hero', cpp: 'hero'}[this.options.language] || 'this';
      c._ = _;
      return c;
    }

    afterRender() {
      let entries, entry, entryIndex, itemGroup;
      super.afterRender();
      this.entryGroupElements = {};
      for (var group in this.entryGroups) {
        entries = this.entryGroups[group];
        this.entryGroupElements[group] = (itemGroup = $('<div class="property-entry-item-group"></div>').appendTo(this.$el.find('.properties-this')));
        if (entries[0].options.item != null ? entries[0].options.item.getPortraitURL : undefined) {
          var itemImage = $('<img class="item-image" draggable=false></img>').attr('src', entries[0].options.item.getPortraitURL());
          if (this.position === 'bot') {
            itemImage.css('top', Math.max(0, (19 * (entries.length - 2)) / 2) + 2);
          }
          itemGroup.append(itemImage);
          var firstEntry = entries[0];
          (function(firstEntry) {
            itemImage.on("mouseenter", e => firstEntry.onMouseEnter(e));
            return itemImage.on("mouseleave", e => firstEntry.onMouseLeave(e));
          })(firstEntry);
        }
        for (entryIndex = 0; entryIndex < entries.length; entryIndex++) {
          entry = entries[entryIndex];
          itemGroup.append(entry.el);
          entry.render();  // Render after appending so that we can access parent container for popover
          if (entries.length === 1) {
            entry.$el.addClass('single-entry');
          }
          if (entryIndex === 0) {
            entry.$el.addClass('first-entry');
          }
        }
      }
      const object = this.tabs || {};
      for (var tab in object) {
        entries = object[tab];
        var tabSlug = _.string.slugify(tab);
        var itemsInGroup = 0;
        for (entryIndex = 0; entryIndex < entries.length; entryIndex++) {
          entry = entries[entryIndex];
          if ((itemsInGroup === 0) || ((itemsInGroup === 2) && (entryIndex !== (entries.length - 1)))) {
            itemGroup = $('<div class="property-entry-item-group"></div>').appendTo(this.$el.find(`.properties-${tabSlug}`));
            itemsInGroup = 0;
          }
          ++itemsInGroup;
          itemGroup.append(entry.el);
          entry.render();  // Render after appending so that we can access parent container for popover
          if (itemsInGroup === 0) {
            entry.$el.addClass('first-entry');
          }
        }
      }
      this.$el.addClass('hero');
      this.$el.toggleClass('shortenize', Boolean(this.shortenize));
      this.$el.toggleClass('web-dev', this.options.level.isType('web-dev'));

      const tts = this.supermodel.getModels(ThangType);

      for (var dn in this.deferredDocs) {
        var t;
        var doc = this.deferredDocs[dn];
        if (doc.type === "spawnable") {
          var thangName = doc.name;
          if (this.thang.spawnAliases[thangName]) {
            thangName = this.thang.spawnAliases[thangName][0];
          }

          var info = this.thang.buildables[thangName];
          var tt = _.find(tts, t => t.get('original') === (info != null ? info.thangType : undefined));
          if (tt == null) { continue; }
          t = new SpellPaletteThangEntryView({doc, thang: tt, buildable: info, buildableName: doc.name, shortenize: true, language: this.options.language, level: this.options.level, useHero: this.useHero});
          this.$el.find("#palette-tab-stuff-area").append(t.el);
          t.render();
        }

        if (doc.type === "event") {
          t = new SpellPaletteEntryView({doc, thang: this.thang, shortenize: true, language: this.options.language, level: this.options.level, useHero: this.useHero});
          this.$el.find("#palette-tab-events").append(t.el);
          t.render();
        }

        if (doc.type === "handler") {
          t = new SpellPaletteEntryView({doc, thang: this.thang, shortenize: true, language: this.options.language, level: this.options.level, useHero: this.useHero});
          this.$el.find("#palette-tab-handlers").append(t.el);
          t.render();
        }

        if (doc.type === "property") {
          t = new SpellPaletteEntryView({doc, thang: this.thang, shortenize: true, language: this.options.language, level: this.options.level, writable: true});
          this.$el.find("#palette-tab-properties").append(t.el);
          t.render();
        }

        if ((doc.type === "snippet") && (this.level.get('type') === 'game-dev')) {
          t = new SpellPaletteEntryView({doc, thang: this.thang, isSnippet: true, shortenize: true, language: this.options.language, level: this.options.level});
          this.$el.find("#palette-tab-snippets").append(t.el);
          t.render();
        }
      }

      return this.$(".section-header:has(+.collapse:empty)").hide();
    }

    afterInsert() {
      super.afterInsert();
      return _.delay(() => { if (!$('#spell-view').is('.shown')) { return (this.$el != null ? this.$el.css('bottom', 0) : undefined); } });
    }

    updateCodeLanguage(language) {
      return this.options.language = language;
    }

    calculateNColumns() {
      if (!this.isHero || (this.position !== 'bot')) { return 1; }
      let columnWidth = 212;
      if (this.shortenize) { columnWidth = 175; }
      if (this.options.level.isType('web-dev')) { columnWidth = 100; }
      const availableWidth = this.$el.find('.properties-this').innerWidth() || ($('#code-area').innerWidth() - 40);
      const nColumns = Math.floor(availableWidth / columnWidth);   // Will always have at least 2 columns, since at 1024px screen we have 425px .properties
      return Math.max(2, nColumns);
    }

    updateMaxHeight() {
      if (!this.isHero || (this.position !== 'bot')) { return; }
      // We figure out how many columns we can fit, width-wise, and then guess how many rows will be needed.
      // We can then assign a height based on the number of rows, and the flex layout will do the rest.
      const nColumns = this.calculateNColumns();
      const columns = (__range__(0, nColumns, false).map((i) => ({items: [], nEntries: 0})));
      const orderedColumns = [];
      let nRows = 0;
      const entryGroupsByLength = _.sortBy(_.keys(this.entryGroups), group => this.entryGroups[group].length);
      entryGroupsByLength.reverse();
      for (var group of Array.from(entryGroupsByLength)) {
        var shortestColumn;
        var entries = this.entryGroups[group];
        if (!(shortestColumn = _.sortBy(columns, column => column.nEntries)[0])) { continue; }
        shortestColumn.nEntries += Math.max(2, entries.length);  // Item portrait is two rows tall
        shortestColumn.items.push(this.entryGroupElements[group]);
        if (!Array.from(orderedColumns).includes(shortestColumn)) { orderedColumns.push(shortestColumn); }
        nRows = Math.max(nRows, shortestColumn.nEntries);
      }
      for (var column of Array.from(orderedColumns)) {
        for (var item of Array.from(column.items)) {
          item.detach().appendTo(this.$el.find('.properties-this'));
        }
      }
      const desiredHeight = 19 * (nRows + 1);
      return this.$el.find('.properties').css('height', desiredHeight);
    }

    onResize(e) {
      return (typeof this.updateMaxHeight === 'function' ? this.updateMaxHeight() : undefined);
    }

    createPalette() {
      let propStorage;
      Backbone.Mediator.publish('tome:palette-cleared', {thangID: this.thang.id});
      const lcs = this.supermodel.getModels(LevelComponent);

      const allDocs = {};
      const excludedDocs = {};
      for (var lc of Array.from(lcs)) {
        var left;
        for (var doc of Array.from(((left = lc.get('propertyDocumentation')) != null ? left : []))) {
          var name;
          if (doc.codeLanguages && !(Array.from(doc.codeLanguages).includes(this.options.language))) {
            excludedDocs['__' + doc.name] = doc;
            continue;
          }
          if (allDocs[name = '__' + doc.name] == null) { allDocs[name] = []; }
          allDocs['__' + doc.name].push(doc);
          if (doc.type === 'snippet') { doc.owner = 'snippets'; }
        }
      }

      if (this.options.programmable) {
        propStorage = {
          'this': 'programmableProperties',
          more: 'moreProgrammableProperties',
          Math: 'programmableMathProperties',
          Array: 'programmableArrayProperties',
          Object: 'programmableObjectProperties',
          String: 'programmableStringProperties',
          Global: 'programmableGlobalProperties',
          Function: 'programmableFunctionProperties',
          RegExp: 'programmableRegExpProperties',
          Date: 'programmableDateProperties',
          Number: 'programmableNumberProperties',
          JSON: 'programmableJSONProperties',
          LoDash: 'programmableLoDashProperties',
          Vector: 'programmableVectorProperties',
          HTML: 'programmableHTMLProperties',
          WebJavaScript: 'programmableWebJavaScriptProperties',
          jQuery: 'programmableJQueryProperties',
          CSS: 'programmableCSSProperties',
          snippets: 'programmableSnippets'
        };
      } else {
        propStorage =
          {'this': ['apiProperties', 'apiMethods']};
      }
      return this.organizePalette(propStorage, allDocs, excludedDocs);
    }

    organizePalette(propStorage, allDocs, excludedDocs) {
      // Assign any kind of programmable properties to the items that grant them.
      let doc, group, item, name, owner, prop, props, storage;
      let entry;
      this.isHero = true;
      const itemThangTypes = {};
      for (var tt of Array.from(this.supermodel.getModels(ThangType))) { itemThangTypes[tt.get('name')] = tt; }  // Also heroes
      const propsByItem = {};
      let propCount = 0;
      const itemsByProp = {};
      this.deferredDocs = {};
      // Make sure that we get the spellbook first, then the primary hand, then anything else.
      const slots = _.sortBy(_.keys(this.thang.inventoryThangTypeNames != null ? this.thang.inventoryThangTypeNames : {}), function(slot) {
        if (slot === 'left-hand') { return 0; } else if (slot === 'right-hand') { return 1; } else { return 2; }
      });
      for (var slot of Array.from(slots)) {
        var thangTypeName = this.thang.inventoryThangTypeNames[slot];
        if (item = itemThangTypes[thangTypeName]) {
          var left;
          if (!item.get('components')) {
            console.error('Item', item, 'did not have any components when we went to assemble docs.');
          }
          for (var component of Array.from((left = item.get('components')) != null ? left : [])) {
            if (component.config) {
              for (owner in propStorage) {
                var storages = propStorage[owner];
                if (props = component.config[storages]) {
                  for (prop of Array.from(_.sortBy(props))) {  // no private properties
                    if ((prop[0] !== '_') && !itemsByProp[prop]) {
                      if ((prop === 'moveXY') && (this.options.level.get('slug') === 'slalom')) { continue; }  // Hide for Slalom
                      if (this.thang.excludedProperties && Array.from(this.thang.excludedProperties).includes(prop)) { continue; }
                      // Temporary: switching up method documentation for M7 levels
                      if ((this.options.level.get('releasePhase') === 'beta') && (['moveUp', 'moveRight', 'moveDown', 'moveLeft'].includes(prop))) { continue; }
                      if ((this.options.level.get('releasePhase') !== 'beta') && (['moveTo', 'use'].includes(prop))) { continue; }
                      if (propsByItem[name = item.get('name')] == null) { propsByItem[name] = []; }
                      propsByItem[item.get('name')].push({owner, prop, item});
                      itemsByProp[prop] = item;
                      ++propCount;
                    }
                  }
                }
              }
            }
          }
        } else {
          console.log(this.thang.id, "couldn't find item ThangType for", slot, thangTypeName);
        }
      }

      // Get any Math-, Vector-, etc.-owned properties into their own tabs
      for (owner in propStorage) {
        storage = propStorage[owner];
        if (!(['this', 'more', 'snippets', 'HTML', 'CSS', 'WebJavaScript', 'jQuery'].includes(owner))) {
          if (!(this.thang[storage] != null ? this.thang[storage].length : undefined)) { continue; }
          if (this.tabs == null) { this.tabs = {}; }
          this.tabs[owner] = [];
          var programmaticonName = this.thang.inventoryThangTypeNames['programming-book'];
          var programmaticon = itemThangTypes[programmaticonName];
          var sortedProps = this.thang[storage].slice().sort();
          for (prop of Array.from(sortedProps)) {
            var left1;
            if (this.thang.excludedProperties && Array.from(this.thang.excludedProperties).includes(prop)) { continue; }
            if (doc = _.find(((left1 = allDocs['__' + prop]) != null ? left1 : []), {owner})) {  // Not all languages have all props
              if (this.position === 'bot') {
                // Assign them to the hero
                if (propsByItem[owner] == null) { propsByItem[owner] = []; }
                propsByItem[owner].push({owner, prop, item: programmaticon});
              } else {
                // Assign them to their tabs
                entry = this.addEntry(doc, false, false, programmaticon);
                this.tabs[owner].push(entry);
              }
            }
          }
        }
      }

      // Assign any unassigned properties to the hero itself.
      for (owner in propStorage) {
        storage = propStorage[owner];
        if (!['this', 'more', 'snippets', 'HTML', 'CSS', 'WebJavaScript', 'jQuery'].includes(owner)) { continue; }
        for (prop of Array.from(_.reject(this.thang[storage] != null ? this.thang[storage] : [], prop => itemsByProp[prop] || (prop[0] === '_')))) {  // no private properties
          if ((prop === 'say') && this.options.level.get('hidesSay')) { continue; }  // Hide for Dungeon Campaign
          if ((prop === 'moveXY') && (this.options.level.get('slug') === 'slalom')) { continue; }  // Hide for Slalom
          if (this.thang.excludedProperties && Array.from(this.thang.excludedProperties).includes(prop)) { continue; }
          // Temporary: switching up method documentation for M7 levels
          if ((this.options.level.get('releasePhase') === 'beta') && (['moveUp', 'moveRight', 'moveDown', 'moveLeft'].includes(prop))) { continue; }
          if ((this.options.level.get('releasePhase') !== 'beta') && (['moveTo', 'use'].includes(prop))) { continue; }
          var warriorHeroProps = ['warcry', 'throw', 'throwAt', 'throwPos', 'throwRange', 'shieldBubble', 'slam', 'reflect', 'forcePush', 'charismagnetize', 'stomp', 'hurl', 'absoluteShield', 'heartShield'];
          if (me.isStudent() && me.showHeroAndInventoryModalsToStudents() && (Array.from(warriorHeroProps).includes(prop))) { continue; }
          if (propsByItem['Hero'] == null) { propsByItem['Hero'] = []; }
          propsByItem['Hero'].push({owner, prop, item: itemThangTypes[this.thang.spriteName]});
          ++propCount;
        }
      }

      Backbone.Mediator.publish('tome:update-snippets', {propGroups: propsByItem, allDocs, language: this.options.language});

      this.shortenize = propCount > 6;
      this.entries = [];
      for (var itemName in propsByItem) {
        props = propsByItem[itemName];
        for (var propIndex = 0; propIndex < props.length; propIndex++) {
          var left2;
          prop = props[propIndex];
          ({
            item
          } = prop);
          ({
            owner
          } = prop);
          ({
            prop
          } = prop);
          doc = _.find(((left2 = allDocs['__' + prop]) != null ? left2 : []), function(doc) {
            if (doc.owner === owner) { return true; }
            return ((owner === 'this') || (owner === 'more')) && ((doc.owner == null) || (doc.owner === 'this') || (doc.owner === 'ui'));
          });
          if (!doc && !excludedDocs['__' + prop]) {
            console.log('could not find doc for', prop, 'from', allDocs['__' + prop], 'for', owner, 'of', propsByItem, 'with item', item);
            if (doc == null) { doc = prop; }
          }
          if (doc) {
            if (['spawnable', 'event', 'handler', 'property'].includes(doc.type) || ((doc.type === 'snippet') && (this.level.get('type') === 'game-dev'))) {
              this.deferredDocs[doc.name] = doc;
            } else {
              this.entries.push(this.addEntry(doc, this.shortenize, owner === 'snippets', item, propIndex > 0));
            }
          }
        }
      }
      if (this.options.level.isType('web-dev')) {
        this.entryGroups = _.groupBy(this.entries, entry => entry.doc.type);
      } else {
        this.entryGroups = _.groupBy(this.entries, function(entry) {
          let left3;
          return (left3 = __guardMethod__(itemsByProp[entry.doc.name], 'get', o => o.get('name'))) != null ? left3 : 'Hero';
        });
      }
      if (this.position === 'bot') {
        // Reorganize to balance number of entries in each group (especially useful for arenas when all properties are on hero)
        const nColumns = this.calculateNColumns();
        const itemsPerGroup = Math.max(4, Math.ceil(propCount / nColumns));
        for (group of Array.from(_.keys(this.entryGroups))) {
          var excessGroupCounter = 1;
          while (this.entryGroups[group].length > itemsPerGroup) {
            var excessEntries = this.entryGroups[group].splice(itemsPerGroup, itemsPerGroup);
            this.entryGroups[group + ` ${++excessGroupCounter}`] = excessEntries;
          }
        }
      }
      const entryGroups = {};
      for (group in this.entryGroups) {
        var entries = this.entryGroups[group];
        entryGroups[group] = {
          item: {name: group, imageURL: (itemThangTypes[group] != null ? itemThangTypes[group].getPortraitURL() : undefined)},
          props: (((() => {
            const result = [];
            for (entry of Array.from(entries)) {               result.push(entry.doc);
            }
            return result;
          })()))
        };
      }
      return Backbone.Mediator.publish('tome:palette-updated', {thangID: this.thang.id, entryGroups});
    }

    addEntry(doc, shortenize, isSnippet, item=null, showImage) {
      let needle;
      if (isSnippet == null) { isSnippet = false; }
      if (showImage == null) { showImage = false; }
      const writable = ((needle = _.isString(doc) ? doc : doc.name), Array.from((this.thang.apiUserProperties != null ? this.thang.apiUserProperties : [])).includes(needle));
      return new SpellPaletteEntryView({doc, thang: this.thang, shortenize, isSnippet, language: this.options.language, writable, level: this.options.level, item, showImage, useHero: this.useHero, spellPalettePosition: this.position});
    }

    onDisableControls(e) { return this.toggleControls(e, false); }
    onEnableControls(e) { return this.toggleControls(e, true); }
    toggleControls(e, enabled) {
      if (e.controls && !(Array.from(e.controls).includes('palette'))) { return; }
      if (enabled === this.controlsEnabled) { return; }
      this.controlsEnabled = enabled;
      this.$el.find('*').attr('disabled', !enabled);
      return this.$el.toggleClass('controls-disabled', !enabled);
    }

    onFrameChanged(e) {
      if ((e.selectedThang != null ? e.selectedThang.id : undefined) !== this.thang.id) { return; }
      return this.options.thang = (this.thang = e.selectedThang);  // Update our thang to the current version
    }

    onTomeChangedLanguage(e) {
      this.updateCodeLanguage(e.language);
      for (var entry of Array.from(this.entries)) { entry.destroy(); }
      this.createPalette();
      return this.render();
    }

    onSectionHeaderClick(e) {
      const $et = this.$(e.currentTarget);
      const target = this.$($et.attr('data-panel'));
      const isCollapsed = !target.hasClass('in');
      if (isCollapsed) {
        target.collapse('show');
        $et.find('.glyphicon').removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-down');
      } else {
        target.collapse('hide');
        $et.find('.glyphicon').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-right');
      }

      setTimeout(() => {
        return this.$('.nano').nanoScroller({alwaysVisible: true});
      }
      , 200);
      return e.preventDefault();
    }

    onClickClose(e) {
      return this.hide();
    }

    hide() {
      this.$el.find('.left .selected').removeClass('selected');
      return this.$el.removeClass('open');
    }

    onPaletteClick(e) {
      this.$el.addClass('open');
      const content = this.$el.find(".rightContentTarget");
      content.html(e.entry.doc.initialHTML);
      content.i18n();
      this.applyRTLIfNeeded();
      const codeLanguage = e.entry.options.language;
      for (var oldEditor of Array.from(this.aceEditors)) { oldEditor.destroy(); }
      this.aceEditors = [];
      const {
        aceEditors
      } = this;
      // Initialize Ace for each popover code snippet that still needs it
      return content.find('.docs-ace').each(function() {
        const aceEditor = aceUtils.initializeACE(this, codeLanguage);
        return aceEditors.push(aceEditor);
      });
    }

    onGatherChatMessageContext(e) {
      const {
        context
      } = e.chat;
      context.apiProperties = [];
      for (var group in this.entryGroups) {
        var entries = this.entryGroups[group];
        for (var entry of Array.from(entries)) {
          var doc;
          if (e.chat.example) {
            // Using entry.options.doc instead of entry.doc skips a lot of the data processing
            doc = _.omit(entry.options.doc, 'shortDescription', 'autoCompletePriority', 'snippets', 'userShouldCaptureReturn');
          } else {
            // Bakes in code language selection and translations
            doc = _.omit(entry.doc, 'ownerName', 'shortName', 'shorterName', 'title', 'initialHTML', 'shortDescription', 'autoCompletePriority', 'snippets', 'i18n', 'userShouldCaptureReturn');
          }
            // TODO: remove more nested i18n
          if (['this', 'more'].includes(doc.owner)) { doc.owner = 'hero'; }
          if (!doc.example) { delete doc.example; }
          if (doc.returns && !doc.returns.example) { if (doc.returns != null) {
            delete doc.returns.example;
          } }
          if (doc.returns && !doc.returns.description) { if (doc.returns != null) {
            delete doc.returns.description;
          } }
          //console.log doc
          context.apiProperties.push(doc);
        }
      }
      return null;
    }

    destroy() {
      for (var entry of Array.from(this.entries)) { entry.destroy(); }
      this.toggleBackground = null;
      $(window).off('resize', this.onResize);
      if (this.setupManager != null) {
        this.setupManager.destroy();
      }
      return super.destroy();
    }
  };
  SpellPaletteView.initClass();
  return SpellPaletteView;
})());

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
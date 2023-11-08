/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteView;
require('ozaria/site/styles/play/level/tome/spell-palette-view.sass');
const CocoView = require('views/core/CocoView');
const {me} = require('core/auth');
const SpellPaletteEntryView = require('./SpellPaletteEntryView');
const SpellPaletteThangEntryView = require('./SpellPaletteThangEntryView');
const LevelComponent = require('models/LevelComponent');
const ThangType = require('models/ThangType');
const ace = require('lib/aceContainer');
const aceUtils = require('core/aceUtils');
const store = require('core/store');

module.exports = (SpellPaletteView = (function() {
  SpellPaletteView = class SpellPaletteView extends CocoView {
    static initClass() {
      this.prototype.id = 'spell-palette-view';
      this.prototype.template = require('ozaria/site/templates/play/level/tome/spell-palette-view');
      this.prototype.controlsEnabled = true;

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'surface:frame-changed': 'onFrameChanged',
        'tome:change-language': 'onTomeChangedLanguage',
        'tome:palette-clicked': 'onPaletteClick'
      };

      this.prototype.events = {
        'click .sub-section-header': 'onSubSectionHeaderClick',
        'click .code-bank-close-btn': 'onCodeBankCloseBtnClick',
        transitionend: 'onTransitionEnd'
      };
    }

    constructor (options) {
      super(options)
      this.onResize = this.onResize.bind(this);
      ({ level: this.level, session: this.session, thang: this.thang, useHero: this.useHero } = options)
      this.aceEditors = []
      this.createPalette()
      $(window).on('resize', this.onResize)
    }

    getRenderData() {
      const c = super.getRenderData();
      c.entryGroups = this.entryGroups;
      c._ = _;
      return c;
    }

    afterRender() {
      super.afterRender();
      return (() => {
        const result = [];
        for (var group in this.entryGroups) {
          var entries = this.entryGroups[group];
          group = _.string.slugify(group);
          var itemGroup = $('<div class="property-entry-item-group"></div>').appendTo(this.$el.find('.properties-'+group));
          var entrySubGroups = _.groupBy(entries, entry => entry.doc.subSection || 'none');
          for (var subGroup in entrySubGroups) {
            var itemSubGroup;
            entries = entrySubGroups[subGroup];
            if (subGroup !== 'none') {
              var header = $(`<div class='sub-section-header' data-panel='#sub-section-${subGroup}-${group}'> \
<span>${subGroup}</span> \
<button tabindex='0' style='float:right;animation: none;position:absolute;right:10px;transform: rotate(90deg);' class='shepherd-next-button-active shepherd-button'></button> \
</a>`).appendTo(itemGroup);
              itemSubGroup = $(`<div class='property-entry-item-sub-group collapse' id='sub-section-${subGroup}-${group}'></div>`).appendTo(itemGroup);
            }
            for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
              var entry = entries[entryIndex];
              if (subGroup !== 'none') {
                itemSubGroup.append(entry.el);
              } else {
                itemGroup.append(entry.el);
              }
              entry.render();
            }
          }  // Render after appending so that we can access parent container for popover
          this.$el.addClass('hero');
          result.push(this.$el.toggleClass('shortenize', Boolean(true)));
        }
        return result;
      })();
    }

    afterInsert() {
      super.afterInsert();
      return _.delay(() => { if (!$('#spell-view').is('.shown')) { return (this.$el != null ? this.$el.css('bottom', 0) : undefined); } });
    }

    updateCodeLanguage(language) {
      return this.options.language = language;
    }

    onResize(e) {
      return (typeof this.updateMaxHeight === 'function' ? this.updateMaxHeight() : undefined);
    }

    createPalette() {
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
          if (doc.type === 'snippet') { doc.owner = 'snippets'; }
          var docCopy = Object.assign({ componentName: lc.get('name') }, doc);
          if (allDocs[name = '__' + doc.name] == null) { allDocs[name] = []; }
          allDocs['__' + doc.name].push(docCopy);
        }
      }

      const methodsBankList = this.options.level.get('methodsBankList') || [];

      if (methodsBankList.length === 0) {
        console.log("Methods Bank list is empty!!");
      } else {
        this.organizePalette(methodsBankList, allDocs, excludedDocs);
      }
      return this.publishAutoCompleteEvent(allDocs);
    }

    // Reads the methods bank list and find its documentation from allDocs(i.e. docs coming from level components)
    // This also groups the list based on the section
    organizePalette(methodsBankList, allDocs, excludedDocs) {
      let doc, section;
      this.entries = [];
      this.tts = this.supermodel.getModels(ThangType);
      const defaultSection = 'methods';
      const defaultSubSection = this.options.level.isType('game-dev') ? 'game' : 'hero';
      for (let propIndex = 0; propIndex < methodsBankList.length; propIndex++) {
        var left;
        var prop = methodsBankList[propIndex];
        ({
          section
        } = prop);
        var {
          subSection
        } = prop;
        if (!section) { // Set default section and sub-section for methods bank
          section = defaultSection;
          subSection = defaultSubSection;
        }
        var propName = prop.name;
        doc = _.find(((left = allDocs['__' + propName]) != null ? left : []), function(doc) {
          if (!prop.componentName || (doc.componentName === prop.componentName)) { return true; }
        });
        if (!doc && !excludedDocs['__' + propName]) {
          console.log('could not find doc for', propName, 'from', allDocs['__' + propName]);
          doc = propName;
        }
        if (doc) {
          this.entries.push(this.addEntry(doc, section, subSection, false));
        }
      }
      return this.entryGroups = _.groupBy(this.entries, entry => entry.doc.section);
    }


    addEntry(doc, section, subSection, shortenize, isSnippet, item=null, showImage) {
      if (shortenize == null) { shortenize = true; }
      if (isSnippet == null) { isSnippet = false; }
      if (showImage == null) { showImage = false; }
      if (doc.type === 'spawnable') {
        let thangName = doc.name;
        if (this.thang.spawnAliases[thangName]) {
          thangName = this.thang.spawnAliases[thangName][0];
        }
        const info = this.thang.buildables[thangName];
        const tt = _.find(this.tts, t => t.get('original') === (info != null ? info.thangType : undefined));
        if (tt) {
          return new SpellPaletteThangEntryView({doc, section, subSection, thang: tt, buildable: info, buildableName: doc.name, shortenize, language: this.options.language, level: this.options.level, useHero: this.useHero});
        }
      } else {
        let needle;
        const writable = ((needle = _.isString(doc) ? doc : doc.name), Array.from((this.thang.apiUserProperties != null ? this.thang.apiUserProperties : [])).includes(needle));
        return new SpellPaletteEntryView({doc, section, subSection, thang: this.thang, shortenize, isSnippet, language: this.options.language, writable, level: this.options.level, item, showImage, useHero: this.useHero});
      }
    }

    // This uses the legacy logic to publish event for auto completion in the code editor using programmable properties.
    // This can potentially be merged with the logic in organizePalette, but currently doing that makes it behave differently, so keeping it as it is for now
    publishAutoCompleteEvent(allDocs) {
      let item, owner, prop, propStorage;
      const propsByItem = {};
      const itemsByProp = {};
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

      const itemThangTypes = {};
      for (var tt of Array.from(this.supermodel.getModels(ThangType))) { itemThangTypes[tt.get('name')] = tt; }  // Also heroes

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
                var props;
                var storages = propStorage[owner];
                if (props = component.config[storages]) {
                  for (prop of Array.from(_.sortBy(props))) {  // no private properties
                    if ((prop[0] !== '_') && !itemsByProp[prop]) {var name;

                      if ((prop === 'moveXY') && (this.options.level.get('slug') === 'slalom')) { continue } // Hide for Slalom
                      if (this.thang.excludedProperties && Array.from(this.thang.excludedProperties).includes(prop)) { continue; }
                      if (propsByItem[name = item.get('name')] == null) { propsByItem[name] = []; }
                      propsByItem[item.get('name')].push({ owner, prop, item })
                      itemsByProp[prop] = item;
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

      for (owner in propStorage) {
        var storage = propStorage[owner];
        if (!['this', 'more', 'snippets', 'HTML', 'CSS', 'WebJavaScript', 'jQuery'].includes(owner)) { continue; }
        for (prop of Array.from(_.reject(this.thang[storage] != null ? this.thang[storage] : [], prop => prop[0] === '_'))) {  // no private properties
          if ((prop === 'say') && this.options.level.get('hidesSay')) { continue; }  // Hide for Dungeon Campaign
          if ((prop === 'moveXY') && (this.options.level.get('slug') === 'slalom')) { continue; }  // Hide for Slalom
          if (this.thang.excludedProperties && Array.from(this.thang.excludedProperties).includes(prop)) { continue; }
          if (propsByItem['Hero'] == null) { propsByItem['Hero'] = []; }
          propsByItem['Hero'].push({owner, prop, item: itemThangTypes[this.thang.spriteName]});
        }
      }
      return Backbone.Mediator.publish('tome:update-snippets', {propGroups: propsByItem, allDocs, language: this.options.language});
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
      if ((e.selectedThang != null ? e.selectedThang.id : undefined) !== (this.thang != null ? this.thang.id : undefined)) { return; }
      return this.options.thang = (this.thang = e.selectedThang);  // Update our thang to the current version
    }

    onTomeChangedLanguage(e) {
      this.updateCodeLanguage(e.language);
      for (var entry of Array.from(this.entries)) { entry.destroy(); }
      this.createPalette();
      return this.render();
    }

    onCodeBankCloseBtnClick() {
      $('.code-bank-left-arrow,.code-bank-right-arrow').toggleClass('hide');
      if ($('#spell-palette-view').hasClass('open')) {
        $('#spell-palette-view').removeClass('open expand');
        return $('#spell-palette-view .container').css('display','none');
      } else {
        $('#spell-palette-view').addClass('open expand');
        $('#spell-palette-view .container').css('display','block');
        if (!$('.sub-section-header.selected').length) {
          $('.sub-section-header').first().click();
          return $('.spell-palette-entry-view').first().click();
        }
      }
    }

    onSubSectionHeaderClick(e) {
      const $et = this.$(e.currentTarget);
      const target = this.$($et.attr('data-panel'));
      const isCollapsed = !target.hasClass('in');
      if (isCollapsed) {
        target.collapse('show');
        $et.find('.shepherd-button').removeClass('shepherd-next-button-active').addClass('shepherd-back-button-active');
        $et.toggleClass('selected', true);
      } else {
        target.collapse('hide');
        $et.find('.shepherd-button').removeClass('shepherd-next-back-active').addClass('shepherd-next-button-active');
        $et.toggleClass('selected', false);
      }

      setTimeout(() => {
        return this.$('.nano').nanoScroller({alwaysVisible: true});
      }
      , 200);
      return e.preventDefault();
    }

    onPaletteClick(e) {
      this.$el.addClass('expand');
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
        aceEditor.renderer.setShowGutter(true);
        return aceEditors.push(aceEditor);
      });
    }

    onTransitionEnd(e) {
      return store.dispatch('game/toggleCodeBank');
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

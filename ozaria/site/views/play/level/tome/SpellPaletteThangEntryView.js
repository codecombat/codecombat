/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteThangEntryView;
const CocoView = require('views/core/CocoView');
const template = require('templates/play/level/tome/spell-palette-thang-entry');
const popoverTemplate = require('ozaria/site/templates/play/level/tome/spell_palette_entry_popover');
const {me} = require('core/auth');
const filters = require('lib/image_filter');
const DocFormatter = require('./DocFormatter');
const utils = require('core/utils');

module.exports = (SpellPaletteThangEntryView = (function() {
  SpellPaletteThangEntryView = class SpellPaletteThangEntryView extends CocoView {
    static initClass() {
      this.prototype.tagName = 'div';  // Could also try <code> instead of <div>, but would need to adjust colors
      this.prototype.className = 'spell-palette-thang-entry-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'surface:frame-changed': 'onFrameChanged',
        'tome:palette-hovered': 'onPaletteHovered',
        'tome:palette-clicked': 'onPaletteClicked',
        'tome:spell-debug-property-hovered': 'onSpellDebugPropertyHovered'
      };

      this.prototype.events = {
        'mouseenter': 'onMouseEnter',
        'mouseleave': 'onMouseLeave',
        'click': 'onClick'
      };
    }

    constructor(options) {
      super(options);
      let example;
      this.onPaletteClicked = this.onPaletteClicked.bind(this);
      this.onClick = this.onClick.bind(this);
      this.thang = options.thang;
      if (options.doc.example != null) {
        example = options.doc.example != null ? options.doc.example[options.language] : undefined;
      } else {
        example = `\# usage code \ngame.spawnXY(\"${options.buildableName}\", 21, 20)`;
      }
      const description = utils.i18n(options.doc, 'description');
      const translatedName = utils.i18n(options.doc, 'name');
      this.doc = {
        name: options.buildableName,
        initialHTML: popoverTemplate({_, marked, doc: {
          shortName: options.doc.name,
          translatedShortName: translatedName !== options.doc.name ? translatedName : undefined,
          type: "spawnable",
          description: `![${this.thang.get('name')}](${this.thang.getPortraitURL()}) ${description}`,
          example
        }
        }),
        example,
        section: options.section,
        subSection: options.subSection
      };
    }

      //@aceEditors = []

    afterRender() {
      return super.afterRender();
    }
      //@$el.addClass _.string.slugify @doc.type

    resetPopoverContent() {}
      //@$el.data('bs.popover').options.content = @docFormatter.formatPopover()
      //@$el.popover('setContent')

    onMouseEnter(e) {
      if (this.popoverPinned || this.otherPopoverPinned) { return; }
    }
      //@resetPopoverContent()
      //@$el.popover 'show'

    onMouseLeave(e) {}
      //@$el.popover 'hide' unless @popoverPinned or @otherPopoverPinned


    onPaletteClicked(e) {
      return this.$el.toggleClass('selected', e.prop === this.doc.name);
    }

    onClick(e) {
      if (key.shift) {
        Backbone.Mediator.publish('tome:insert-snippet', {doc: this.options.doc, language: this.options.language, formatted: this.doc});
        return;
      }
      return Backbone.Mediator.publish('tome:palette-clicked', {thang: this.thang, prop: this.doc.name, entry: this});
    }

    onFrameChanged(e) {}
      //return unless e.selectedThang?.id is @thang.id
      //@options.thang = @thang = @docFormatter.options.thang = e.selectedThang  # Update our thang to the current version

    onPaletteHovered(e) {
      if (e.entry === this) { return; }
    }

    onSpellDebugPropertyHovered(e) {
      const matched = (e.property === this.doc.name) && (e.owner === this.doc.owner);
      if (matched && !this.debugHovered) {
        this.debugHovered = true;
        if (!this.popoverPinned) { this.togglePinned(); }
      } else if (this.debugHovered && !matched) {
        this.debugHovered = false;
        if (this.popoverPinned) { this.togglePinned(); }
      }
      return null;
    }

    destroy() {
      this.$el.off();
      for (var oldEditor of Array.from(this.aceEditors)) { oldEditor.destroy(); }
      return super.destroy();
    }
  };
  SpellPaletteThangEntryView.initClass();
  return SpellPaletteThangEntryView;
})());

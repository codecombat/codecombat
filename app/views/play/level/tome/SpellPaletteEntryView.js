/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteEntryView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/tome/spell_palette_entry');
const {me} = require('core/auth');
const filters = require('lib/image_filter');
const DocFormatter = require('./DocFormatter');
const ace = require('lib/aceContainer');
const utils = require('core/utils');
const aceUtils = require('core/aceUtils');

module.exports = (SpellPaletteEntryView = (function() {
  SpellPaletteEntryView = class SpellPaletteEntryView extends CocoView {
    static initClass() {
      this.prototype.tagName = 'div';  // Could also try <code> instead of <div>, but would need to adjust colors
      this.prototype.className = 'spell-palette-entry-view';
      this.prototype.template = template;
      this.prototype.popoverPinned = false;
      this.prototype.overridePopoverTemplate = '<div class="popover spell-palette-popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>';

      this.prototype.subscriptions = {
        'surface:frame-changed': 'onFrameChanged',
        'tome:palette-hovered': 'onPaletteHovered',
        'tome:palette-clicked': 'onPaletteClicked',
        'tome:palette-pin-toggled': 'onPalettePinToggled',
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
      this.onPaletteClicked = this.onPaletteClicked.bind(this);
      this.onClick = this.onClick.bind(this);
      this.thang = options.thang;
      this.docFormatter = new DocFormatter(options);
      this.doc = this.docFormatter.doc;
      this.doc.initialHTML = this.docFormatter.formatPopover();
      this.doc.docFormatter = this.docFormatter;  // For Blockly tooltips to use
      this.aceEditors = [];
    }

    afterRender() {
      super.afterRender();
      this.$el.addClass(_.string.slugify(this.doc.type));
      if (this.options.spellPalettePosition === 'mid') { return; }
      const placement = function() { if ($('body').hasClass('dialogue-view-active')) { return 'top'; } else { return 'left'; } };
      return this.$el.popover({
        animation: false,
        html: true,
        placement,
        trigger: 'manual',  // Hover, until they click, which will then pin it until unclick.
        content: this.docFormatter.formatPopover(),
        container: 'body',
        template: this.overridePopoverTemplate
      }).on('shown.bs.popover', () => {
        Backbone.Mediator.publish('tome:palette-hovered', {thang: this.thang, prop: this.doc.name, entry: this});
        const soundIndex = Math.floor(Math.random() * 4);
        this.playSound(`spell-palette-entry-open-${soundIndex}`, 0.75);
        return this.afterRenderPopover();
      });
    }

    // NOTE: This can't be run twice without resetting the popover content HTML
    //       in between. If you do, Ace will break.
    afterRenderPopover() {
      const popover = this.$el.data('bs.popover');
      __guard__(popover != null ? popover.$tip : undefined, x => x.i18n());
      const codeLanguage = this.options.language;
      for (var oldEditor of Array.from(this.aceEditors)) { oldEditor.destroy(); }
      this.aceEditors = [];
      const {
        aceEditors
      } = this;
      // Initialize Ace for each popover code snippet that still needs it
      return __guard__(popover != null ? popover.$tip : undefined, x1 => x1.find('.docs-ace').each(function() {
        const aceEditor = aceUtils.initializeACE(this, codeLanguage);
        return aceEditors.push(aceEditor);
      }));
    }

    resetPopoverContent() {
      if (this.options.spellPalettePosition === 'mid') { return; }
      this.$el.data('bs.popover').options.content = this.docFormatter.formatPopover();
      return this.$el.popover('setContent');
    }

    onMouseEnter(e) {
      if (this.options.spellPalettePosition === 'mid') { return; }
      if (this.popoverPinned || this.otherPopoverPinned) { return; }
      this.resetPopoverContent();
      return this.$el.popover('show');
    }

    onMouseLeave(e) {
      if (this.options.spellPalettePosition === 'mid') { return; }
      if (!this.popoverPinned && !this.otherPopoverPinned) { return this.$el.popover('hide'); }
    }

    togglePinned() {
      if (this.options.spellPalettePosition === 'mid') { return; }
      if (this.popoverPinned) {
        this.popoverPinned = false;
        this.$el.add('.spell-palette-popover.popover').removeClass('pinned');
        $('.spell-palette-popover.popover .close').remove();
        this.$el.popover('hide');
        this.playSound('spell-palette-entry-unpin');
      } else {
        this.popoverPinned = true;
        this.resetPopoverContent();
        this.$el.add('.spell-palette-popover.popover').addClass('pinned');
        this.$el.popover('show');
        const x = $('<button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button>');
        $('.spell-palette-popover.popover').append(x);
        x.on('click', this.onClick);
        this.playSound('spell-palette-entry-pin');
      }
      return Backbone.Mediator.publish('tome:palette-pin-toggled', {entry: this, pinned: this.popoverPinned});
    }

    onPaletteClicked(e) {
      return this.$el.toggleClass('selected', e.prop === this.doc.name);
    }

    onClick(e) {
      if (key.shift) {
        Backbone.Mediator.publish('tome:insert-snippet', {doc: this.options.doc, language: this.options.language, formatted: this.doc});
        return;
      }
      this.togglePinned();
      return Backbone.Mediator.publish('tome:palette-clicked', {thang: this.thang, prop: this.doc.name, entry: this});
    }

    onFrameChanged(e) {
      if ((e.selectedThang != null ? e.selectedThang.id : undefined) !== (this.thang != null ? this.thang.id : undefined)) { return; }
      return this.options.thang = (this.thang = (this.docFormatter.options.thang = e.selectedThang));  // Update our thang to the current version
    }

    onPaletteHovered(e) {
      if (e.entry === this) { return; }
      if (this.popoverPinned) { return this.togglePinned(); }
    }

    onPalettePinToggled(e) {
      if (e.entry === this) { return; }
      return this.otherPopoverPinned = e.pinned;
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
      if (this.popoverPinned) { $('.popover.pinned').remove(); }  // @$el.popover('destroy') doesn't work
      if (this.popoverPinned) { this.togglePinned(); }
      this.$el.popover('destroy');
      this.$el.off();
      for (var oldEditor of Array.from(this.aceEditors)) { oldEditor.destroy(); }
      return super.destroy();
    }
  };
  SpellPaletteEntryView.initClass();
  return SpellPaletteEntryView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
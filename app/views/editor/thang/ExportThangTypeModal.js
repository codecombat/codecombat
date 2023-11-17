// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ExportThangTypeModal;
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/thang/export-thang-type-modal');
const SpriteExporter = require('lib/sprites/SpriteExporter');

module.exports = (ExportThangTypeModal = (function() {
  ExportThangTypeModal = class ExportThangTypeModal extends ModalView {
    constructor(...args) {
      super(...args);
      this.onSpriteSheetUploaded = this.onSpriteSheetUploaded.bind(this);
    }

    static initClass() {
      this.prototype.id = "export-thang-type-modal";
      this.prototype.template = template;
      this.prototype.plain = true;

      this.prototype.events =
        {'click #save-btn': 'onClickSaveButton'};

      this.prototype.colorMap = {
        red: { hue: 0, saturation: 0.75, lightness: 0.5 },
        blue: { hue: 0.66, saturation: 0.75, lightness: 0.5 },
        green: { hue: 0.33, saturation: 0.75, lightness: 0.5 }
      };
    }

    initialize(options, thangType) {
      this.thangType = thangType;
      this.builder = null;
      return this.getFilename = _.once(this.getFilename);
    }
    getColorLabel() { return this.$('#color-config-select').val(); }
    getColorConfig() {
      const color = this.colorMap[this.getColorLabel()];
      if (color) { return { team: color }; }
      return null;
    }
    getActionNames() { return _.map(this.$('input[name="action"]:checked'), el => $(el).val()); }
    getResolutionFactor() { return parseInt(this.$('#resolution-input').val()) || SPRITE_RESOLUTION_FACTOR; }
    getFilename() { return 'spritesheet-'+_.string.slugify(moment().format())+'.png'; }
    getSpriteType() { return this.$('input[name="sprite-type"]:checked').val(); }

    onClickSaveButton() {
      this.$('.modal-footer button').addClass('hide');
      this.$('.modal-footer .progress').removeClass('hide');
      this.$('input, select').attr('disabled', true);
      const options = {
        resolutionFactor: this.getResolutionFactor(),
        actionNames: this.getActionNames(),
        colorConfig: this.getColorConfig(),
        spriteType: this.getSpriteType()
      };
      this.exporter = new SpriteExporter(this.thangType, options);
      this.exporter.build();
      return this.listenToOnce(this.exporter, 'build', this.onExporterBuild);
    }

    onExporterBuild(e) {
      this.spriteSheet = e.spriteSheet;
      let src = this.spriteSheet._images[0].toDataURL();
      src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+');
      const body = {
        filename: this.getFilename(),
        mimetype: 'image/png',
        path: `db/thang.type/${this.thangType.get('original')}`,
        b64png: src
      };
      return $.ajax('/file', {type: 'POST', data: body, success: this.onSpriteSheetUploaded});
    }

    onSpriteSheetUploaded() {
      let config, label;
      const spriteSheetData = {
        actionNames: this.getActionNames(),
        animations: this.spriteSheet._data,
        frames: (Array.from(this.spriteSheet._frames).map((f) => [
          f.rect.x,
          f.rect.y,
          f.rect.width,
          f.rect.height,
          0,
          f.regX,
          f.regY
        ])),
        image: `db/thang.type/${this.thangType.get('original')}/`+this.getFilename(),
        resolutionFactor: this.getResolutionFactor(),
        spriteType: this.getSpriteType()
      };
      if (config = this.getColorConfig()) {
        spriteSheetData.colorConfig = config;
      }
      if (label = this.getColorLabel()) {
        spriteSheetData.colorLabel = label;
      }
      const spriteSheets = _.clone(this.thangType.get('prerenderedSpriteSheetData') || []);
      spriteSheets.push(spriteSheetData);
      this.thangType.set('prerenderedSpriteSheetData', spriteSheets);
      this.thangType.save();
      return this.listenToOnce(this.thangType, 'sync', this.hide);
    }
  };
  ExportThangTypeModal.initClass();
  return ExportThangTypeModal;
})());

window.SomeModal = module.exports;

// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let VectorIconSetupModal;
require('app/styles/editor/thang/vector-icon-setup-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/thang/vector-icon-setup-modal');

module.exports = (VectorIconSetupModal = (function() {
  VectorIconSetupModal = class VectorIconSetupModal extends ModalView {
    static initClass() {
      this.prototype.id = "vector-icon-setup-modal";
      this.prototype.template = template;
      this.prototype.demoSize = 400;
      this.prototype.plain = true;

      this.prototype.events = {
        'change #container-select': 'onChangeContainer',
        'click #center': 'onClickCenter',
        'click #zero-bounds': 'onClickZeroBounds',
        'click #done-button': 'onClickDone'
      };

      this.prototype.shortcuts = {
        'shift+-'() { return this.incrScale(-0.02); },
        'shift+='() { return this.incrScale(0.02); },
        'up'() { return this.incrRegY(1); },
        'down'() { return this.incrRegY(-1); },
        'left'() { return this.incrRegX(1); },
        'right'() { return this.incrRegX(-1); }
      };
    }

    constructor(options, thangType) {
      super(options);
      this.thangType = thangType;
      const portrait = __guard__(this.thangType.get('actions'), x => x.portrait);
      this.containers = _.keys(__guard__(this.thangType.get('raw'), x1 => x1.containers) || {});
      this.container = (portrait != null ? portrait.container : undefined) || _.last(this.containers);
      this.scale = (portrait != null ? portrait.scale : undefined) || 1;
      this.regX = __guard__(__guard__(portrait != null ? portrait.positions : undefined, x3 => x3.registration), x2 => x2.x) || 0;
      this.regY = __guard__(__guard__(portrait != null ? portrait.positions : undefined, x5 => x5.registration), x4 => x4.y) || 0;
      this.saveChanges();
    }

    saveChanges() {
      let left;
      const actions = _.cloneDeep(((left = this.thangType.get('actions')) != null ? left : {}));
      if (actions.portrait == null) { actions.portrait = {}; }
      actions.portrait.scale = this.scale;
      if (actions.portrait.positions == null) { actions.portrait.positions = {}; }
      actions.portrait.positions.registration = { x: this.regX, y: this.regY };
      actions.portrait.container = this.container;
      this.thangType.set('actions', actions);
      return this.thangType.buildActions();
    }

    afterRender() {
      this.initStage();
      return super.afterRender();
    }

    initStage() {
      if (!this.containers || !this.container) { return; }
      this.stage = this.thangType.getVectorPortraitStage(this.demoSize);
      this.sprite = this.stage.children[0];
      const canvas = $(this.stage.canvas);
      canvas.attr('id', 'resulting-icon');
      this.$el.find('#resulting-icon').replaceWith(canvas);
      return this.updateSpriteProperties();
    }

    onChangeContainer(e) {
      this.container = $(e.target).val();
      this.saveChanges();
      return this.initStage();
    }

    refreshSprite() {
      if (!this.stage) { return; }
      const stage = this.thangType.getVectorPortraitStage(this.demoSize);
      this.stage.removeAllChildren();
      this.stage.addChild(this.sprite = stage.children[0]);
      this.updateSpriteProperties();
      return this.stage.update();
    }

    updateSpriteProperties() {
      this.sprite.scaleX = (this.sprite.scaleY = (this.scale * this.demoSize) / 100);
      this.sprite.regX = this.regX / this.scale;
      this.sprite.regY = this.regY / this.scale;
      return console.log('set to', this.scale, this.regX, this.regY);
    }

    onClickCenter() {
      const containerInfo = this.thangType.get('raw').containers[this.container];
      const {
        b
      } = containerInfo;
      this.regX = b[0];
      this.regY = b[1];
      const maxDimension = Math.max(b[2], b[3]);
      this.scale = 100 / maxDimension;
      if (b[2] > b[3]) {
        this.regY += (b[3] - b[2]) / 2;
      } else {
        this.regX += (b[2] - b[3]) / 2;
      }
      this.regX *= this.scale;
      this.regY *= this.scale;
      this.updateSpriteProperties();
      return this.stage.update();
    }

    incrScale(amount) {
      this.scale += amount;
      this.updateSpriteProperties();
      return this.stage.update();
    }

    incrRegX(amount) {
      this.regX += amount;
      this.updateSpriteProperties();
      return this.stage.update();
    }

    incrRegY(amount) {
      this.regY += amount;
      this.updateSpriteProperties();
      return this.stage.update();
    }

    onClickDone() {
      this.saveChanges();
      this.trigger('done');
      return this.hide();
    }
  };
  VectorIconSetupModal.initClass();
  return VectorIconSetupModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let WorldSelectModal;
require('app/styles/editor/level/modal/world-select-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/modal/world-select-modal');
const Surface = require('lib/surface/Surface');
const ThangType = require('models/ThangType');
const globalVar = require('core/globalVar');

module.exports = (WorldSelectModal = (function() {
  WorldSelectModal = class WorldSelectModal extends ModalView {
    static initClass() {
      this.prototype.id = 'world-select-modal';
      this.prototype.template = template;
      this.prototype.modalWidthPercent = 80;
      this.prototype.cache = false;

      this.prototype.subscriptions = {
        'surface:choose-region': 'selectionMade',
        'surface:choose-point': 'selectionMade'
      };

      this.prototype.events =
        {'click #done-button': 'done'};

      this.prototype.shortcuts =
        {'enter': 'done'};
    }

    constructor(options) {
      super();
      this.getRenderData = this.getRenderData.bind(this);
      this.selectionMade = this.selectionMade.bind(this);
      this.done = this.done.bind(this);
      this.world = options.world;
      this.dataType = options.dataType || 'point';
      this.default = options.default;
      this.defaultFromZoom = options.defaultFromZoom;
      this.selectionMade = _.debounce(this.selectionMade, 300);
      this.supermodel = options.supermodel;
    }

    getRenderData(c) {
      if (c == null) { c = {}; }
      c = super.getRenderData(c);
      c.selectingPoint = this.dataType === 'point';
      c.flexibleRegion = this.dataType === 'region';
      return c;
    }

    afterInsert() {
      super.afterInsert();
      return this.initSurface();
    }

    // surface setup

    initSurface() {
      const webGLCanvas = this.$el.find('.webgl-canvas');
      const normalCanvas = this.$el.find('.normal-canvas');
      const canvases = webGLCanvas.add(normalCanvas);
      canvases.attr('width', (globalVar.currentView.$el.width()*.8)-70);
      canvases.attr('height', globalVar.currentView.$el.height()*.6);
      this.surface = new Surface(this.world, normalCanvas, webGLCanvas, {
        paths: false,
        grid: true,
        navigateToSelection: false,
        choosing: this.dataType,
        coords: true,
        thangTypes: this.supermodel.getModels(ThangType),
        showInvisible: true
      });
      this.surface.playing = false;
      this.surface.setWorld(this.world);
      this.surface.camera.zoomTo({x: 262, y: -164}, 1.66, 0);
      return this.showDefaults();
    }

    showDefaults() {
      // show current point, and zoom to it
      if (this.dataType === 'point') {
        if ((this.default != null) && _.isFinite(this.default.x) && _.isFinite(this.default.y)) {
          this.surface.chooser.setPoint(this.default);
          return this.surface.camera.zoomTo(this.surface.camera.worldToSurface(this.default), 2);
        }

      } else if (this.defaultFromZoom != null) {
        this.showZoomRegion();
        const surfaceTarget = this.surface.camera.worldToSurface(this.defaultFromZoom.target);
        return this.surface.camera.zoomTo(surfaceTarget, this.defaultFromZoom.zoom*0.6);

      } else if ((this.default != null) && _.isFinite(this.default[0].x) && _.isFinite(this.default[0].y) && _.isFinite(this.default[1].x) && _.isFinite(this.default[1].y)) {
        this.surface.chooser.setRegion(this.default);
        return this.showBoundaryRegion();
      }
    }

    showZoomRegion() {
      const d = this.defaultFromZoom;
      const canvasWidth = 924;  // Dimensions for canvas player. Need these somewhere.
      const canvasHeight = 589;
      let dimensions = {x: canvasWidth/d.zoom, y: canvasHeight/d.zoom};
      dimensions = this.surface.camera.surfaceToWorld(dimensions);
      const width = dimensions.x;
      const height = dimensions.y;
      const {
        target
      } = d;
      const region = [
        {x: target.x - (width/2), y: target.y - (height/2)},
        {x: target.x + (width/2), y: target.y + (height/2)}
      ];
      return this.surface.chooser.setRegion(region);
    }

    showBoundaryRegion() {
      const bounds = this.surface.camera.normalizeBounds(this.default);
      const point = {
        x: bounds.x + (bounds.width / 2),
        y: bounds.y + (bounds.height / 2)
      };
      const zoom = 0.8 * (this.surface.camera.canvasWidth / bounds.width);
      return this.surface.camera.zoomTo(point, zoom);
    }

    // event handlers

    selectionMade(e) {
      e.camera = this.surface.camera;
      return this.lastSelection = e;
    }

    done() {
      if (typeof this.callback === 'function') {
        this.callback(this.lastSelection);
      }
      return this.hide();
    }

    onHidden() {
      return (this.surface != null ? this.surface.destroy() : undefined);
    }
  };
  WorldSelectModal.initClass();
  return WorldSelectModal;
})());

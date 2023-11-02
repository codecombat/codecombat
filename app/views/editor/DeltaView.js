// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DeltaView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/delta');
const deltasLib = require('core/deltas');
const modelDeltas = require('lib/modelDeltas');
const jsondiffpatch = require('lib/jsondiffpatch');
const diffview = require('exports-loader?diffview!vendor/scripts/diffview');
require('vendor/styles/diffview.css');
const difflib = require('exports-loader?difflib!vendor/scripts/difflib');
require('lib/setupTreema');

const TEXTDIFF_OPTIONS = {
  baseTextName: "Old",
  newTextName: "New",
  contextSize: 5,
  viewType: 1
};

module.exports = (DeltaView = (function() {
  DeltaView = class DeltaView extends CocoView {
    static initClass() {
  
      /*
      Takes a CocoModel instance (model) and displays changes since the
      last save (attributes vs _revertAttributes).
  
      * If headModel is included, will look for and display conflicts with the changes in model.
      * If comparisonModel is included, will show deltas between model and comparisonModel instead
        of changes within model itself.
  
      */
  
      this.deltaCounter = 0;
      this.prototype.className = 'delta-view';
      this.prototype.template = template;
      this.prototype.maxDeltas = 50;
    }

    constructor(options) {
      super(options);
      this.expandedDeltas = [];
      this.skipPaths = options.skipPaths;
      if (key.shift && key.alt) {
        this.maxDeltas = 1e9;
      } else if (key.shift) {
        this.maxDeltas = 1000;
      }

      for (var modelName of ['model', 'headModel', 'comparisonModel']) {
        this[modelName] = options[modelName];
        if (!this[modelName] || !options.loadModels) { continue; }
        if (!this[modelName].isLoaded) {
          this[modelName] = this.supermodel.loadModel(this[modelName]).model;
        }
      }

      if (this.supermodel.finished()) { this.buildDeltas(); }
    }

    onLoaded() {
      this.buildDeltas();
      return super.onLoaded();
    }

    buildDeltas() {
      if (this.comparisonModel) {
        this.expandedDeltas = modelDeltas.getExpandedDeltaWith(this.model, this.comparisonModel);
        this.deltas = modelDeltas.getDeltaWith(this.model, this.comparisonModel);
      } else {
        this.expandedDeltas = modelDeltas.getExpandedDelta(this.model);
        this.deltas = modelDeltas.getDelta(this.model);
      }
      [this.expandedDeltas, this.skippedDeltas] = Array.from(this.filterDeltas(this.expandedDeltas));

      if (this.headModel) {
        this.headDeltas = modelDeltas.getExpandedDelta(this.headModel);
        this.headDeltas = this.filterDeltas(this.headDeltas)[0];
        return this.conflicts = deltasLib.getConflicts(this.headDeltas, this.expandedDeltas);
      }
    }

    filterDeltas(deltas) {
      if (!this.skipPaths) { return [deltas, []]; }
      for (let i = 0; i < this.skipPaths.length; i++) {
        var path = this.skipPaths[i];
        if (_.isString(path)) { this.skipPaths[i] = [path]; }
      }
      const newDeltas = [];
      const skippedDeltas = [];
      for (var delta of Array.from(deltas)) {
        var skip = false;
        for (var skipPath of Array.from(this.skipPaths)) {
          if (_.isEqual(_.first(delta.dataPath, skipPath.length), skipPath)) {
            skip = true;
            break;
          }
        }
        if (skip) { skippedDeltas.push(delta); } else { newDeltas.push(delta); }
      }
      return [newDeltas, skippedDeltas];
    }

    afterRender() {
      let deltaData, deltaEl, i;
      let delta;
      const expertView = this.$el.find('.expert-view');
      if (expertView) {
        expertView.html(jsondiffpatch.formatters.html.format(this.deltas));
      }

      DeltaView.deltaCounter += this.expandedDeltas.length;
      const deltas = this.$el.find('.details');
      for (i = 0; i < deltas.length; i++) {
        delta = deltas[i];
        deltaEl = $(delta);
        deltaData = this.expandedDeltas[i];
        if (i < this.maxDeltas) {
          this.expandDetails(deltaEl, deltaData);
        }
      }

      const conflictDeltas = this.$el.find('.conflict-details');
      const conflicts = ((() => {
        const result = [];
        for (delta of Array.from(this.expandedDeltas)) {           if (delta.conflict) {
            result.push(delta.conflict);
          }
        }
        return result;
      })());
      return (() => {
        const result1 = [];
        for (i = 0; i < conflictDeltas.length; i++) {
          delta = conflictDeltas[i];
          deltaEl = $(delta);
          deltaData = conflicts[i];
          if (i < this.maxDeltas) {
            result1.push(this.expandDetails(deltaEl, deltaData));
          } else {
            result1.push(undefined);
          }
        }
        return result1;
      })();
    }

    expandDetails(deltaEl, deltaData) {
      let error, leftEl, options, rightEl;
      const treemaOptions = { schema: deltaData.schema || {}, readOnly: true };

      if (_.isObject(deltaData.left) && (leftEl = deltaEl.find('.old-value'))) {
        options = _.defaults({data: _.merge({}, deltaData.left)}, treemaOptions);
        try {
          TreemaNode.make(leftEl, options).build();
        } catch (error1) {
          error = error1;
          console.error("Couldn't show left details Treema for", deltaData.left, treemaOptions);
        }
      }

      if (_.isObject(deltaData.right) && (rightEl = deltaEl.find('.new-value'))) {
        options = _.defaults({data: _.merge({}, deltaData.right)}, treemaOptions);
        try {
          TreemaNode.make(rightEl, options).build();
        } catch (error2) {
          error = error2;
          console.error("Couldn't show right details Treema for", deltaData.right, treemaOptions);
        }
      }

      if (deltaData.action === 'text-diff') {
        if ((deltaData.left == null) || (deltaData.right == null)) { return console.error(`Couldn't show diff for left: ${deltaData.left}, right: ${deltaData.right} of delta:`, deltaData); }
        const left = difflib.stringAsLines(deltaData.left);
        const right = difflib.stringAsLines(deltaData.right);
        const sm = new difflib.SequenceMatcher(left, right);
        const opcodes = sm.get_opcodes();
        const el = deltaEl.find('.text-diff');
        options = {baseTextLines: left, newTextLines: right, opcodes};
        const args = _.defaults(options, TEXTDIFF_OPTIONS);
        return el.append(diffview.buildView(args));
      }
    }

    getApplicableDelta() {
      let delta = modelDeltas.getDelta(this.model);
      if (this.conflicts) { delta = deltasLib.pruneConflictsFromDelta(delta, this.conflicts); }
      if (this.skippedDeltas) { delta = deltasLib.pruneExpandedDeltasFromDelta(delta, this.skippedDeltas); }
      return delta;
    }
  };
  DeltaView.initClass();
  return DeltaView;
})());

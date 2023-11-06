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
let PatchesView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/patches');
const PatchesCollection = require('collections/PatchesCollection');
const nameLoader = require('core/NameLoader');
const PatchModal = require('./PatchModal');

module.exports = (PatchesView = (function() {
  PatchesView = class PatchesView extends CocoView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.className = 'patches-view';
      this.prototype.status = 'pending';

      this.prototype.events = {
        'change .status-buttons': 'onStatusButtonsChanged',
        'click .patch-row': 'openPatchModal'
      };
    }

    constructor(model, options) {
      super(options);
      this.model = model;
      this.initPatches();
    }

    initPatches() {
      this.startedLoading = false;
      return this.patches = this.model.fetchPatchesWithStatus();
    }

    load() {
      this.initPatches();
      this.patches = this.model.fetchPatchesWithStatus(this.status, {cache: false});
      this.supermodel.trackCollection(this.patches);
      return this.listenTo(this.patches, 'sync', this.onPatchesLoaded);
    }

    onPatchesLoaded() {
      const ids = (Array.from(this.patches.models).map((p) => p.get('creator')));
      const jqxhrOptions = nameLoader.loadNames(ids);
      if (jqxhrOptions) { return this.supermodel.addRequestResource('user_names', jqxhrOptions).load(); }
    }

    getRenderData() {
      const c = super.getRenderData();
      for (var patch of Array.from(this.patches.models)) { patch.userName = nameLoader.getName(patch.get('creator')); }
      c.patches = this.patches.models;
      c.status;
      return c;
    }

    afterRender() {
      this.$el.find(`.${this.status}`).addClass('active');
      return super.afterRender();
    }

    onStatusButtonsChanged(e) {
      this.status = $(e.target).val();
      return this.reloadPatches();
    }

    reloadPatches() {
      this.supermodel.resetProgress();
      this.load();
      return this.render();
    }

    openPatchModal(e) {
      const row = $(e.target).closest('.patch-row');
      const patch = _.find(this.patches.models, {id: row.data('patch-id')});
      const modal = new PatchModal(patch, this.model);
      this.openModalView(modal);
      this.listenTo(modal, 'accepted-patch', function(attrs) { return this.trigger('accepted-patch', attrs); });
      return this.listenTo(modal, 'hide', function() {
        const f = () => this.reloadPatches();
        setTimeout(f, 400);
        return this.stopListening(modal);
      });
    }
  };
  PatchesView.initClass();
  return PatchesView;
})());

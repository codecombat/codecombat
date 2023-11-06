// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let VersionsModal;
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/modal/versions-modal');
const DeltaView = require('views/editor/DeltaView');
const PatchModal = require('views/editor/PatchModal');
const nameLoader = require('core/NameLoader');
const CocoCollection = require('collections/CocoCollection');
const deltasLib = require('core/deltas');

class VersionsViewCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = null;
  }

  initialize(url, levelID, model) {
    this.url = url;
    this.levelID = levelID;
    this.model = model;
    super.initialize();
    return this.url = this.url + this.levelID + '/versions';
  }
}
VersionsViewCollection.initClass();

module.exports = (VersionsModal = (function() {
  VersionsModal = class VersionsModal extends ModalView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.modalWidthPercent = 80;

      // needs to be overwritten by child
      this.prototype.id = '';
      this.prototype.url = '';
      this.prototype.page = '';

      this.prototype.events =
        {'change input.select': 'onSelectionChanged'};
    }

    constructor(options, ID, model) {
      super(options);
      this.ID = ID;
      this.model = model;
      this.original = new this.model({_id: this.ID});
      this.original = this.supermodel.loadModel(this.original).model;
      this.listenToOnce(this.original, 'sync', this.onViewSync);
    }

    onViewSync() {
      this.versions = new VersionsViewCollection(this.url, this.original.attributes.original, this.model);
      this.versions = this.supermodel.loadCollection(this.versions, 'versions').model;
      return this.listenTo(this.versions, 'sync', this.onVersionsFetched);
    }

    onVersionsFetched() {
      const ids = (Array.from(this.versions.models).map((p) => p.get('creator')));
      const jqxhrOptions = nameLoader.loadNames(ids);
      if (jqxhrOptions) { return this.supermodel.addRequestResource('user_names', jqxhrOptions).load(); }
    }

    onSelectionChanged() {
      const rows = this.$el.find('input.select:checked');
      const deltaEl = this.$el.find('.delta-view');
      if (this.deltaView) { this.removeSubView(this.deltaView); }
      this.deltaView = null;
      if (rows.length !== 2) { return; }

      const laterVersion = new this.model({_id: $(rows[0]).val()});
      const earlierVersion = new this.model({_id: $(rows[1]).val()});
      this.deltaView = new DeltaView({
        model: earlierVersion,
        comparisonModel: laterVersion,
        skipPaths: deltasLib.DOC_SKIP_PATHS,
        loadModels: true
      });
      return this.insertSubView(this.deltaView, deltaEl);
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.page = this.page;
      if (this.versions) {
        context.dataList = (Array.from(this.versions.models).map((m) => m.attributes));
        for (var version of Array.from(context.dataList)) {
          version.creator = nameLoader.getName(version.creator);
        }
      }
      return context;
    }
  };
  VersionsModal.initClass();
  return VersionsModal;
})());

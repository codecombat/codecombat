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
let ResourceEditView;
require('app/styles/editor/resource/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/resource/edit');
const ResourceHubResource = require('models/ResourceHubResource');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (ResourceEditView = (function() {
  ResourceEditView = class ResourceEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-resource-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options, resourceID) {
      super(options);
      this.resourceID = resourceID;
      this.resource = new ResourceHubResource({_id: this.resourceID});
      this.resource.saveBackups = true;
      this.supermodel.loadModel(this.resource);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.resource, 'change', () => {
        this.resource.updateI18NCoverage();
        return this.treema.set('/', this.resource.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.resource.loaded)) { return; }
      const data = $.extend(true, {}, this.resource.attributes);
      const options = {
        data,
        filePath: `db/resource_hub_resource/${this.resource.get('_id')}`,
        schema: ResourceHubResource.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel
      };
      this.treema = this.$el.find('#resource-treema').treema(options);
      this.treema.build();
      return (this.treema.childrenTreemas.rewards != null ? this.treema.childrenTreemas.rewards.open(3) : undefined);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.resource), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    onPopulateI18N() {
      return this.resource.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.resource.set(key, value);
      }
      this.resource.updateI18NCoverage();

      const res = this.resource.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/resource/${this.resource.get('slug') || this.resource.id}`;
        return document.location.href = url;
      });
    }
  };
  ResourceEditView.initClass();
  return ResourceEditView;
})());

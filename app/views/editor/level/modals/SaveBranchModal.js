// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SaveBranchModal;
require('app/styles/editor/level/modal/save-branch-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/modal/save-branch-modal');
const DeltaView = require('views/editor/DeltaView');
const deltasLib = require('core/deltas');
let modelDeltas = require('lib/modelDeltas');
const Branch = require('models/Branch');
const Branches = require('collections/Branches');
const LevelComponents = require('collections/LevelComponents');
const LevelSystems = require('collections/LevelSystems');
modelDeltas = require('lib/modelDeltas');


module.exports = (SaveBranchModal = (function() {
  SaveBranchModal = class SaveBranchModal extends ModalView {
    static initClass() {
      this.prototype.id = 'save-branch-modal';
      this.prototype.template = template;
      this.prototype.modalWidthPercent = 99;
      this.prototype.events = {
        'click #save-branch-btn': 'onClickSaveBranchButton',
        'click #branches-list-group .list-group-item': 'onClickBranch',
        'click .delete-branch-btn': 'onClickDeleteBranchButton',
        'click #stash-branch-btn': 'onClickStashBranchButton'
      };
    }

    initialize({ components, systems }) {
      // Should be given all loaded, up to date systems and components with existing changes

      // Create a list of components and systems we'll be saving a branch for
      this.components = components;
      this.systems = systems;
      this.componentsWithChanges = new LevelComponents(this.components.filter(c => c.hasLocalChanges()));
      this.systemsWithChanges = new LevelSystems(this.systems.filter(c => c.hasLocalChanges()));

      // Load existing branches
      this.branches = new Branches();
      return this.branches.fetch({url: '/db/branches'})
      .then(() => {

        // Load any patch target we don't already have
        const fetches = [];
        for (var branch of Array.from(this.branches.models)) {
          for (var patch of Array.from(branch.get('patches') || [])) {
            var collection = patch.target.collection === 'level_component' ? this.components : this.systems;
            var model = collection.get(patch.target.id);
            if (!model) {
              model = new collection.model({ _id: patch.target.id });
              fetches.push(model.fetch());
              model.once('sync', function() { return this.markToRevert(); });
              collection.add(model);
            }
          }
        }
        return $.when(...Array.from(fetches || []));

      }).then(() => {

        // Go through each branch and make clones of patch targets, with patches applied, so we can show the deltas
        for (var branch of Array.from(this.branches.models)) {
          branch.components = new Backbone.Collection();
          branch.systems = new Backbone.Collection();
          for (var patch of Array.from(branch.get('patches') || [])) {
            var allModels, changedModels;
            patch.id = _.uniqueId();
            if (patch.target.collection === 'level_component') {
              allModels = this.components;
              changedModels = branch.components;
            } else {
              allModels = this.systems;
              changedModels = branch.systems;
            }
            var model = allModels.get(patch.target.id).clone(false);
            model.markToRevert();
            modelDeltas.applyDelta(model, patch.delta);
            changedModels.add(model);
          }
        }
        this.selectedBranch = this.branches.first();
        return this.render();
      });
    }

    afterRender() {
      let changeEl;
      super.afterRender();
      this.renderSelectedBranch();

      // insert all the Delta views for the systems/components which will form the branch
      let changeEls = this.$el.find('.component-changes-stub');
      for (changeEl of Array.from(changeEls)) {
        var componentId = $(changeEl).data('component-id');
        var component = this.componentsWithChanges.find(c => c.id === componentId);
        this.insertDeltaView(component, changeEl);
      }

      changeEls = this.$el.find('.system-changes-stub');
      return (() => {
        const result = [];
        for (changeEl of Array.from(changeEls)) {
          var systemId = $(changeEl).data('system-id');
          var system = this.systemsWithChanges.find(c => c.id === systemId);
          result.push(this.insertDeltaView(system, changeEl));
        }
        return result;
      })();
    }

    insertDeltaView(model, changeEl, headModel) {
      try {
        const deltaView = new DeltaView({model, headModel, skipPaths: deltasLib.DOC_SKIP_PATHS});
        this.insertSubView(deltaView, $(changeEl));
        return deltaView;
      } catch (e) {
        return console.error('Couldn\'t create delta view:', e);
      }
    }

    renderSelectedBranch() {
      // insert delta subviews for the selected branch, including the 'headComponent' which shows
      // what, if any, conflicts the existing branch has with the client's local changes

      let changeEl, preBranchSave;
      if (this.selectedBranchDeltaViews) { for (var view of Array.from(this.selectedBranchDeltaViews)) { this.removeSubView(view); } }
      this.selectedBranchDeltaViews = [];
      this.renderSelectors('#selected-branch-col');
      let changeEls = this.$el.find('#selected-branch-col .component-changes-stub');
      for (changeEl of Array.from(changeEls)) {
        var componentId = $(changeEl).data('component-id');
        var component = this.selectedBranch.components.get(componentId);
        var targetComponent = this.components.find(c => (c.get('original') === component.get('original')) && c.get('version').isLatestMajor);
        preBranchSave = component.clone();
        preBranchSave.markToRevert();
        var componentDiff = targetComponent.clone();
        preBranchSave.set(componentDiff.attributes);
        this.selectedBranchDeltaViews.push(this.insertDeltaView(preBranchSave, changeEl));
      }

      changeEls = this.$el.find('#selected-branch-col .system-changes-stub');
      return (() => {
        const result = [];
        for (changeEl of Array.from(changeEls)) {
          var systemId = $(changeEl).data('system-id');
          var system = this.selectedBranch.systems.get(systemId);
          var targetSystem = this.systems.find(c => (c.get('original') === system.get('original')) && c.get('version').isLatestMajor);
          preBranchSave = system.clone();
          preBranchSave.markToRevert();
          var systemDiff = targetSystem.clone();
          preBranchSave.set(systemDiff.attributes);
          result.push(this.selectedBranchDeltaViews.push(this.insertDeltaView(preBranchSave, changeEl)));
        }
        return result;
      })();
    }

    onClickBranch(e) {
      $(e.currentTarget).closest('.list-group').find('.active').removeClass('active');
      $(e.currentTarget).addClass('active');
      const branchCid = $(e.currentTarget).data('branch-cid');
      this.selectedBranch = branchCid ? this.branches.get(branchCid) : null;
      return this.renderSelectedBranch();
    }

    onClickStashBranchButton(e) {
      return this.saveBranch(e, {deleteSavedChanges: true});
    }

    onClickSaveBranchButton(e) {
      return this.saveBranch(e, {deleteSavedChanges: false});
    }

    saveBranch(e, {deleteSavedChanges}) {
      let branch;
      if (this.selectedBranch) {
        branch = this.selectedBranch;
      } else {
        const name = this.$('#new-branch-name-input').val();
        if (!name) {
          return noty({text: 'Name required', layout: 'topCenter', type: 'error', killer: false});
        }
        const slug = _.string.slugify(name);
        if (this.branches.findWhere({slug})) {
          return noty({text: 'Name taken', layout: 'topCenter', type: 'error', killer: false});
        }
        branch = new Branch({name});
      }

      const patches = [];
      const toRevert = [];
      const selectedComponents = _.map(this.$('.component-checkbox:checked'), checkbox => this.componentsWithChanges.get($(checkbox).data('component-id')));
      for (var component of Array.from(selectedComponents)) {
        patches.push(modelDeltas.makePatch(component).toJSON());
        toRevert.push(component);
      }

      const selectedSystems = _.map(this.$('.system-checkbox:checked'), checkbox => this.systemsWithChanges.get($(checkbox).data('system-id')));
      for (var system of Array.from(selectedSystems)) {
        patches.push(modelDeltas.makePatch(system).toJSON());
        toRevert.push(system);
      }
      branch.set({patches});
      const jqxhr = branch.save();
      const button = $(e.currentTarget);
      if (!jqxhr) {
        return button.text('Save Failed (validation error)');
      }

      button.attr('disabled', true).text('Saving...');
      return Promise.resolve(jqxhr)
      .then(() => {
        if (deleteSavedChanges) {
          for (var model of Array.from(toRevert)) { model.revert(); }
        }
        return this.hide();
    }).catch(e => {
        button.attr('disabled', false).text('Save Failed (network/runtime error)');
        throw e;
      });
    }

    onClickDeleteBranchButton(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      const branchCid = $(e.currentTarget).closest('.list-group-item').data('branch-cid');
      const branch = this.branches.get(branchCid);
      if (!confirm('Really delete this branch?')) { return; }
      branch.destroy();
      this.branches.remove(branch);
      if (branch === this.selectedBranch) {
        this.selectedBranch = null;
        this.renderSelectedBranch();
      }
      return $(e.currentTarget).closest('.list-group-item').remove();
    }
  };
  SaveBranchModal.initClass();
  return SaveBranchModal;
})());

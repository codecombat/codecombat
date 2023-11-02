/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LoadBranchModal;
require('app/styles/editor/level/modal/load-branch-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/modal/load-branch-modal');
const DeltaView = require('views/editor/DeltaView');
const deltasLib = require('core/deltas');
const modelDeltas = require('lib/modelDeltas');
const Branch = require('models/Branch');
const Branches = require('collections/Branches');
const LevelComponents = require('collections/LevelComponents');
const LevelSystems = require('collections/LevelSystems');


module.exports = (LoadBranchModal = (function() {
  LoadBranchModal = class LoadBranchModal extends ModalView {
    static initClass() {
      this.prototype.id = 'load-branch-modal';
      this.prototype.template = template;
      this.prototype.modalWidthPercent = 99;
      this.prototype.events = {
        'click #load-branch-btn': 'onClickLoadBranchButton',
        'click #unstash-branch-btn': 'onClickUnstashBranchButton',
        'click #branches-list-group .list-group-item': 'onClickBranch',
        'click .delete-branch-btn': 'onClickDeleteBranchButton'
      };
    }


    initialize({ components, systems }) {
      // Should be given all loaded, up to date systems and components with existing changes

      // Load existing branches
      this.components = components;
      this.systems = systems;
      this.branches = new Branches();
      return this.branches.fetch({url: '/db/branches'})
      .then(() => {
        this.selectedBranch = this.branches.first();

        // Load any patch target we don't already have
        const fetches = [];
        for (var branch of Array.from(this.branches.models)) {
          for (var patch of Array.from(branch.get('patches'))) {
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

        // Go through each branch and figure out what their patch statuses are
        return Array.from(this.branches.models).map((branch) =>
          (() => {
            const result = [];
            for (var patch of Array.from(branch.get('patches'))) {
              patch.id = _.uniqueId();
              var collection = patch.target.collection === 'level_component' ? this.components : this.systems;

              // make a model that represents what the patch represented when it was made
              var originalChange = collection.get(patch.target.id).clone(false);
              originalChange.markToRevert();
              modelDeltas.applyDelta(originalChange, patch.delta);

              // make a model that represents what will change locally
              var currentModel = collection.find(model => _.all([
                model.get('original') === patch.target.original,
                model.get('version').isLatestMajor
              ]));
              var postLoadChange = currentModel.clone();
              postLoadChange.markToRevert(); // includes whatever local changes we have now

              var toApply = currentModel.clone(false);
              var applied = modelDeltas.applyDelta(toApply, patch.delta);
              if (applied) {
                postLoadChange.set(toApply.attributes);
                for (var key of Array.from(postLoadChange.keys())) {
                  if (!toApply.has(key)) {
                    postLoadChange.unset(key);
                  }
                }
              }
                // now postLoadChange has current state -> future state

              // properties used in rendering and loading
              result.push(_.assign(patch, {
                // the original target with patch applied
                originalChange,

                // the current target with local changes removed and patch applied (if successful)
                // Whether the patch was applied or not, this is how the model will be after loading
                postLoadChange,

                // whether applying the patch to the current target was successful
                applied,

                // so we can label this part of the patch as overwriting local changes
                currentModelHasLocalChanges: currentModel.hasLocalChanges(),

                // so we can label changes being applied to a newer version of the model
                modelHasChangedSincePatchCreated: originalChange.id !== currentModel.id,

                // the target model as it was passed into the modal, unchanged
                currentModel
              }));
            }
            return result;
          })());
      }).then(() => this.render());
    }

    afterRender() {
      super.afterRender();
      return this.renderSelectedBranch();
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

      if (this.selectedBranchDeltaViews) { for (var view of Array.from(this.selectedBranchDeltaViews)) { this.removeSubView(view); } }
      this.selectedBranchDeltaViews = [];
      this.renderSelectors('#selected-branch-col');
      if (!this.selectedBranch) { return; }
      return (() => {
        const result = [];
        for (var patch of Array.from(this.selectedBranch.get('patches'))) {
          var originalChangeEl = this.$(`.changes-stub[data-patch-id='${patch.id}'][data-prop='original-change']`);
          this.insertDeltaView(patch.originalChange, originalChangeEl);
          var postLoadChangeEl = this.$(`.changes-stub[data-patch-id='${patch.id}'][data-prop='post-load-change']`);
          result.push(this.insertDeltaView(patch.postLoadChange, postLoadChangeEl));
        }
        return result;
      })();
    }

    onClickBranch(e) {
      $(e.currentTarget).closest('.list-group').find('.active').removeClass('active');
      $(e.currentTarget).addClass('active');
      const branchCid = $(e.currentTarget).data('branch-cid');
      this.selectedBranch = this.branches.get(branchCid);
      return this.renderSelectedBranch();
    }

    onClickUnstashBranchButton(e) {
      return this.loadBranch({deleteBranch: true});
    }

    onClickLoadBranchButton(e) {
      return this.loadBranch({deleteBranch: false});
    }

    loadBranch({deleteBranch}) {
      const selectedBranch = this.$('#branches-list-group .active');
      const branchCid = selectedBranch.data('branch-cid');
      const branch = this.branches.get(branchCid);
      for (var patch of Array.from(branch.get('patches'))) {
        if (!patch.applied) { continue; }
        var { currentModel, postLoadChange } = patch;

        currentModel.set(postLoadChange.attributes);
        for (var key of Array.from(currentModel.keys())) {
          if (!postLoadChange.has(key)) {
            currentModel.unset(key);
          }
        }
      }
      if (deleteBranch) {
        Promise.resolve(branch.destroy()).catch(e => noty({text: 'Failed to delete branch after unstashing', layout: 'topCenter', type: 'error', killer: false}));
      }
      return this.hide();
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
  LoadBranchModal.initClass();
  return LoadBranchModal;
})());

/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PendingPatchesView;
const RootView = require('views/core/RootView');
const template = require('app/templates/admin/pending-patches-view');
const CocoCollection = require('collections/CocoCollection');
const Patch = require('models/Patch');

class PendingPatchesCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '/db/patch?view=pending';
    this.prototype.model = Patch;
  }
}
PendingPatchesCollection.initClass();

module.exports = (PendingPatchesView = (function() {
  PendingPatchesView = class PendingPatchesView extends RootView {
    static initClass() {
      this.prototype.id = 'pending-patches-view';
      this.prototype.template = template;
    }

    constructor(options) {
      super(options);
      this.nameMap = {};
      this.patches = this.supermodel.loadCollection(new PendingPatchesCollection(), 'patches', {cache: false}).model;
    }

    onLoaded() {
      super.onLoaded();
      this.loadUserNames();
      return this.loadAllModelNames();
    }

    getRenderData() {
      let patch;
      const c = super.getRenderData();
      c.patches = [];
      if (this.supermodel.finished()) {
        const comparator = m => m.target.collection + ' ' + m.target.original;
        const patches = _.sortBy(((() => {
          const result = [];
          for (patch of Array.from(this.patches.models)) {             result.push(_.clone(patch.attributes));
          }
          return result;
        })()), comparator);
        c.patches = _.uniq(patches, comparator);
        for (patch of Array.from(c.patches)) {
          var name;
          patch.creatorName = this.nameMap[patch.creator] || patch.creator;
          if (name = this.nameMap[patch.target.original]) {
            patch.name = name;
            patch.slug = _.string.slugify(name);
            patch.url = '/editor/' + (() => { switch (patch.target.collection) {
              case 'level': case 'achievement': case 'article': case 'campaign': case 'poll':
                return `${patch.target.collection}/${patch.slug}`;
              case 'thang_type':
                return `thang/${patch.slug}`;
              case 'level_system': case 'level_component':
                return `level/items?${patch.target.collection}=${patch.slug}`;
              case 'course':
                return `course/${patch.slug}`;
              default:
                console.log(`Where do we review a ${patch.target.collection} patch?`);
                return '';
            } })();
          }
        }
      }
      return c;
    }

    loadUserNames() {
      // Only fetch the names for the userIDs we don't already have in @nameMap
      let patch;
      let ids = [];
      for (patch of Array.from(this.patches.models)) {
        var id;
        if (!(id = patch.get('creator'))) {
          console.error('Found bad user ID in malformed patch', patch);
          continue;
        }
        if (!this.nameMap[id]) { ids.push(id); }
      }
      ids = _.uniq(ids);
      if (!ids.length) { return; }

      const success = nameMap => {
        if (this.destroyed) { return; }
        for (patch of Array.from(this.patches.models)) {
          var creatorID = patch.get('creator');
          if (this.nameMap[creatorID]) { continue; }
          var creator = nameMap[creatorID];
          var name = creator != null ? creator.name : undefined;
          if (creator != null ? creator.firstName : undefined) { if (!name) { name = creator.firstName + ' ' + creator.lastName; } }
          if (creator) { if (!name) { name = `Anonymous ${creatorID.substr(18)}`; } }
          if (!name) { name = '<bad patch data>'; }
          if (name.length > 21) {
            name = name.substr(0, 18) + '...';
          }
          this.nameMap[creatorID] = name;
        }
        return this.render();
      };

      const userNamesRequest = this.supermodel.addRequestResource('user_names', {
        url: '/db/user/-/names',
        data: {ids},
        method: 'POST',
        success
      }, 0);
      return userNamesRequest.load();
    }

    loadAllModelNames() {
      let p;
      let allPatches = ((() => {
        const result = [];
        for (p of Array.from(this.patches.models)) {           result.push(p.attributes);
        }
        return result;
      })());
      allPatches = _.groupBy(allPatches, p => p.target.collection);
      return (() => {
        const result1 = [];
        for (var collection in allPatches) {
          var patches = allPatches[collection];
          result1.push(this.loadCollectionModelNames(collection, patches));
        }
        return result1;
      })();
    }

    loadCollectionModelNames(collection, patches) {
      let patch;
      let ids = ((() => {
        const result = [];
        for (patch of Array.from(patches)) {           if (!this.nameMap[patch.target.original]) {
            result.push(patch.target.original);
          }
        }
        return result;
      })());
      ids = _.uniq(ids);
      if (!ids.length) { return; }
      const success = nameMapArray => {
        if (this.destroyed) { return; }
        const nameMap = {};
        for (let modelIndex = 0; modelIndex < nameMapArray.length; modelIndex++) {
          var model = nameMapArray[modelIndex];
          if (!model) {
            console.warn(`No model found for id ${ids[modelIndex]}`);
            continue;
          }
          nameMap[model.original || model._id] = model.name;
        }
        for (patch of Array.from(patches)) {
          var {
            original
          } = patch.target;
          var name = nameMap[original];
          if (name && (name.length > 60)) {
            name = name.substr(0, 57) + '...';
          }
          this.nameMap[original] = name;
        }
        return this.render();
      };

      const modelNamesRequest = this.supermodel.addRequestResource('patches', {
        url: `/db/${collection.replace('_', '.')}/names`,
        data: {ids},
        method: 'POST',
        success
      }, 0);
      return modelNamesRequest.load();
    }
  };
  PendingPatchesView.initClass();
  return PendingPatchesView;
})());

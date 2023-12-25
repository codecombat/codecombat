/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const factories = require('test/app/factories');
const SaveBranchModal = require('views/editor/level/modals/SaveBranchModal');
const LevelComponents = require('collections/LevelComponents');
const LevelSystems = require('collections/LevelSystems');
const modelDeltas = require('lib/modelDeltas');

const makeBranch = function(attrs, {systems, components}) {
  if (attrs == null) { attrs = {}; }
  const branch = new Branch(attrs);
  const patches = [];
  for (var component of Array.from(components.models)) {
    patches.push(modelDeltas.makePatch(component).toJSON());
  }
  for (var system of Array.from(systems.models)) {
    patches.push(modelDeltas.makePatch(system).toJSON());
  }
  branch.set({patches});
  return branch;
};

describe('SaveBranchModal', () => it('saves a new branch with all local changes to systems and components', function(done) {
  
  // a couple that don't have changes
  const component = factories.makeLevelComponent({name: 'Unchanged Component'});
  const system = factories.makeLevelSystem({name: 'Unchanged System'});
  
  // a couple with changes
  const changedComponent = factories.makeLevelComponent({name: 'Changed Component'});
  const changedSystem = factories.makeLevelSystem({name: 'Changed System'});
  changedComponent.markToRevert();
  changedComponent.set('description', 'new description');
  changedSystem.markToRevert();
  changedSystem.set('description', 'also a new description');
  
  // a component with history
  const componentV0 = factories.makeLevelComponent({
    name: 'Versioned Component',
    version: {
      major: 0,
      minor: 0,
      isLatestMajor: false,
      isLatestMinor: false
    }
  });
  const componentV1 = factories.makeLevelComponent({
    name: 'Versioned Component', 
    original: componentV0.get('original'),
    description:'Recent description change',
    version: {
      major: 0,
      minor: 1,
      isLatestMajor: true,
      isLatestMinor: true
    }
  });
  const componentV0Changed = componentV0.clone();
  componentV0Changed.markToRevert();
  componentV0Changed.set({name: 'Unconflicting change', description: 'Conflicting change'});
  
  const modal = new SaveBranchModal({ 
    components: new LevelComponents([component, changedComponent, componentV1]),
    systems: new LevelSystems([changedSystem, system])
  });
  jasmine.demoModal(modal);
  jasmine.Ajax.requests.mostRecent().respondWith({
    status: 200,
    responseText: JSON.stringify([
      { 
        name: 'First Branch',
        patches: [
          modelDeltas.makePatch(componentV0Changed).toJSON()
        ],
        updatedBy: me.id,
        updatedByName: 'Myself',
        updated: moment().subtract(1, 'day').toISOString()
      },
      {
        name: 'Newer Branch By Someone Else',
        updatedBy: _.uniqueId('user_'),
        updatedByName: 'Someone Else',
        updated: moment().subtract(5, 'hours').toISOString()
      },
      {
        name: 'Older Branch By Me',
        updatedBy: me.id,
        updatedByName: 'Myself',
        updated: moment().subtract(2, 'days').toISOString()
      },
      {
        name: 'Older Branch By Someone Else',
        updatedBy: _.uniqueId('user_'),
        updatedByName: 'Someone Else',
        updated: moment().subtract(1, 'week').toISOString()
      }
    ])
  });
  return _.defer(() => {
    const componentRequest = jasmine.Ajax.requests.mostRecent();
    expect(componentRequest.url).toBe(componentV0.url());
    componentRequest.respondWith({
      status: 200,
      responseText: JSON.stringify(componentV0.toJSON())
    });
    modal.$('#branches-list-group input').val('Branch Name');
    modal.$('#save-branch-btn').click();
    const saveBranchRequest = jasmine.Ajax.requests.mostRecent();
    expect(saveBranchRequest.url).toBe('/db/branches');
    expect(saveBranchRequest.method).toBe('POST');
    const body = JSON.parse(saveBranchRequest.params);
    expect(body.patches.length).toBe(2);
    const targetIds = _.map(body.patches, patch => patch.id);
    expect(_.contains(targetIds, changedComponent.id));
    expect(_.contains(targetIds, changedSystem.id));
    return done();
  });
}));

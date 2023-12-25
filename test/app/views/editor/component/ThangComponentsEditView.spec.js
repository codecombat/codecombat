/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ThangComponentEditView = require('views/editor/component/ThangComponentsEditView');
const SuperModel = require('models/SuperModel');
const LevelComponent = require('models/LevelComponent');

const responses = {
  '/db/level.component/B/version/0': {
    system: 'System',
    original: 'B',
    version: {major: 0, minor:0},
    name: 'B (depends on A)',
    dependencies: [{original:'A', majorVersion: 0}]
  },
  '/db/level.component/A/version/0': {
    system: 'System',
    original: 'A',
    version: {major: 0, minor:0},
    name: 'A',
    configSchema: { type: 'object', properties: { propA: { type: 'number' }, propB: { type: 'string' }} }
  }
};
  
const componentC = new LevelComponent({
  system: 'System',
  original: 'C',
  version: {major: 0, minor:0},
  name: 'C (depends on B)',
  dependencies: [{original:'B', majorVersion: 0}]
});
componentC.loaded = true;

describe('ThangComponentsEditView', function() {
  let view = null;
  
  beforeEach(function(done) {
    const supermodel = new SuperModel();
    supermodel.registerModel(componentC);
    view = new ThangComponentEditView({ components: [], supermodel });
    return _.defer(function() {
      view.render();
      view.componentsTreema.set('/', [ { original: 'C', majorVersion: 0 }]);
      const success = jasmine.Ajax.requests.sendResponses(responses);
      expect(success).toBeTruthy();
      return _.defer(() => done());
    });
  });
  
  afterEach(() => view.destroy());

  it('loads dependencies when you add a component with the left side treema', () => expect(_.size(view.subviews)).toBe(3));
   
  // TODO: Figure out why this is breaking karma but not always
  it('adds dependencies to its components list', function() {
    const componentOriginals = (Array.from(view.components).map((c) => c.original));
    expect(Array.from(componentOriginals).includes('A')).toBeTruthy();
    expect(Array.from(componentOriginals).includes('B')).toBeTruthy();
    return expect(Array.from(componentOriginals).includes('C')).toBeTruthy();
  });
    
  return it('removes components that are dependent on a removed component', function() {
    view.components = (Array.from(view.components).filter((c) => c.original !== 'A'));
    view.onComponentsChanged();
    expect(view.components.length).toBe(0);
    return expect(_.size(view.subviews)).toBe(0);
  });
});

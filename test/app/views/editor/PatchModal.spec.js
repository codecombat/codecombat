/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LevelComponent = require('models/LevelComponent');
const Patch = require('models/Patch');
const modelDeltas = require('lib/modelDeltas');

const PatchModal = require('views/editor/PatchModal');

describe('PatchModal', () => describe('acceptPatch', () => it('triggers LevelComponents and Systems to recompile their code', function() {
  let levelComponent = new LevelComponent({ code: 'newList = (item.prop for item in list)', id: 'id' });
  levelComponent.markToRevert();
  levelComponent.set('code', 'func = -> console.log()');
  const patch = new Patch({delta: modelDeltas.getDelta(levelComponent), target: 'id'});

  levelComponent = new LevelComponent({ code: 'newList = (item.prop for item in list)', id: 'id' });
  levelComponent.markToRevert();
  const patchModal = new PatchModal(patch, levelComponent);
  patchModal.render();
  patchModal.acceptPatch();
  return expect(levelComponent.get('js').indexOf('function()')).toBeGreaterThan(-1);
})));

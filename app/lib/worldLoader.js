/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
module.exports = (window.libWorldRequire = function(path) {
  switch (path) {
    case 'lib/world/systems/action': return require('lib/world/systems/action');
    case 'lib/world/systems/collision': return require('lib/world/systems/collision');
    case 'lib/world/systems/movement': return require('lib/world/systems/movement');
    case 'lib/world/box2d': return require('lib/world/box2d');
    case 'lib/world/GoalManager': return require('lib/world/GoalManager');
    case 'lib/world/Grid': return require('lib/world/Grid');
    case 'lib/world/component': return require('lib/world/component');
    case 'lib/world/ellipse': return require('lib/world/ellipse');
    case 'lib/world/errors': return require('lib/world/errors');
    case 'lib/world/line_segment': return require('lib/world/line_segment');
    case 'lib/world/names': return require('lib/world/names');
    case 'lib/world/rand': return require('lib/world/rand');
    case 'lib/world/rectangle': return require('lib/world/rectangle');
    case 'lib/world/script_event_prereqs': return require('lib/world/script_event_prereqs');
    case 'lib/world/system': return require('lib/world/system');
    case 'lib/world/thang': return require('lib/world/thang');
    case 'lib/world/thang_state': return require('lib/world/thang_state');
    case 'lib/world/vector': return require('lib/world/vector');
    case 'lib/world/world': return require('lib/world/world');
    case 'lib/world/world_frame': return require('lib/world/world_frame');
    case 'lib/world/world_script_note': return require('lib/world/world_script_note');
    case 'lib/world/world_utils': return require('lib/world/world_utils');
    default: throw new Error("Whoops, dunno what you're trying to load but I didn't include it in worldLoader");
  }
});

// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// This temporarily creates a window.createjs attribute
if (window.createjs == null) { window.createjs = {}; }

// TODO: this used to be when we had a bunch of separate scripts. Now with combined 1.0 CreateJS, is it still needed?
import 'imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/createjs';

export default window.createjs;
// delete window.createjs # Don't do this; something needs it to be global.

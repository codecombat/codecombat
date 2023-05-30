let TreemaNode;
const _ = require('lodash');
window.TreemaNode = (TreemaNode = require('exports-loader?TreemaNode!bower_components/treema/treema.js'));
const treemaExt = require('core/treema-ext');
treemaExt.setup(); // This is only run the first time the module is required

module.exports = TreemaNode;

_ = require 'lodash'
window.TreemaNode = TreemaNode = require('exports-loader?TreemaNode!bower_components/treema/treema.js');
treemaExt = require 'core/treema-ext'
treemaExt.setup() # This is only run the first time the module is required

module.exports = TreemaNode

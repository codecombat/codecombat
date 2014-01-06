ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/artisan'
{me} = require('lib/auth')

module.exports = class ArtisanView extends ContributeClassView
  id: "artisan-view"
  template: template
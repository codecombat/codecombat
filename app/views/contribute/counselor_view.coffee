ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/counselor'
{me} = require('lib/auth')

module.exports = class CounselorView extends ContributeClassView
  id: "counselor-view"
  template: template
  contributorClassName: 'counselor'

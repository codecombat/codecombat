require('app/styles/contact-cn.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/contact-cn-view'

module.exports = class ContactCNView extends RootView
  id: 'contact-view'
  template: template

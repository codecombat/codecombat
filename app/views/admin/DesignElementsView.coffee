RootView = require 'views/core/RootView'
template = require 'templates/admin/design-elements-view'

module.exports = class DesignElementsView extends RootView
  id: 'design-elements-view'
  template: template
  
  afterInsert: ->
    super()
    # hack to get hash links to work. Make this general?
    hash = document.location.hash
    document.location.hash = ''
    setTimeout((-> document.location.hash = hash), 10)
    @$('#modal-2').find('.background-wrapper').addClass('plain')
    setTimeout((=> @$('#tooltip').tooltip('show')), 20)
    setTimeout((=> @$('#popover').popover('show')), 20)
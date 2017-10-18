require('app/styles/admin/design-elements-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/admin/design-elements-view'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

module.exports = class DesignElementsView extends RootView
  id: 'design-elements-view'
  template: template
  
  afterInsert: ->
    super()
    # hack to get hash links to work. Make this general?
    hash = document.location.hash
    document.location.hash = ''
    setTimeout((-> document.location.hash = hash), 10)
    
    # modal
    @$('#modal-2').find('.background-wrapper').addClass('plain')

    # tooltips
    @$('[data-toggle="tooltip"]').tooltip({
      title: 'Lorem ipsum'
      trigger: 'click'
    })
    if hash is '#tooltips'
      setTimeout((=> @$('[data-toggle="tooltip"]').tooltip('show')), 20)
      
    # popovers
    if hash is '#popovers'
      setTimeout((=> @$('#popover').popover('show')), 20)
      
    # autocomplete
    tags = [
      "ActionScript", "AppleScript", "Asp", "BASIC", "C", "C++", "Clojure", "COBOL", "ColdFusion", "Erlang",
      "Fortran", "Groovy", "Haskell", "Java", "JavaScript", "Lisp", "Perl", "PHP", "Python", "Ruby", "Scala", "Scheme"
    ]
    @$('#tags').autocomplete({source: tags})
    if hash is '#autocomplete'
      setTimeout((=> @$('#tags').autocomplete("search", "t")), 20)
    
    # slider
    @$('#slider-example').slider()
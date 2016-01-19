CocoView = require 'views/core/CocoView'

module.exports = class NewItemView extends CocoView
  id: 'new-item-view'
  className: 'modal-content' 
  template: require('templates/play/level/modal/new-item-view')
  
  events:
    'click #continue-btn': 'onClickContinueButton'
    
  afterRender: ->
    super()
    # TODO: Animate icon
    
  initialize: (options) ->
    @item = options.item
    super()

  onClickContinueButton: ->
    @trigger 'continue'
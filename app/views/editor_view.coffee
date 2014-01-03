View = require 'views/kinds/RootView'
template = require 'templates/editor'

module.exports = class EditorView extends View
  id: "editor-level-view"
  template: template

  events:
    "click .images img": "onClickImage"
    "click #image-modal": "onClickImageModal"
    
  onClickImage: (e) =>
    imgURL = $(e.target).attr('src')
    img = $('<img></img>').attr('src', imgURL)
    img.addClass('img-polaroid')
    @$el.find('#image-modal .modal-body').empty().append(img)
    @$el.find('#image-modal').modal('show')

  onClickImageModal: (e) =>
    @$el.find('#image-modal').modal('hide')
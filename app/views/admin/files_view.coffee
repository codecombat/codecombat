RootView = require 'views/kinds/RootView'
template = require 'templates/admin/files'
tableTemplate = require 'templates/admin/files_table'

module.exports = class FilesView extends RootView
  id: 'admin-files-view'
  template: template

  events:
    'click #upload-button': -> filepicker.pick {mimetypes:'audio/*'}, @onFileChosen
    'change #folder-select': 'loadFiles'

  afterRender: ->
    super()
    @loadFiles()

  onFileChosen: (InkBlob) =>
    body =
      url: InkBlob.url
      filename: InkBlob.filename
      mimetype: InkBlob.mimetype
      path: @currentFolder()
      force: true

    # Automatically overwrite if the same path was put in here before
#    body.force = true # if InkBlob.filename is @data
    @uploadingPath = [@currentFolder(), InkBlob.filename].join('/')
    $.ajax('/file', {type: 'POST', data: body, success: @onFileUploaded})

  onFileUploaded: (e) =>
    @loadFiles()

  currentFolder: -> @$el.find('#folder-select').val()

  loadFiles: ->
    $.ajax
      url: "/file/#{@currentFolder()}/"
      success: @onLoadedFiles

  onLoadedFiles: (res) =>
    table = tableTemplate({files:res})
    @$el.find('#file-table').replaceWith(table)

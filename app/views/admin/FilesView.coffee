RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
require('vendor/co')
api = require 'core/api'
require('core/services/filepicker')()

FilesComponent = Vue.extend({
  template: require('templates/admin/files')()
  
  data: ->
    files: []
    directory: 'music' # or 'interface'
  
  methods:
    loadFiles: ->
      co =>
        @files = []
        @files = yield api.files.getDirectory({path: @directory})
        
    uploadFile: ->
      filepicker.pick {mimetypes:'audio/*'}, (InkBlob) =>
        body =
          url: InkBlob.url
          filename: InkBlob.filename
          mimetype: InkBlob.mimetype
          path: @directory
          force: 'true'
        api.files.saveFile(body).then(@loadFiles)

  created: ->
    @loadFiles()
    
  watch:
    directory: ->
      @loadFiles()
    
})

module.exports = class FilesView extends RootComponent
  id: 'files-view'
  template: template
  VueComponent: FilesComponent

<template lang="pug">
div.container
  h1 Files

  select#folder-select(v-model="directory")
    option(value="music") Music
    option(value="interface") Interface
    option(value="cinematic") Cinematic
    //- Dont use value 'interactive', since it gets converted to mongoose object id in server/routes/file.coffee parsePathIntoQuery
    option(value="interactives") Interactives

  a.btn.btn-primary#upload-button
    span.glyphicon.glyphicon-upload(v-on:click="uploadFile")

  table.table-condensed#file-table.table
    tbody
      tr
        th Filename
      tr(v-for="file in files")
        td
          a(:href='"/file/"+file.metadata.path+"/"+file.filename', target="_blank")
            | {{file.filename}}
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'
require('core/services/filepicker')()

module.exports = Vue.extend({
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

</script>

<style lang="sass">

#files-view
  table
    font-size: 12px

</style>

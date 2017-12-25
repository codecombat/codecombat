<template lang="jade">
div.container
  h1 Files

  select#folder-select(v-model="directory")
    option(value="music") Music
    option(value="interface") Interface

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

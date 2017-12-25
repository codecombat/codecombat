<template lang="jade">
div#admin-clas-view.container
  h1 CLAs

  table.table.table-striped.table-bordered.table-condensed#clas
    tbody
      tr
        th Name
        th Email
        th GitHub Username
        th Created
      tr(v-for="cla in clas")
        td {{cla.name}}
        td {{cla.email}}
        td {{cla.githubUsername}}
        td {{dateFormat(cla.created)}}
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'

module.exports = Vue.extend({
  data: ->
    clas: []

  methods:
    dateFormat: (s) -> moment(s).format('llll')

  created: co.wrap ->
    clas = yield api.clas.getAll()
    clas = _.sortBy(clas, (cla) -> (cla.githubUsername || 'zzzzzz').toLowerCase())
    clas = _.uniq(clas, true, 'githubUsername')
    @clas = clas
})

</script>

<style lang="sass">
@import "app/styles/bootstrap/variables"

#admin-clas-view
  background-color: white

  padding: 50px 0 200px

  table
    font-size: 11px

  hr
    border: 1px solid black
</style>

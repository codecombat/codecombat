<template lang="pug">
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

<script>
import api from 'core/api';

export default Vue.extend({
  data: () => ({
    clas: []
  }),
  methods: {
    dateFormat: s => moment(s).format('llll')
  },
  created() {
    api.clas.getAll()
      .then(clas => _.uniq(_.sortBy(clas, (cla) => new Date(cla.created)).reverse(), true, 'githubUsername'))
      .then(clas => this.clas = clas)
  }
});

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

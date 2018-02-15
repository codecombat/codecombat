<template lang="jade">

div
  page-errors(v-if="errors.length")
  slot(v-else)

</template>

<script lang="coffee">

PageErrors = require('core/components/PageErrors.vue').default

module.exports = {
  name: 'flat-layout'
  components:
    'page-errors': PageErrors
  computed: Vuex.mapState({
    errors: (state) -> state.pageErrors
  })
}

</script>

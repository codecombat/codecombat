<script>
import InputClanSearch from 'app/views/landing-pages/league/components/InputClanSearch'

export default {
  components: {
    InputClanSearch
  },

  mounted() {
    if (!me.isAdmin()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
  }
}
</script>

<template>
  <div>
    <p>Search for clans and teams by name</p>
    <InputClanSearch />
  </div>
</template>

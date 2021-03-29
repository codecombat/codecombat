<script>
import InputClanSearch from './InputClanSearch'

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
  <div class="form-group">
    <p>Search for clans and teams by name</p>
    <InputClanSearch />
  </div>
</template>


<style lang="sass">
.algolia-autocomplete 
    width: 100%

    .aa-input
      width: 100%

    .aa-hint
      color: #999
      width: 100%

    .aa-dropdown-menu 
      background-color: #fff
      border: 1px solid #999
      border-top: none
      width: 100%

      .aa-suggestion 
        cursor: pointer
        padding: 5px 4px
        border-top: 1px solid #ccc

        .school
          font-family: Open Sans
          font-size: 14px
          line-height: 20px
          font-weight: bold

        .district
          font-family: Open Sans
          font-size: 14px
          line-height: 20px

          span
            white-space: nowrap


      .aa-suggestion.aa-cursor 
        background-color: #B2D7FF

      em
        font-weight: bold
        font-style: normal
</style>
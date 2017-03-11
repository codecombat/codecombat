module.exports = {
  name: 'page-errors'
  template: require('templates/core/components/page-errors')()
  computed: _.assign(
    Vuex.mapState({
      error: (state) -> _.first(state.pageErrors)
    }),
    Vuex.mapGetters('me', [
      'isAnonymous'
      'forumLink'
    ])
  )
}

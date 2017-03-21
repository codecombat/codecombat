userSchema = require('schemas/models/user')

emptyUser = _.zipObject(([key, null] for key in _.keys(userSchema.properties)))

module.exports = {
  namespaced: true
  state: emptyUser
  getters:
    isAnonymous: (state) -> state.anonymous is true
    forumLink: (state) ->
      link = 'http://discourse.codecombat.com/'
      lang = (state.preferredLanguage or 'en-US').split('-')[0]
      if lang in ['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt']
        link += "c/other-languages/#{lang}"
      link

  mutations:
    updateUser: (state, updates) ->
      # deep copy, since nested data may be changed, and vuex store restricts mutations
      _.assign(state, $.extend(true, {}, updates))
}

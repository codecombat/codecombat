userSchema = require('schemas/models/user')
api = require('core/api')

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
    isAdmin: (state) ->
      permissions = state.permissions or []
      return permissions.indexOf('admin') > -1
    isLicensor: (state) ->
      (state?.permissions or []).indexOf('licensor') > -1

  mutations:
    updateUser: (state, updates) ->
      # deep copy, since nested data may be changed, and vuex store restricts mutations
      _.assign(state, $.extend(true, {}, updates))
      
  actions:
    save: ({state}, updates) ->
      # updates this module, Backbone me, and server
      user = _.assign({}, state, updates)
      return api.users.put(user)
      .then =>
        me.set(updates) # will also call updateUser
        return state
}

fetchJson = require './fetch-json'

module.exports = {
  url: (userId, path) -> if path then "/db/user/#{userId}/#{path}" else "/db/user/#{userId}"
  
  getByHandle: (handle, options) ->
    fetchJson("/db/user/#{handle}", options)
    
  getByIsraelId: (israelId, options) ->
    fetchJson('/db/user', _.assign({}, options, { data: { israelId } }))

  getByEmail: (email, options={}) ->
    fetchJson("/db/user", _.merge {}, options, { data: { email } })

  signupWithPassword: ({userId, name, email, password}, options={}) ->
    fetchJson(@url(userId, 'signup-with-password'), _.assign({}, options, {
      method: 'POST'
      json: { name, email, password }
    }))
    .then ->
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'

  signupWithFacebook: ({userId, name, email, facebookID}, options={}) ->
    fetchJson(@url(userId, 'signup-with-facebook'), _.assign({}, options, {
      method: 'POST'
      json: { name, email, facebookID, facebookAccessToken: application.facebookHandler.token() }
    }))
    .then ->
      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'

  signupWithGPlus: ({userId, name, email, gplusID}, options={}) ->
    fetchJson(@url(userId, 'signup-with-gplus'), _.assign({}, options, {
      method: 'POST'
      json: { name, email, gplusID, gplusAccessToken: application.gplusHandler.token() }
    }))
    .then ->
      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
      
  put: (user, options={}) ->
    fetchJson(@url(user._id), _.assign({}, options, {
      method: 'PUT'
      json: user
    }))
    
  putIsraelId: ({israelId, userId}, options={}) ->
    fetchJson(@url(userId, 'israel-id'), _.assign({}, options, {
      method: 'PUT'
      json: { israelId }
    }))
    
  resetProgress: (options={}) ->
    store = require('core/store')
    fetchJson(@url(store.state.me._id, 'reset_progress'), _.assign({}, options, {
      method: 'POST'
    }))
}

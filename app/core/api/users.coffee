fetchJson = require './fetch-json'

module.exports = {
  url: (userID, path) -> if path then "/db/user/#{userID}/#{path}" else "/db/user/#{userID}"

  getByHandle: (handle, options) ->
    fetchJson("/db/user/#{handle}", options)

  getByEmail: ({ email }, options={}) ->
    fetchJson("/db/user", _.merge {}, options, { data: { email } })

  signupWithPassword: ({userID, name, email, password}, options={}) ->
    fetchJson(@url(userID, 'signup-with-password'), _.assign({}, options, {
      method: 'POST'
      json: { name, email, password }
    }))
    .then ->
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'

  signupWithFacebook: ({userID, name, email, facebookID}, options={}) ->
    fetchJson(@url(userID, 'signup-with-facebook'), _.assign({}, options, {
      method: 'POST'
      json: { name, email, facebookID, facebookAccessToken: application.facebookHandler.token() }
    }))
    .then ->
      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'

  signupWithGPlus: ({userID, name, email, gplusID}, options={}) ->
    fetchJson(@url(userID, 'signup-with-gplus'), _.assign({}, options, {
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

  resetProgress: (options={}) ->
    store = require('core/store')
    fetchJson(@url(store.state.me._id, 'reset_progress'), _.assign({}, options, {
      method: 'POST'
    }))

  createBillingAgreement: ({userID, productID}, options={}) ->
    fetchJson(@url(userID, "paypal/create-billing-agreement"), _.assign({}, options, {
      method: 'POST'
      json: {productID}
    }))

  executeBillingAgreement: ({userID, token}, options={}) ->
    fetchJson(@url(userID, "paypal/execute-billing-agreement"), _.assign({}, options, {
      method: 'POST'
      json: {token}
    }))

  cancelBillingAgreement: ({userID, billingAgreementID}, options={}) ->
    fetchJson(@url(userID, "paypal/cancel-billing-agreement"), _.assign({}, options, {
      method: 'POST'
      json: {billingAgreementID}
    }))
    
  getCourseInstances: ({ userID, campaignSlug }, options={}) ->
    fetchJson(@url(userID, "course-instances"), _.merge({}, options, {
      data: { userID, campaignSlug }
    }))

  getLevelSessions: ({ userID }, options={}) ->
    fetchJson("/db/user/#{userID}/level.sessions", _.merge({}, options))
    
  resetProgress: ({ userID }, options={}) ->
    fetchJson("/db/user/#{userID}/reset_progress", _.assign({}, options, {
      method: 'POST'
    }))
}

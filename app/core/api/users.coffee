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
      credentials: 'include'
      json: { name, email, password }
    }))

  signupWithFacebook: ({userID, name, email, facebookID}, options={}) ->
    fetchJson(@url(userID, 'signup-with-facebook'), _.assign({}, options, {
      method: 'POST'
      credentials: 'include'
      json: { name, email, facebookID, facebookAccessToken: application.facebookHandler.token() }
    }))

  signupWithGPlus: ({userID, name, email, gplusID}, options={}) ->
    fetchJson(@url(userID, 'signup-with-gplus'), _.assign({}, options, {
      method: 'POST'
      credentials: 'include'
      json: { name, email, gplusID, gplusAccessToken: application.gplusHandler.token() }
    }))

  signupFromGoogleClassroom: (attrs, options={}) ->
    fetchJson("/db/user/signup-from-google-classroom", _.assign({}, options, {
      method: 'POST'
      json: attrs
    }))

  put: (user, options={}) ->
    fetchJson(@url(user._id), _.assign({}, options, {
      method: 'PUT'
      json: user
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

  exportData: ({ userID }, options={}) ->
    fetchJson("/db/user/#{userID}/export-data", _.assign({}, options, {
      method: 'GET'
    }))

  fetchByIds: ({ fetchByIds, teachersOnly, includeTrialRequests }) ->
    fetchJson("/db/user", {
      method: 'GET',
      data: {
        fetchByIds
        teachersOnly
        includeTrialRequests
      }
    })

  setCountryGeo: (options = {}) ->
    fetchJson("/db/user/setUserCountryGeo", _.assign({}, options, {
      method: 'PUT'
    }))
}

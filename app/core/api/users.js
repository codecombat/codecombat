// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json')

module.exports = {
  url (userID, path) { if (path) { return `/db/user/${userID}/${path}` } else { return `/db/user/${userID}` } },

  getByHandle (handle, options) {
    return fetchJson(`/db/user/${handle}`, options)
  },

  getByEmail ({ email }, options) {
    if (options == null) { options = {} }
    return fetchJson('/db/user', _.merge({}, options, { data: { email } }))
  },

  signupWithPassword ({ userID, name, email, password }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'signup-with-password'), _.assign({}, options, {
      method: 'POST',
      credentials: 'include',
      json: { name, email, password }
    }))
  },

  signupWithFacebook ({ userID, name, email, facebookID }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'signup-with-facebook'), _.assign({}, options, {
      method: 'POST',
      credentials: 'include',
      json: { name, email, facebookID, facebookAccessToken: application.facebookHandler.token() }
    }))
  },

  signupWithGPlus ({ userID, name, email, gplusID }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'signup-with-gplus'), _.assign({}, options, {
      method: 'POST',
      credentials: 'include',
      json: { name, email, gplusID, gplusAccessToken: application.gplusHandler.token() }
    }))
  },

  signupFromGoogleClassroom (attrs, options) {
    if (options == null) { options = {} }
    return fetchJson('/db/user/signup-from-google-classroom', _.assign({}, options, {
      method: 'POST',
      json: attrs
    }))
  },

  put (user, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(user._id), _.assign({}, options, {
      method: 'PUT',
      json: user
    }))
  },

  createBillingAgreement ({ userID, productID }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'paypal/create-billing-agreement'), _.assign({}, options, {
      method: 'POST',
      json: { productID }
    }))
  },

  executeBillingAgreement ({ userID, token }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'paypal/execute-billing-agreement'), _.assign({}, options, {
      method: 'POST',
      json: { token }
    }))
  },

  cancelBillingAgreement ({ userID, billingAgreementID }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'paypal/cancel-billing-agreement'), _.assign({}, options, {
      method: 'POST',
      json: { billingAgreementID }
    }))
  },

  getCourseInstances ({ userID, campaignSlug }, options) {
    if (options == null) { options = {} }
    return fetchJson(this.url(userID, 'course-instances'), _.merge({}, options, {
      data: { userID, campaignSlug }
    }))
  },

  getLevelSessions ({ userID }, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/user/${userID}/level.sessions`, _.merge({}, options))
  },

  resetProgress ({ userID }, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/user/${userID}/reset_progress`, _.assign({}, options, {
      method: 'POST'
    }))
  },

  exportData ({ userID }, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/user/${userID}/export-data`, _.assign({}, options, {
      method: 'GET'
    }))
  },

  fetchByIds ({ fetchByIds, teachersOnly, includeTrialRequests }) {
    return fetchJson('/db/user', {
      method: 'GET',
      data: {
        fetchByIds,
        teachersOnly,
        includeTrialRequests
      }
    })
  },

  setCountryGeo (options) {
    if (options == null) { options = {} }
    return fetchJson('/db/user/setUserCountryGeo', _.assign({}, options, {
      method: 'PUT'
    }))
  },

  fetchCreatorOfPrepaid ({ prepaidId }, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/prepaid/${prepaidId}/creator`, _.assign({}, options, {
      method: 'GET'
    }))
  },

  provisionSubscription ({ userId }) {
    return fetchJson(`/db/user/${userId}/provision-subscription`, _.assign({}, {
      method: 'PUT'
    }))
  },

  loginArapahoe (attrs, options) {
    if (options == null) { options = {} }
    return fetchJson('/auth/login-arapahoe', _.assign({}, options, {
      method: 'POST',
      json: attrs
    }))
  },

  loginLafourche (attrs, options) {
    if (options == null) { options = {} }
    return fetchJson('/auth/login-lafourche', _.assign({}, options, {
      method: 'POST',
      json: attrs
    }))
  },

  loginShreve (attrs, options) {
    if (options == null) { options = {} }
    return fetchJson('/auth/login-shreve', _.assign({}, options, {
      method: 'POST',
      json: attrs
    }))
  },

  loginHouston (attrs, options) {
    if (options == null) { options = {} }
    return fetchJson('/auth/login-houston', _.assign({}, options, {
      method: 'POST',
      json: attrs
    }))
  },

  putUserProducts (json, options) {
    if (options == null) { options = {} }
    return fetchJson('/db/user/products', _.assign({}, options, {
      method: 'PUT',
      json
    }))
  },

  getRelatedAccount ({ userId }) {
    return fetchJson(`/db/user/related-accounts/${userId}`, _.assign({}, {
      method: 'GET'
    }))
  },

  verifyRelatedAccount ({ userAskingToRelateId, body }) {
    return fetchJson(`/db/user/related-accounts/${userAskingToRelateId}/verify`, _.assign({}, {
      method: 'PUT',
      json: body
    }))
  },

  sendVerifyEmail (body) {
    return fetchJson('/db/user/related-accounts/confirm-email', _.assign({}, {
      method: 'POST',
      json: body
    }))
  },

  getFullNames (json, options) {
    return fetchJson('/db/user/-/getFullNames', _.assign({}, options, {
      method: 'POST',
      json
    }))
  },

  fetchNamesForUser (ids) {
    return fetchJson('/db/user/-/names', {
      method: 'POST',
      data: { ids }
    })
  },
  getUserCredits (operation) {
    return fetchJson(`/db/user-credits/${operation}`, _.assign({}, {
      method: 'GET'
    }))
  }
}

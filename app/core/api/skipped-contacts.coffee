fetchJson = require './fetch-json'
utils = require 'core/utils'

module.exports = {
  getAll: (options) ->
    return fetchJson('/db/skipped-contact', options).then (contacts) ->
      contacts.forEach (contact) ->
        contact.email = contact.trialRequest?.properties.email or contact.zpContact?.email
        if contact.trialRequest?.created
          contact.dateCreated = new Date(contact.trialRequest.created)
        else
          contact.dateCreated = utils.objectIdToDate(contact._id)
      return contacts

  put: (skippedContact, options) ->
    fetchJson("/db/skipped-contact/#{skippedContact._id}", _.assign({}, options, {
      method: 'PUT'
      json: skippedContact
    }))
}

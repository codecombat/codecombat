// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import fetchJson from './fetch-json';

import utils from 'core/utils';

export default {
  getAll(options) {
    return fetchJson('/db/skipped-contact', options).then(function(contacts) {
      contacts.forEach(function(contact) {
        contact.email = (contact.trialRequest != null ? contact.trialRequest.properties.email : undefined) || (contact.zpContact != null ? contact.zpContact.email : undefined);
        if ((contact.trialRequest != null ? contact.trialRequest.created : undefined)) {
          return contact.dateCreated = new Date(contact.trialRequest.created);
        } else {
          return contact.dateCreated = utils.objectIdToDate(contact._id);
        }
      });
      return contacts;
    });
  },

  put(skippedContact, options) {
    return fetchJson(`/db/skipped-contact/${skippedContact._id}`, _.assign({}, options, {
      method: 'PUT',
      json: skippedContact
    }));
  }
};

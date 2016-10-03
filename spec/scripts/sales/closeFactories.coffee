_ = require 'lodash'
moment = require 'moment'
faker = require 'faker'

makeTasksResult = (total_results) ->
  return {
    total_results
    has_more: false
    data: []
  }

makeActivityResult = ({ auto1, auto2, they_replied } = {}) ->
  activities = []
  if auto1
    activity = {
      id: 'acti_'+faker.random.uuid()
      to: ['teacher1@example.com']
      sender: 'Sales McClose <sales_1@codecombat.com>'
      _type: 'Email'
      template_id: 'template_auto1' # TODO: Be less magical. (This is in createTeacherEmailTemplatesAuto1)
      date_created: moment().subtract(7, 'days').toDate()
    }
    _.assign(activity, auto1) if _.isObject(auto1)
    activities.push activity
    activities.push makeStatusChangeActivity('Auto Attempt 1')
  if auto2
    activity = {
      id: 'acti_'+faker.random.uuid()
      to: ['teacher1@example.com']
      sender: 'Sales McClose <sales_1@codecombat.com>'
      _type: 'Email'
      template_id: 'template_auto2' # TODO: Be less magical. (This is in createTeacherEmailTemplatesAuto1)
      date_created: moment().subtract(4, 'days').toDate()
    }
    _.assign(activity, auto2) if _.isObject(auto2)
    activities.push activity
    activities.push makeStatusChangeActivity('Auto Attempt 2', 'Auto Attempt 1')
  if they_replied
    activity = {
      id: 'acti_'+faker.random.uuid()
      to: ['lisa@codecombat.com']
      sender: "#{faker.name.findName()} <#{faker.internet.email()}>"
      _type: 'Email'
      date_created: moment().subtract(2, 'days').toDate()
    }
    _.assign(activity, they_replied) if _.isObject(they_replied)
    activities.push activity
  return {
    has_more: false
    data: activities
  }

makeStatusChangeActivity = (status, oldStatus) ->
  {
    id: 'acti_'+faker.random.uuid()
    _type: 'LeadStatusChange'
    user_id: 'close_user_0'
    new_status_label: status
    old_status_label: oldStatus
    date_created: moment().subtract(7, 'days')
  }

# TODO: Add options for status, different contact info
makeLead = ({auto1, auto2} = {}) ->
  if auto1
    return {
      id: 'lead_1'
      status_label: 'Auto Attempt 1'
      contacts: [makeContact({ withEmails: true, withPhones: true })]
    }
  else if auto2
    return {
      id: 'lead_1'
      status_label: 'Auto Attempt 2'
      contacts: [makeContact({ withEmails: true, withPhones: true })]
    }
  else
    return {
      id: 'lead_1'
      status_label: 'Not Attempted'
      contacts: [makeContact({ withEmails: true, withPhones: true })]
    }


makeLeadsResult = () ->
  {
    total_results: 1
    has_more: false
    data: [
      makeLead()
    ]
  }

# withEmails: true, false, a number of fake email addresses to generate, or array of email addresses to use
makeContact = ({ withEmails, withPhones } = {}) ->
  contact = {}
  if withPhones
    phones = _.times Number(withPhones), ->
      {
        phone: faker.phone.phoneNumber()
        type: faker.random.arrayElement(['office', 'work', 'mobile', 'direct'])
      }
    _.assign contact, {phones}
  if withEmails
    emails = _.times Number(withEmails.length || withEmails), (i) ->
      {
        email: withEmails[i] || faker.internet.email()
        type: 'office'
      }
    _.assign contact, {emails}
  contact

module.exports = {
  makeTasksResult
  makeActivityResult
  makeLead
  makeLeadsResult
  makeContact
}

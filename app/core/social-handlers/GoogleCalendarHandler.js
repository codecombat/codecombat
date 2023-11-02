import api from 'core/api'
import CocoClass from 'core/CocoClass'
const SCOPE = 'https://www.googleapis.com/auth/calendar'

const convertEvent = (e, timeZone) => {
  const description = e.meetingLink ? `Join Meeting: ${e.meetingLink}` : ''
  const res = {
    summary: e.name,
    start: {
      dateTime: e.startDate,
      timeZone
    },
    end: {
      dateTime: e.endDate,
      timeZone
    },
    recurrence: [
      e.rrule.replace(/DTSTART:.*?\n/, '')
    ],
    // TODO: if any of students also has email?
    attendees: (e.gcEmails || []).map(e => { return { email: e } }),
    reminders: {
      useDefault: false,
      overrides: [
        { method: 'email', minutes: 24 * 60 },
        { method: 'popup', minutes: 10 }
      ]
    },
    description
  }
  return res
}

class GoogleCalendarAPIHandler extends CocoClass {
  constructor () {
    super()
    if (me.useGoogleCalendar()) {
      application.gplusHandler.loadAPI()
    }
  }

  async loadCalendarsFromAPI () {
    try {
      const r = await gapi.client.calendar.events.list({
        calendarId: 'primary',
        timeMin: (new Date()).toISOString()
      })
      return r.result.items || []
    } catch (err) {
      console.error('Error in loading calendars from google calendar:', err)
      throw new Error('Error in loading calendars from google calendar')
    }
  }

  async updateInstanceToAPI (instance, eventId, timeZone) {
    if (!eventId) {
      throw new Error('Event id not present to search on google')
    }

    const convertEvent = (i, timeZone) => ({
      start: {
        dateTime: i.startDate,
        timeZone
      },
      end: {
        dateTime: i.endDate,
        timeZone
      }
    })

    const instances = await gapi.client.calendar.events.instances({
      calendarId: 'primary',
      eventId
    })

    const iid = instances.items[instance.index]?.id
    if (!iid) {
      throw new Error('Instance not found on google')
    }

    const event = await gapi.client.calendar.events.patch({
      calendarId: 'primary',
      eventId: iid,
      resource: convertEvent(instance, timeZone)
    })

    console.log('Google Event updated: ' + event.htmlLink)
    return event
  }

  async updateCalendarsToAPI (e, timeZone) {
    if (!e.googleEventId) {
      throw new Error('Google event id not present')
    }

    const event = await gapi.client.calendar.events.patch({
      calendarId: 'primary',
      eventId: e.googleEventId,
      resource: convertEvent(e, timeZone)
    })

    console.log('Google Event updated: ' + event.htmlLink)
    return event
  }

  async syncCalendarsToAPI (e, timeZone) {
    const event = await gapi.client.calendar.events.insert({
      calendarId: 'primary',
      resource: convertEvent(e, timeZone)
    })

    console.log('Google Event created: ' + event.htmlLink)
    return event
  }

  requestGoogleAccessToken (callback) {
    application.gplusHandler.requestGoogleAuthorization(SCOPE, callback)
  }
}

export default {
  gcApiHandler: new GoogleCalendarAPIHandler(),
  scopes: SCOPE
}

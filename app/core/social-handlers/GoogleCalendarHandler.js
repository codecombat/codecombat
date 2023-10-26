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

const GoogleCalendarAPIHandler = class GoogleCalendarAPIHandler extends CocoClass {
  constructor () {
    if (me.useGoogleCalendar()) {
      application.gplusHandler.loadAPI()
    }
    super()
  }

  loadCalendarsFromAPI () {
    return new Promise((resolve, reject) => {
      const fun = async () => {
        // gapi.client.load('calendar', 'v3', async () => {
        try {
          const r = await gapi.client.calendar.events.list({
            'calendarId': 'primary',
            'timeMin': (new Date()).toISOString(),
          })
          resolve(r.result.items || [])
        } catch (err) {
          console.error('Error in loading calendars from google calendar:', err)
          reject(new Error('Error in loading calendars from google calendar'))
        }
        // })
      }
      this.requestGoogleAccessToken(fun)
    })
  }

  updateInstanceToAPI (instance, eventId, timeZone) {
    const convertEvent = (i, timeZone) => {
      const res = {
        start: {
          dateTime: i.startDate,
          timeZone
        },
        end: {
          dateTime: i.endDate,
          timeZone
        }
      }
      return res
    }

    return new Promise((resolve, reject) => {
      const fun = () => {
        if (!eventId) {
          return reject(new Error('Event id not present to search on google'))
        }
        gapi.client.load('calendar', 'v3', () => {
          gapi.client.calendar.events.instances({
            calendarId: 'primary',
            eventId
          }).execute((instances) => {
            const iid = instances.items[instance.index]?.id
            if (!iid) {
              return reject(new Error('Instance not found on google'))
            }
            gapi.client.calendar.events.patch({
              calendarId: 'primary',
              eventId: iid,
              resource: convertEvent(instance, timeZone)
            }).execute((event) => {
              console.log('Google Event updated: ' + event.htmlLink)
              resolve(event)
            })
          })
        })
      }
      this.requestGoogleAccessToken(fun)
    })
  }

  updateCalendarsToAPI (event, timeZone) {
    return new Promise((resolve, reject) => {
      const fun = () => {
        if (!event.googleEventId) {
          return reject(new Error('Google event id not present'))
        }
        gapi.client.load('calendar', 'v3', () => {
          gapi.client.calendar.events.patch({
            calendarId: 'primary',
            eventId: event.googleEventId,
            resource: convertEvent(event, timeZone)
          }).execute((event) => {
            console.log('Google Event updated: ' + event.htmlLink)
            resolve(event)
          })
        })
      }
      this.requestGoogleAccessToken(fun)
    })
  }

  syncCalendarsToAPI (event, timeZone) {
    return new Promise((resolve, reject) => {
      const fun = () => {
        gapi.client.load('calendar', 'v3', () => {
          gapi.client.calendar.events.insert({
            calendarId: 'primary',
            resource: convertEvent(event, timeZone)
          }).execute((event) => {
            console.log('Google Event created: ' + event.htmlLink)
            resolve(event)
          })
        })
      }
      this.requestGoogleAccessToken(fun)
    })
  }

  requestGoogleAccessToken (callback) {
    application.gplusHandler.requestGoogleAuthorization(
      SCOPE,
      callback
    )
  }
}

module.exports = {
  gcApiHandler: new GoogleCalendarAPIHandler(),

  scopes: SCOPE,

  markAsImported: async function (gcId) {
    try {
      const gEvent = me.get('googleCalendarEvents').find((gc) => gc.id === gcId)
      if (gEvent) {
        gEvent.importedToCoco = true
        await new Promise(me.save().then)
      } else {
        return Promise.reject('Event not found in me.googleClanedarEvents')
      }
    } catch (err) {
      console.error('Error in marking google calendar event as imported:', err)
      return Promise.reject('Error in marking event as imported')
    }
  },

  importEvents: async function () {
    try {
      const importedEvents = await this.gcApiHandler.loadCalendarsFromAPI()
      const importedEventsNames = importedEvents.map(c => ({ summary: c.summary }))
      const events = me.get('googleCalendarEvents') || []
      let mergedEvents = []
      importedEventsNames.forEach((imported) => {
        const ev = events.find((e) => e.summary === imported.summary)
        mergedEvents.push({ ...ev, ...imported })
      })

      const mergedEventIds = mergedEvents.map((e) => e.id)
      const extraEventsImported = events.filter((e) => (e.importedToCoco && !mergedEventIds.includes(e.id)))

      extraEventsImported.forEach((e) => (e.deletedFromGC = true))
      mergedEvents = mergedEvents.concat(extraEventsImported)

      me.set('googleCalendarEvents', mergedEvents)
      await new Promise(me.save().then)
    } catch (err) {
      console.error('Error in importing google calendar events:', err)
      return Promise.reject('Error in importing events')
    }
  },

  syncEventsToGC: async function (event, { timezone = 'America/New_York' } = {}) {
    try {
      if (event?.googleEventId) return this.gcApiHandler.updateCalendarsToAPI(event, timezone)
      return this.gcApiHandler.syncCalendarsToAPI(event, timezone)
    } catch (e) {
      console.error('Error in syncing event to google calendar:', e)
      return 'Error in syncing event to google calendar'
    }
  },

  syncInstanceToGC: async function (instance, eventId, timezone = 'America/New_York') {
    try {
      return this.gcApiHandler.updateInstanceToAPI(instance, eventId, timezone)
    } catch (e) {
      console.error('Error in syncing instance to google calendar:', e)
      return 'Error in syncing instance to google calendar'
    }
  }
}

import fetchJson from './fetch-json'
import _ from 'lodash'

export const getEvent = (id) => fetchJson(`/db/event/${id}`)
export const getAllEvents = () => fetchJson('/db/events')
export const getEventsByUser = uid => fetchJson(`/db/events?userId=${uid}`)

export const postEvent = (options = {}) => fetchJson('/db/event', _.assign({}, {
  method: 'POST',
  json: options
}))

export const updateEvent = (id, options = {}) => fetchJson(`/db/event/${id}`, _.assign({}, {
  method: 'PUT',
  json: options
}))

export const postEventMember = (id, options = {}) => fetchJson(`/db/event/${id}/member`, _.assign({}, {
  method: 'POST',
  json: options
}))

export const putEventMember = (id, options = {}) => fetchJson(`/db/event/${id}/member`, _.assign({}, {
  method: 'PUT',
  json: options
}))

export const deleteEventMember = (id, options = {}) => fetchJson(`/db/event/${id}/member`, _.assign({}, {
  method: 'DELETE',
  json: options
}))

export const syncToGoogleFailed = (id, options = {}) => fetchJson(`/db/event/${id}/sync-failed`, _.assign({}, {
  method: 'PUT',
  json: options
}))

// instances

export const getInstances = (id) => fetchJson(`/db/event/${id}/instances`)

export const putInstance = (id, options = {}) => fetchJson(`/db/event.instance/${id}`, _.assign({}, {
  method: 'PUT',
  json: options
}))

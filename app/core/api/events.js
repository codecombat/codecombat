import fetchJson from './fetch-json'

export const getAllEvents = () => fetchJson('/db/events')
export const getEventsByUser = uid => fetchJson(`/db/events?userId=${uid}`)

import fetchJson from 'app/core/api/fetch-json'

const presenceHandler = method => ({ levelOriginalId }) => {
  if (!levelOriginalId) {
    throw new Error('Please pass in a valid "levelOriginalId"')
  }
  return fetchJson(`/artisan/presence/level/${levelOriginalId}`, {
    method
  })
}

export const setPresence = presenceHandler('POST')
export const getPresence = presenceHandler('GET')
export const deletePresence = presenceHandler('DELETE')

import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new chat message in the database.
 * @async
 */
export const createNewChatMessage = ({ ...opts }, options = {}) =>
  fetchJson('/db/chat_message', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getChatMessages = () => fetchJson('/db/chat_message')

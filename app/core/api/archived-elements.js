import fetchJson from './fetch-json'

/**
 * Archives a game element
 * @param _id - The mongo _id of the element
 * @param elementType - The game element type
 * @async
 */
export const archiveElement = (_id, elementType) => {
  if (!me.isAdmin()) {
    throw new Error('Admin access required')
  }

  if (!_id) {
    throw new Error('You must pass an \'_id\' to be archived')
  }

  if (!elementType) {
    throw new Error('You must pass an \'elementType\' to be archived')
  }

  return fetchJson('/db/archived-elements', {
    method: 'POST',
    json: {
      _id,
      elementType
    }
  })
}

/**
 * Un-archives a game element. This is not a destructive operation.
 * @param _id - The mongo _id of the element
 * @param elementType - The game element type
 * @async
 */
export const unarchiveElement = (_id, elementType) => {
  if (!me.isAdmin()) {
    throw new Error('Admin access required')
  }

  if (!_id) {
    throw new Error('You must pass an \'_id\' to be un-archived')
  }

  if (!elementType) {
    throw new Error('You must pass an \'elementType\' to be un-archived')
  }

  return fetchJson(`/db/archived-elements/${_id}`, {
    method: 'PUT',
    json: {
      elementType
    }
  })
}

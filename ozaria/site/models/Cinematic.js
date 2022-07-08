import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/cinematic.schema'

class Cinematic extends CocoModel { }

Cinematic.className = 'Cinematic'
Cinematic.schema = schema
Cinematic.urlRoot = '/db/cinematic'
Cinematic.prototype.urlRoot = '/db/cinematic'

/**
 * @typedef {Object} DialogueText
 * @property {number} id
 * @property {text} string
 */

/**
 * Flattens a cinematic into an array of dialogue nodes.
 *
 * O(n) complexity where n is the number of dialogue nodes.
 *
 * @param {Cinematic} cinematic - the cinematic to flatten
 * @returns {Array<DialogueText>} - List of all dialogue in the cinematic
 */
Cinematic.flattenDialogueText = (cinematic) => {
  const cinematicText = []
  const shots = cinematic.get('shots') || []
  let idx = 0
  for (const shot of shots) {
    for (const { text } of (shot.dialogNodes || [])) {
      if (text) {
        cinematicText.push({
          id: idx,
          text: text
        })
        idx += 1
      }
    }
  }
  return cinematicText
}

/**
 * A static method to find the paths to some dialogue on a Cinematic.
 * The two numbers can be used to expand the treema editor or locate the text
 * in the nested Cinematic structure.
 *
 * O(n) complexity where n is the number of dialogue nodes.
 *
 * @param {Cinematic} cinematic
 * @param {string} searchText - The exact text we are searching for.
 * @returns {Array<[number, number]>} - The shot index and then dialog node index.
 */
Cinematic.findDialogTextPath = (cinematic, searchText) => {
  const results = []
  const shots = cinematic.get('shots') || []
  for (let i = 0; i < shots.length; i++) {
    const shot = shots[i]
    if (Array.isArray(shot.dialogNodes)) {
      for (let j = 0; j < shot.dialogNodes.length; j++) {
        const text = (shot.dialogNodes[j] || {}).text
        if (text === searchText) {
          results.push([i, j])
        }
      }
    }
  }
  return results
}

module.exports = Cinematic

/* eslint-env jasmine */
import { getLeftCharacterThangTypeSlug, getRightCharacterThangTypeSlug } from '../../../app/schemas/selectors/cinematic'

/**
 * This data can be used to check that none of the selectors that match
 * the left or right character work.
 * Intentionally invalid data.
 */
const invalidThangTypesSetupData = [
  { shotSetup: {} },
  { dialogNodes: [] },
  { shotSetup: { camera: 'dual' } },
  { shotSetup: { rightThangType: {} } },
  { shotSetup: { backgroundArt: {} } },
  { shotSetup: { leftThangType: undefined } },
  { shotSetup: { leftThangType: { slug: 'abc', rand: 123 } } },
  { shotSetup: { rightThangType: undefined } },
  { shotSetup: { rightThangType: { slug: 'abc', rand: 123 } } }
]

const shotSetupChar = (thangType, data) => ({ [thangType]: data })

const malformedErrorData = thangType => ([
  { type: 'slug' },
  { type: 'slug', slug: 'randomSlug' },
  { type: 'slug', slug: 'a', enterOnStart: false },
  { type: 'slug', enterOnStart: true },
  { type: 'slug', position: { x: 0, y: 0 } },
  { type: 'slug', position: { x: 0, y: 0 }, enterOnStart: false }
]).map(d => ({ shotSetup: shotSetupChar(thangType, d) }))

describe('Cinematic', () => {
  describe('Selectors', () => {
    getCharacterThangTypeSlugTest(getLeftCharacterThangTypeSlug, 'getLeftCharacterThangTypeSlug', invalidThangTypesSetupData, 'leftThangType')
    getCharacterThangTypeSlugTest(getRightCharacterThangTypeSlug, 'getRightCharacterThangTypeSlug', invalidThangTypesSetupData, 'rightThangType')
  })
})

// Test for left and right character selectors.
function getCharacterThangTypeSlugTest (selector, side, data, characterProperty) {
  describe(`${side}`, () => {
    it('returns undefined when passed nothing', () => {
      expect(selector(undefined)).toBeUndefined()
    })

    it('returns undefined if the left thangType doesn\'t have type', () => {
      for (const testData of data) {
        expect(selector(testData)).toBeUndefined()
      }
    })

    it('throws error if type is slug but properties are not fulfilled', () => {
      for (const testData of malformedErrorData(characterProperty)) {
        expect(() => selector(testData)).toThrow()
      }
    })
  })
}

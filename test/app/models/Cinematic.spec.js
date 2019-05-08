/* eslint-env jasmine */
import {
  getLeftCharacterThangTypeSlug,
  getRightCharacterThangTypeSlug,
  getLeftHero,
  getRightHero,
  getClearBackgroundObject,
  getBackgroundObject,
  getBackground,
  getClearText,
  getSpeaker,
  getBackgroundSlug,
  getExitCharacter,
  getTextPosition,
  getText
} from '../../../app/schemas/selectors/cinematic'

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

describe('Cinematic', () => {
  describe('Selectors', () => {
    getCharacterThangTypeSlugTest(getLeftCharacterThangTypeSlug, 'getLeftCharacterThangTypeSlug', invalidThangTypesSetupData, 'leftThangType')
    getCharacterThangTypeSlugTest(getRightCharacterThangTypeSlug, 'getRightCharacterThangTypeSlug', invalidThangTypesSetupData, 'rightThangType')

    it('getLeftCharacterThangTypeSlug', () => {
      const result = getLeftCharacterThangTypeSlug(shotFixture1)
      expect(result).toBeUndefined()

      const result2 = getLeftCharacterThangTypeSlug(shotFixture2)
      expect(result2).toEqual({ slug: 'fake-slug-thangtype', enterOnStart: false, thang: { scaleX: 1, scaleY: 1, pos: { x: 0, y: 0 } } })
    })

    it('getRightCharacterThangTypeSlug', () => {
      const result = getRightCharacterThangTypeSlug(shotFixture2)
      expect(result).toBeUndefined()

      const result2 = getRightCharacterThangTypeSlug(shotFixture1)
      expect(result2).toEqual({ slug: 'fake-slug-thangtype', enterOnStart: false, thang: { scaleX: 1, scaleY: 1, pos: { x: 0, y: 0 } } })
    })

    it('getLeftHero', () => {
      const result = getLeftHero(shotFixture1)
      expect(result).toEqual({ enterOnStart: true, thang: { scaleX: 1, scaleY: 13, pos: { x: 3, y: 10 } } })

      const result2 = getLeftHero(shotFixture2)
      expect(result2).toBeUndefined()
    })

    it('getRightHero', () => {
      const result = getRightHero(shotFixture2)
      expect(result).toEqual({ enterOnStart: true, thang: { scaleX: 1, scaleY: 13, pos: { x: 3, y: 10 } } })

      const result2 = getRightHero(shotFixture1)
      expect(result2).toBeUndefined()
    })

    it('getClearBackgroundObject', () => {
      const result = getClearBackgroundObject(shotFixture1.dialogNodes[0])
      expect(result).toEqual(7331)

      const result2 = getClearBackgroundObject(shotFixture2.dialogNodes[0])
      expect(result2).toBeUndefined()
    })

    it('getBackgroundObject', () => {
      const result = getBackgroundObject(shotFixture1.dialogNodes[0])
      expect(result).toEqual({ scaleX: 1, scaleY: 1, pos: { x: 0, y: 0 }, type: { slug: 'background-obj-fixture' } })

      const result2 = getBackgroundObject(shotFixture2.dialogNodes[0])
      expect(result2).toBeUndefined()
    })

    it('getBackground', () => {
      const result = getBackground(shotFixture1)
      expect(result).toEqual({ slug: 'background-fixture-slug', thang: { scaleX: 0.3, scaleY: 0.2, pos: { x: 17, y: 18 } } })

      const result2 = getBackground(shotFixture2)
      expect(result2).toBeUndefined()
    })

    it('getClearText', () => {
      const result = getClearText(shotFixture1.dialogNodes[0])
      expect(result).toEqual(true)

      const result2 = getClearText(shotFixture2.dialogNodes[0])
      expect(result2).toEqual(false)
    })

    it('getSpeaker', () => {
      const result = getSpeaker(shotFixture1.dialogNodes[0])
      expect(result).toBeUndefined()

      const result2 = getSpeaker(shotFixture2.dialogNodes[0])
      expect(result2).toEqual('left')
    })

    it('getBackgroundSlug', () => {
      const result = getBackgroundSlug(shotFixture1)
      expect(result).toEqual('background-fixture-slug')

      const result2 = getBackgroundSlug(shotFixture2)
      expect(result2).toBeUndefined()
    })

    it('getExitCharacter', () => {
      const result = getExitCharacter(shotFixture1.dialogNodes[0])
      expect(result).toEqual('both')

      const result2 = getExitCharacter(shotFixture2.dialogNodes[0])
      expect(result2).toBeUndefined()
    })

    it('getTextPosition', () => {
      const result = getTextPosition(shotFixture1.dialogNodes[0])
      expect(result).toBeUndefined()

      const result2 = getTextPosition(shotFixture2.dialogNodes[0])
      expect(result2).toEqual({
        x: 40,
        y: 10
      })
    })

    it('getText', () => {
      const result = getText(shotFixture1.dialogNodes[0])
      expect(result).toEqual('hello, world')

      const result2 = getText(shotFixture2.dialogNodes[0])
      expect(result2).toBeUndefined()
    })
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
  })
}

// Fixture testing selectors for cinematics.
var shotFixture1 = {
  shotSetup: {
    leftThangType: {
      thangType: {
        type: 'hero',
        pos: {
          x: 3,
          y: 10
        },
        scaleX: 1,
        scaleY: 13
      },
      enterOnStart: true
    },
    rightThangType: {
      thangType: {
        type: {
          slug: 'fake-slug-thangtype'
        }
      }
    },
    backgroundArt: {
      type: {
        slug: 'background-fixture-slug'
      },
      pos: {
        x: 17,
        y: 18
      },
      scaleX: 0.3,
      scaleY: 0.2
    }
  },
  dialogNodes: [
    {
      dialogClear: true,
      exitCharacter: 'both',
      text: 'hello, world',
      triggers: {
        backgroundObject: {
          thangType: {
            type: {
              slug: 'background-obj-fixture'
            }
          },
          triggerStart: 1337
        },
        clearBackgroundObject: {
          triggerStart: 7331
        }
      }
    },
    {
      dialogClear: false
    }
  ]
}

var shotFixture2 = {
  shotSetup: {
    rightThangType: {
      thangType: {
        type: 'hero',
        pos: {
          x: 3,
          y: 10
        },
        scaleX: 1,
        scaleY: 13
      },
      enterOnStart: true
    },
    leftThangType: {
      thangType: {
        type: {
          slug: 'fake-slug-thangtype'
        }
      }
    }
  },
  dialogNodes: [
    {
      triggers: { },
      speaker: 'left',
      textLocation: {
        x: 40,
        y: 10
      }
    }
  ]
}

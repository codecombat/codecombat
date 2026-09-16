/* eslint-disable
    no-undef,
*/
const LevelComponent = require('models/LevelComponent')
const helper = require('lib/level-position-components')

describe('lib/level-position-components', () => {
  const PHYSICAL = LevelComponent.PhysicalID
  const POSITION_JS = _.find(LevelComponent.positionIDs, id => id !== PHYSICAL)
  const EXISTS = LevelComponent.ExistsID

  const thangWith = (...originals) => ({ id: 'Thang 1', components: originals.map(original => ({ original, majorVersion: 0, config: {} })) })
  const typeWith = (...originals) => originals.map(original => ({ original, majorVersion: 0, config: {} }))

  describe('positionOriginals', () => {
    it('finds Physical on the level thang', () => {
      expect(helper.positionOriginals(thangWith(EXISTS, PHYSICAL), [])).toEqual([PHYSICAL])
    })

    it('finds PositionJS on the level thang', () => {
      expect(helper.positionOriginals(thangWith(EXISTS, POSITION_JS), [])).toEqual([POSITION_JS])
    })

    it('keeps level thang order when both are present', () => {
      expect(helper.positionOriginals(thangWith(POSITION_JS, PHYSICAL), [])).toEqual([POSITION_JS, PHYSICAL])
    })

    it('appends ThangType defaults the level thang does not have, after the level ones', () => {
      expect(helper.positionOriginals(thangWith(PHYSICAL), typeWith(POSITION_JS, PHYSICAL))).toEqual([PHYSICAL, POSITION_JS])
    })

    it('uses ThangType defaults when the level thang has no position component', () => {
      expect(helper.positionOriginals(thangWith(EXISTS), typeWith(EXISTS, POSITION_JS))).toEqual([POSITION_JS])
    })

    it('returns nothing when neither side has one', () => {
      expect(helper.positionOriginals(thangWith(EXISTS), typeWith(EXISTS))).toEqual([])
      expect(helper.positionOriginals(undefined, undefined)).toEqual([])
    })
  })

  describe('winningPositionOriginal / hasDuplicatePosition', () => {
    it('reports the last attached component as the winner', () => {
      expect(helper.winningPositionOriginal(thangWith(PHYSICAL), typeWith(POSITION_JS))).toBe(POSITION_JS)
      expect(helper.winningPositionOriginal(thangWith(POSITION_JS, PHYSICAL), [])).toBe(PHYSICAL)
    })

    it('flags a thang that ends up with two position components', () => {
      expect(helper.hasDuplicatePosition(thangWith(PHYSICAL), typeWith(POSITION_JS))).toBe(true)
      expect(helper.hasDuplicatePosition(thangWith(PHYSICAL), typeWith(PHYSICAL))).toBe(false)
      expect(helper.hasDuplicatePosition(thangWith(EXISTS), [])).toBe(false)
    })
  })

  describe('shapeOriginals / collisionOriginals', () => {
    it('use their own id lists', () => {
      const SHAPE = _.find(LevelComponent.shapeIDs, id => id !== PHYSICAL)
      const COLLIDES = LevelComponent.CollidesID
      expect(helper.shapeOriginals(thangWith(PHYSICAL, POSITION_JS), typeWith(SHAPE))).toEqual([PHYSICAL, SHAPE])
      expect(helper.collisionOriginals(thangWith(PHYSICAL), typeWith(COLLIDES))).toEqual([COLLIDES])
    })
  })

  describe('positionConfigFor', () => {
    const pos = { x: 12.5, y: 7, z: 2 }

    it('gives Physical the editor z', () => {
      expect(helper.positionConfigFor(PHYSICAL, pos, { config: { pos: { x: 0, y: 0, z: 1 } } })).toEqual({ x: 12.5, y: 7, z: 2 })
    })

    it('falls back to the existing Physical z when the editor has none', () => {
      expect(helper.positionConfigFor(PHYSICAL, { x: 1, y: 2 }, { config: { pos: { x: 0, y: 0, z: 1 } } })).toEqual({ x: 1, y: 2, z: 1 })
    })

    it('keeps the PositionJS z, default 0', () => {
      expect(helper.positionConfigFor(POSITION_JS, pos, { config: { pos: { x: 0, y: 0, z: 5 } } })).toEqual({ x: 12.5, y: 7, z: 5 })
      expect(helper.positionConfigFor(POSITION_JS, pos, { config: {} })).toEqual({ x: 12.5, y: 7, z: 0 })
      expect(helper.positionConfigFor(POSITION_JS, pos, undefined)).toEqual({ x: 12.5, y: 7, z: 0 })
    })
  })
})

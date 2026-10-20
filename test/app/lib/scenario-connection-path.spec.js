/* eslint-env jasmine */
const { scenarioConnectionPath } = require('lib/scenario-connection-path')

describe('lib/scenario-connection-path', () => {
  const numbers = d => d.match(/-?[\d.]+/g).map(Number)

  it('flips y so a bottom-based position becomes a top-based path point', () => {
    expect(scenarioConnectionPath({ x: 40, y: 45.5 }, { x: 60, y: 45.5 }, 'left')).toMatch(/^M 40,54\.5 Q .* 60,54\.5$/)
  })

  it('bows a left curve towards the top of the map', () => {
    expect(scenarioConnectionPath({ x: 10, y: 50 }, { x: 30, y: 50 }, 'left')).toBe('M 10,50 Q 20,46 30,50')
  })

  it('bows a right curve towards the bottom of the map', () => {
    expect(scenarioConnectionPath({ x: 10, y: 50 }, { x: 30, y: 50 }, 'right')).toBe('M 10,50 Q 20,54 30,50')
  })

  it('bows away from the map centre when no side is given', () => {
    expect(scenarioConnectionPath({ x: 10, y: 20 }, { x: 30, y: 20 })).toBe('M 10,80 Q 20,84 30,80')
    expect(scenarioConnectionPath({ x: 10, y: 80 }, { x: 30, y: 80 })).toBe('M 10,20 Q 20,16 30,20')
  })

  it('never bows less than 4 viewBox units', () => {
    expect(scenarioConnectionPath({ x: 10, y: 50 }, { x: 11, y: 50 }, 'left')).toBe('M 10,50 Q 10.5,46 11,50')
  })

  it('never bows more than 22 viewBox units', () => {
    const [,, cx, cy] = numbers(scenarioConnectionPath({ x: 0, y: 100 }, { x: 100, y: 0 }, 'left'))
    expect(cx).toBeCloseTo(50 + 22 / Math.SQRT2, 3)
    expect(cy).toBeCloseTo(50 - 22 / Math.SQRT2, 3)
  })
})

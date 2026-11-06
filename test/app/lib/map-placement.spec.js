const { MAP_Z, resolveMapPlacements, offsetForPosition, byDrawOrder } = require('lib/map-placement')

describe('map-placement', () => {
  const planet = { id: 'planet-green', image: 'db/campaign/c/green.webp', position: { x: 22, y: 67 }, width: 0.25 }

  describe('resolveMapPlacements', () => {
    it('places a decoration at its own position with the kind defaults', () => {
      const { decorations } = resolveMapPlacements({ decorations: [planet] })
      expect(decorations.length).toBe(1)
      expect(decorations[0]).toEqual(jasmine.objectContaining({ id: 'planet-green', x: 22, y: 67, z: MAP_Z.decoration, widthPercent: 25, rotation: 0, opacity: 1 }))
    })

    it('clamps z into 0..10 and keeps decimals', () => {
      const { decorations, markers } = resolveMapPlacements({
        decorations: [{ ...planet, z: 5.5 }, { ...planet, id: 'moon', z: 99 }, { ...planet, id: 'dust', z: -3 }],
        markers: [{ key: 'a', position: { x: 1, y: 1 }, z: 3.25 }, { key: 'b', position: { x: 1, y: 1 } }],
      })
      expect(decorations.map(d => d.z)).toEqual([5.5, 10, 0])
      expect(markers.a.z).toBe(3.25)
      expect(markers.b.z).toBe(MAP_Z.marker)
    })

    it('anchors a marker to a decoration: offset in percent of the decoration width, vertical through the aspect', () => {
      const { markers } = resolveMapPlacements({
        decorations: [planet],
        markers: [{ key: 'm', position: { x: 0, y: 0 }, anchor: { id: 'planet-green', offset: { x: 40, y: -62 } } }],
        mapAspect: 1.5,
      })
      // 40% of a 25%-wide planet = 10% of the map width; -62% of it = -15.5% of map width = -23.25% of map height on a 3:2 map
      expect(markers.m.x).toBeCloseTo(32, 5)
      expect(markers.m.y).toBeCloseTo(67 - 23.25, 5)
    })

    it('moving the decoration carries its anchored marker', () => {
      const anchored = { key: 'm', position: { x: 0, y: 0 }, anchor: { id: 'planet-green', offset: { x: 0, y: 40 } } }
      const before = resolveMapPlacements({ decorations: [planet], markers: [anchored], mapAspect: 16 / 9 }).markers.m
      const after = resolveMapPlacements({ decorations: [{ ...planet, position: { x: 52, y: 17 } }], markers: [anchored], mapAspect: 16 / 9 }).markers.m
      expect(after.x - before.x).toBeCloseTo(30, 5)
      expect(after.y - before.y).toBeCloseTo(-50, 5)
    })

    it('keeps an anchored item at least a step above its anchor', () => {
      const { decorations, markers } = resolveMapPlacements({
        decorations: [{ ...planet, z: 4 }, { id: 'moon', image: 'm.png', position: { x: 0, y: 0 }, width: 0.05, z: 1, anchor: { id: 'planet-green', offset: { x: 60, y: 0 } } }],
        markers: [{ key: 'm', position: { x: 0, y: 0 }, z: 1, anchor: { id: 'planet-green', offset: { x: 0, y: 0 } } }],
      })
      expect(decorations[1].z).toBeCloseTo(4.1, 5)
      expect(markers.m.z).toBeCloseTo(4.1, 5)
    })

    it('falls back to the own position for an unknown anchor, a self anchor and a cycle', () => {
      const { decorations, markers } = resolveMapPlacements({
        decorations: [
          { ...planet, id: 'a', anchor: { id: 'b', offset: { x: 10, y: 10 } } },
          { ...planet, id: 'b', position: { x: 5, y: 5 }, anchor: { id: 'a', offset: { x: 10, y: 10 } } },
          { ...planet, id: 'c', position: { x: 9, y: 9 }, anchor: { id: 'c', offset: { x: 10, y: 10 } } },
        ],
        markers: [{ key: 'm', position: { x: 3, y: 4 }, anchor: { id: 'nope', offset: { x: 10, y: 10 } } }],
      })
      const c = decorations.find(d => d.id === 'c')
      expect(c.x).toBe(9)
      expect(markers.m).toEqual({ x: 3, y: 4, z: MAP_Z.marker })
      // a and b break the cycle: one of them resolves from its own position, the other hangs on it
      const a = decorations.find(d => d.id === 'a')
      const b = decorations.find(d => d.id === 'b')
      expect([a, b].some(d => d.x === 22 || d.x === 5)).toBe(true)
    })

    it('drops a decoration whose showIf level is not complete and keeps it once it is', () => {
      const gated = { ...planet, id: 'moon', showIf: { level: 'level-original', status: 'complete' } }
      expect(resolveMapPlacements({ decorations: [planet, gated] }).decorations.map(d => d.id)).toEqual(['planet-green'])
      expect(resolveMapPlacements({ decorations: [planet, gated], isComplete: id => id === 'level-original' }).decorations.map(d => d.id)).toEqual(['planet-green', 'moon'])
    })

    it('ignores decorations without an id and markers without a key', () => {
      const { decorations, markers } = resolveMapPlacements({ decorations: [{ image: 'x.png', position: { x: 1, y: 1 } }, planet], markers: [{ position: { x: 1, y: 1 } }] })
      expect(decorations.map(d => d.id)).toEqual(['planet-green'])
      expect(Object.keys(markers)).toEqual([])
    })
  })

  describe('offsetForPosition', () => {
    it('inverts the anchored position so a drag keeps the anchor', () => {
      const parent = { x: 22, y: 67, width: 0.25 }
      const offset = offsetForPosition(parent, { x: 32, y: 67 - 23.25 }, 1.5)
      expect(offset.x).toBeCloseTo(40, 5)
      expect(offset.y).toBeCloseTo(-62, 5)
    })
  })

  describe('byDrawOrder', () => {
    it('sorts by z then by the renderer order', () => {
      const items = [{ z: 3, order: 1 }, { z: 1, order: 5 }, { z: 3, order: 0 }, { z: 2.5, order: 9 }]
      expect(items.sort(byDrawOrder).map(i => `${i.z}/${i.order}`)).toEqual(['1/5', '2.5/9', '3/0', '3/1'])
    })
  })
})

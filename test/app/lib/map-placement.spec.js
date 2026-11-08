const { MAP_Z, resolveMapPlacements, offsetForPosition, byDrawOrder, hexToRgb } = require('lib/map-placement')

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
      expect(markers.m.anchorId).toBe('planet-green')
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

    it('falls back to the own position for an unknown anchor, a self anchor and every member of a cycle', () => {
      const { decorations, markers } = resolveMapPlacements({
        decorations: [
          { ...planet, id: 'a', anchor: { id: 'b', offset: { x: 10, y: 10 } } },
          { ...planet, id: 'b', position: { x: 5, y: 5 }, anchor: { id: 'a', offset: { x: 10, y: 10 } } },
          { ...planet, id: 'c', position: { x: 9, y: 9 }, anchor: { id: 'c', offset: { x: 10, y: 10 } } },
          { ...planet, id: 'd', position: { x: 1, y: 1 }, anchor: { id: 'a', offset: { x: 40, y: 0 } } },
        ],
        markers: [{ key: 'm', position: { x: 3, y: 4 }, anchor: { id: 'nope', offset: { x: 10, y: 10 } } }],
      })
      const byId = {}
      for (const d of decorations) { byId[d.id] = d }
      expect([byId.a.x, byId.b.x, byId.c.x]).toEqual([22, 5, 9])
      expect([byId.a.anchorId, byId.b.anchorId, byId.c.anchorId]).toEqual([null, null, null])
      // d is outside the cycle: it hangs on a, which sits at its own position
      expect(byId.d.x).toBeCloseTo(22 + 0.4 * 25, 5)
      expect(byId.d.anchorId).toBe('a')
      expect(markers.m).toEqual({ x: 3, y: 4, z: MAP_Z.marker, anchorId: null })
    })

    it('treats an empty-string id like any other id', () => {
      const { decorations, labels } = resolveMapPlacements({
        decorations: [{ ...planet, id: '' }, { ...planet, id: 'moon', position: { x: 0, y: 0 }, anchor: { id: '', offset: { x: 40, y: 0 } } }],
        labels: [{ id: 'l', text: 'x', position: { x: 0, y: 0 }, anchor: { id: '', offset: { x: 40, y: 0 } } }],
      })
      expect(decorations.map(d => [d.id, d.x, d.anchorId])).toEqual([['', 22, null], ['moon', 32, '']])
      expect([labels[0].x, labels[0].anchorId]).toEqual([32, ''])
    })

    it('draws the first of two decorations sharing an id, the one the editor finds', () => {
      const { decorations } = resolveMapPlacements({ decorations: [planet, { ...planet, position: { x: 50, y: 50 } }] })
      expect(decorations.map(d => [d.id, d.x, d.index])).toEqual([['planet-green', 22, 0]])
    })

    it('keeps ids off Object.prototype: "constructor" is a decoration, "toString" is a missing anchor', () => {
      const { decorations, markers, labels } = resolveMapPlacements({
        decorations: [{ ...planet, id: 'constructor' }],
        markers: [{ key: 'm', position: { x: 3, y: 4 }, anchor: { id: 'toString', offset: { x: 10, y: 10 } } }],
        labels: [{ id: 'l', text: 'x', position: { x: 1, y: 2 }, anchor: { id: 'hasOwnProperty', offset: { x: 10, y: 10 } } }],
      })
      expect(decorations.map(d => d.id)).toEqual(['constructor'])
      expect(markers.m).toEqual({ x: 3, y: 4, z: MAP_Z.marker, anchorId: null })
      expect(labels[0]).toEqual(jasmine.objectContaining({ x: 1, y: 2, z: MAP_Z.label, anchorId: null }))
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

  describe('labels', () => {
    const plank = { id: 'plank-green', text: 'Vibe Coding Lab', position: { x: 22, y: 40 }, accent: '#C0D030' }

    it('places a label at its own position with the kind defaults and the resolved look', () => {
      const { labels } = resolveMapPlacements({ labels: [plank] })
      expect(labels.length).toBe(1)
      expect(labels[0]).toEqual(jasmine.objectContaining({ id: 'plank-green', index: 0, x: 22, y: 40, z: MAP_Z.label, text: 'Vibe Coding Lab', scale: 1, style: 'plank', accent: '#C0D030', accentRgb: '192, 208, 48', plankImage: null }))
    })

    it('anchors a label to a decoration and never draws it under that decoration', () => {
      const { labels } = resolveMapPlacements({ decorations: [{ ...planet, z: 6 }], labels: [{ ...plank, position: { x: 0, y: 0 }, anchor: { id: 'planet-green', offset: { x: 0, y: -62 } } }], mapAspect: 1.5 })
      expect(labels[0].x).toBeCloseTo(22, 5)
      expect(labels[0].y).toBeCloseTo(67 - 15.5 * 1.5, 5)
      expect(labels[0].z).toBeCloseTo(6.1, 5)
    })

    it('keeps the text translations, clamps scale, and falls back on an unknown style or a bad colour', () => {
      const { labels } = resolveMapPlacements({ labels: [{ ...plank, i18n: { de: { text: 'Vibe-Labor' } }, scale: 9, style: 'banner', accent: 'lime' }, { ...plank, id: 'tiny', scale: 0.01, style: 'chip' }] })
      expect(labels[0].i18n).toEqual({ de: { text: 'Vibe-Labor' } })
      expect(labels[0].scale).toBe(4)
      expect(labels[0].style).toBe('plank')
      expect(labels[0].accent).toBeNull()
      expect(labels[0].accentRgb).toBeNull()
      expect(labels[1].scale).toBe(0.25)
      expect(labels[1].style).toBe('chip')
    })

    it('normalises the accent to six digits so every renderer reads the same colour', () => {
      const { labels } = resolveMapPlacements({ labels: [{ ...plank, accent: '#fff' }, { ...plank, id: 'b', accent: 'c0d030' }] })
      expect(labels[0].accent).toBe('#FFFFFF')
      expect(labels[0].accentRgb).toBe('255, 255, 255')
      expect(labels[1].accent).toBe('#C0D030')
    })

    it('resolves a 9-slice plank image with its caps and padding, filling in missing numbers', () => {
      const { labels } = resolveMapPlacements({ labels: [{ ...plank, plankImage: { image: 'db/campaign/c/plank.png', slice: [24, 40, 24, 40], padding: [12, 4] } }, { ...plank, id: 'bare', plankImage: { image: 'db/campaign/c/plank.png' } }, { ...plank, id: 'none', plankImage: { slice: [1, 1, 1, 1] } }] })
      expect(labels[0].plankImage).toEqual({ image: 'db/campaign/c/plank.png', slice: [24, 40, 24, 40], padding: [12, 4] })
      expect(labels[1].plankImage).toEqual({ image: 'db/campaign/c/plank.png', slice: [0, 0, 0, 0], padding: [0, 0] })
      expect(labels[2].plankImage).toBeNull()
    })

    it('names the decoration an anchored label hangs on', () => {
      const { labels } = resolveMapPlacements({ decorations: [planet], labels: [{ id: 'l', text: 'x', position: { x: 0, y: 0 }, anchor: { id: 'planet-green', offset: { x: 0, y: -62 } } }] })
      expect(labels[0].anchorId).toBe('planet-green')
    })

    it('ignores labels without an id', () => {
      expect(resolveMapPlacements({ labels: [{ text: 'x', position: { x: 1, y: 1 } }, plank] }).labels.map(l => l.id)).toEqual(['plank-green'])
    })
  })

  describe('hexToRgb', () => {
    it('reads 3- and 6-digit hex colours and rejects the rest', () => {
      expect(hexToRgb('#C0D030')).toBe('192, 208, 48')
      expect(hexToRgb('#fff')).toBe('255, 255, 255')
      expect(hexToRgb('28F8F8')).toBe('40, 248, 248')
      expect(hexToRgb('lime')).toBeNull()
      expect(hexToRgb(undefined)).toBeNull()
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

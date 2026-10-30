const Level = require('models/Level')
const LevelComponent = require('models/LevelComponent')
const LevelSession = require('models/LevelSession')
const SuperModel = require('models/SuperModel')
const ThangType = require('models/ThangType')

describe('Level hero inventory rules', function () {
  // SuperModel keys models by URL, so each one needs its own _id.
  const makeThangType = (original, kind, components) => new ThangType({ _id: original, original, kind, version: { major: 0, minor: 0 }, components })
  const makeItem = (original, config) => makeThangType(original, 'Item', [{ original: LevelComponent.ItemID, majorVersion: 0, config }])
  const heroComponents = [{ original: LevelComponent.EquipsID, majorVersion: 0, config: {} }]

  const makeSupermodel = () => {
    const supermodel = new SuperModel()
    const thangTypes = [
      makeThangType('placeholder', 'Hero', heroComponents),
      makeThangType('hero', 'Hero', heroComponents),
      makeItem('boomrod', {}),
      makeItem('rifle', { slots: ['right-hand'] }),
      makeItem('trap-belt', { slots: ['waist'] }),
      makeItem('book', { slots: ['left-hand'] }),
      makeItem('tome', { slots: ['left-hand'] }),
      makeItem('plate', { slots: ['torso'] }),
      makeItem('glove', { slots: ['gloves'] }),
      makeItem('ring', { slots: ['left-ring', 'right-ring'] }),
      makeItem('other-ring', { slots: ['left-ring', 'right-ring'] }),
    ]
    for (const thangType of thangTypes) { supermodel.registerModel(thangType) }
    return supermodel
  }

  const makeLevel = (attributes = {}, placeholderInventory) => new Level({
    type: 'hero',
    thangs: [
      {
        id: 'Hero Placeholder',
        thangType: 'placeholder',
        components: placeholderInventory ? [{ original: LevelComponent.EquipsID, majorVersion: 0, config: { inventory: placeholderInventory } }] : [],
      },
    ],
    ...attributes,
  })

  const makeSession = (inventory, attributes = {}) => new LevelSession({ heroConfig: { thangType: 'hero', inventory }, ...attributes })

  const equippedInventory = (world, thangId = 'Hero Placeholder') => {
    const thang = _.find(world.thangs, { id: thangId })
    return _.find(thang.components, { original: LevelComponent.EquipsID }).config.inventory
  }

  const equip = (inventory, level = makeLevel()) => equippedInventory(level.denormalize(makeSupermodel(), makeSession(inventory)))

  it('leaves a legal loadout alone', function () {
    const inventory = { 'right-hand': 'rifle', 'left-hand': 'book', waist: 'trap-belt', torso: 'plate', 'left-ring': 'ring', 'right-ring': 'other-ring' }
    expect(equip({ ...inventory })).toEqual(inventory)
  })

  it('drops items from slots they do not list', function () {
    expect(equip({ 'right-hand': 'boomrod', waist: 'rifle', gloves: 'trap-belt' })).toEqual({ 'right-hand': 'boomrod' })
  })

  it('treats an item with no slots config as right-hand only, like the inventory UI', function () {
    expect(equip({ 'right-hand': 'boomrod' })).toEqual({ 'right-hand': 'boomrod' })
    expect(equip({ waist: 'boomrod' })).toEqual({})
    expect(makeItem('boomrod', {}).getAllowedSlots()).toEqual(['right-hand'])
  })

  it('drops a spellbook from the flag slot', function () {
    expect(equip({ 'left-hand': 'tome', flag: 'book' })).toEqual({ 'left-hand': 'tome' })
  })

  it('keeps one copy of an item equipped in two slots, the first in schema order', function () {
    expect(equip({ 'right-ring': 'ring', 'left-ring': 'ring' })).toEqual({ 'left-ring': 'ring' })
  })

  it('checks the slot before the duplicate, so a copy in the wrong slot does not cost the legal one', function () {
    expect(equip({ head: 'plate', torso: 'plate' })).toEqual({ torso: 'plate' })
  })

  it('keeps an item whose ThangType is not loaded', function () {
    expect(equip({ feet: 'unknown-item' })).toEqual({ feet: 'unknown-item' })
  })

  it('applies in headless worlds, which ranked simulations use', function () {
    const level = makeLevel()
    level.headless = true
    expect(equip({ 'right-hand': 'boomrod', waist: 'rifle', 'left-ring': 'ring', 'right-ring': 'ring' }, level)).toEqual({ 'right-hand': 'boomrod', 'left-ring': 'ring' })
  })

  it('applies to both heroes of a ladder match', function () {
    const level = new Level({
      type: 'hero-ladder',
      thangs: [
        { id: 'Hero Placeholder', thangType: 'placeholder', components: [] },
        { id: 'Hero Placeholder 1', thangType: 'placeholder', components: [] },
      ],
    })
    const session = makeSession({ flag: 'book', 'left-ring': 'ring' }, { team: 'humans' })
    const otherSession = makeSession({ waist: 'rifle', 'left-ring': 'ring' }, { team: 'ogres' })
    const world = level.denormalize(makeSupermodel(), session, otherSession)
    expect(equippedInventory(world, 'Hero Placeholder')).toEqual({ 'left-ring': 'ring' })
    expect(equippedInventory(world, 'Hero Placeholder 1')).toEqual({ 'left-ring': 'ring' })
  })

  it('keeps gear the level grants, in whatever slot the level puts it', function () {
    const level = makeLevel({ requiredGear: { gloves: ['book'] } }, { gloves: 'book' })
    expect(equip({ waist: 'rifle' }, level)).toEqual({ gloves: 'book' })
  })

  it('does not let an illegal item satisfy the required gear of its slot', function () {
    const level = makeLevel({ requiredGear: { gloves: ['book'] } }, { gloves: 'book' })
    expect(equip({ gloves: 'rifle' }, level)).toEqual({ gloves: 'book' })
  })

  describe('building several worlds from one session', function () {
    const buildTwice = (inventory, level) => {
      const supermodel = makeSupermodel()
      const session = makeSession(inventory)
      const worlds = [level.denormalize(supermodel, session), level.denormalize(supermodel, session)]
      return { session, inventories: worlds.map(world => equippedInventory(world)) }
    }

    it('keeps a default item the level grants for restricted gear when the player has a copy in another slot', function () {
      const level = makeLevel({ restrictedGear: { 'right-ring': ['other-ring'] } }, { 'right-ring': 'ring' })
      const { inventories } = buildTwice({ 'left-ring': 'ring', 'right-ring': 'other-ring' }, level)
      const expected = { 'left-ring': 'ring', 'right-ring': 'ring' }
      expect(inventories).toEqual([expected, expected])
    })

    it('keeps a default item the level grants for restricted gear in a slot the item does not list', function () {
      const level = makeLevel({ restrictedGear: { gloves: ['glove'] } }, { gloves: 'book' })
      const { inventories } = buildTwice({ gloves: 'glove' }, level)
      expect(inventories).toEqual([{ gloves: 'book' }, { gloves: 'book' }])
    })

    it('leaves the session as the player stored it', function () {
      const level = makeLevel({ requiredGear: { gloves: ['book'] } }, { gloves: 'book' })
      const inventory = { waist: 'rifle', 'left-ring': 'ring', 'right-ring': 'ring' }
      const { session, inventories } = buildTwice({ ...inventory }, level)
      const expected = { gloves: 'book', 'left-ring': 'ring' }
      expect(inventories).toEqual([expected, expected])
      expect(session.get('heroConfig').inventory).toEqual(inventory)
    })
  })
})

// Which components on a level thang hold its existence, position, shape and
// collision config. The level editor writes the same value into every one of them so
// the world rebuild lands on the value the user chose, no matter which
// component the engine attaches last.
//
// Order matters: Level.denormalizeThang keeps the level thang's own
// components first and appends the ThangType defaults it is missing, and
// Component.attach lets the last attached component overwrite thang.pos.
// The lists returned here follow that merged order, so the last entry is the
// one whose config wins in the world.
const LevelComponent = require('models/LevelComponent')

function originalsFor (ids, levelThang, thangTypeComponents) {
  const fromLevel = ((levelThang && levelThang.components) || []).filter(c => ids.includes(c.original)).map(c => c.original)
  const fromType = (thangTypeComponents || []).filter(c => ids.includes(c.original)).map(c => c.original)
  return _.uniq(fromLevel.concat(fromType))
}

function positionOriginals (levelThang, thangTypeComponents) {
  return originalsFor(LevelComponent.positionIDs, levelThang, thangTypeComponents)
}

function shapeOriginals (levelThang, thangTypeComponents) {
  return originalsFor(LevelComponent.shapeIDs, levelThang, thangTypeComponents)
}

function collisionOriginals (levelThang, thangTypeComponents) {
  return originalsFor(LevelComponent.collisionIDs, levelThang, thangTypeComponents)
}

function existenceOriginals (levelThang, thangTypeComponents) {
  return originalsFor(LevelComponent.existenceIDs, levelThang, thangTypeComponents)
}

// The component a fresh level thang gets for one of these jobs: the CodeCombat one when the
// ThangType uses it or has none of them, otherwise the ThangType's own (PositionJS, ExistenceJS).
function essentialOriginal (ids, cocoOriginal, thangTypeComponents) {
  const fromType = originalsFor(ids, null, thangTypeComponents)
  return fromType.includes(cocoOriginal) || !fromType.length ? cocoOriginal : fromType[0]
}

// The component whose config.pos the engine ends up using: last attached wins.
function winningPositionOriginal (levelThang, thangTypeComponents) {
  return _.last(positionOriginals(levelThang, thangTypeComponents))
}

function hasDuplicatePosition (levelThang, thangTypeComponents) {
  return positionOriginals(levelThang, thangTypeComponents).length > 1
}

function configZ (component) {
  return component && component.config && component.config.pos ? component.config.pos.z : undefined
}

// Physical takes the z the editor computed (depth / 2) when pos carries one. Otherwise a component
// keeps its own z, falling back to the ThangType default it overrides (a fresh override has no pos
// yet), then 0. PositionJS has no depth, so it never takes the editor z.
function positionConfigFor (original, pos, component, defaultComponent) {
  const ownZ = configZ(component)
  const existingZ = ownZ != null ? ownZ : configZ(defaultComponent)
  const z = original === LevelComponent.PhysicalID && pos.z != null ? pos.z : existingZ
  return { x: pos.x, y: pos.y, z: z != null ? z : 0 }
}

module.exports = {
  positionOriginals,
  shapeOriginals,
  collisionOriginals,
  existenceOriginals,
  essentialOriginal,
  winningPositionOriginal,
  hasDuplicatePosition,
  positionConfigFor,
}

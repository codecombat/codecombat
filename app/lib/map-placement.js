// Placement of everything drawn on a campaign map: decorations, level and scenario markers, module portals.
// Pure: no DOM, no models. Both renderers (this one and hackstack/src/lib/map-placement.ts) implement the
// same rules, so a campaign reads the same on every map.
//
// Positions are percent of the map, bottom-left origin. A decoration's width is a fraction of the map width.
// An anchored item sits at its anchor decoration's centre plus an offset in percent of that decoration's
// width; the vertical offset is converted with the map aspect because map heights and widths differ.
// Draw order is z, then array order; the renderer emits items in that order and leaves z-index to the UI
// chrome (tooltips, popups), which stays above everything authored.

const MAP_Z = {
  background: 0,
  decoration: 1,
  connection: 2,
  marker: 3,
  label: 4,
  lifted: 5,
}

// An anchored item never draws under the decoration it hangs on.
const ANCHOR_Z_STEP = 0.1

function finiteOr (value, fallback) {
  return typeof value === 'number' && isFinite(value) ? value : fallback
}

function clampZ (z, fallback) {
  return Math.min(10, Math.max(0, finiteOr(z, fallback)))
}

// Resolves decorations first (they can anchor to each other), then the markers. Returns:
//   decorations: the visible ones, each with x, y (resolved centre), z, widthPercent and its array index
//   markers: by key, { x, y, z } for every marker passed in
// isComplete(originalOrScenarioId) answers showIf; a missing anchor id or a cycle falls back to the item's
// own position.
function resolveMapPlacements ({ decorations = [], markers = [], mapAspect = 1.5, isComplete = () => false } = {}) {
  const byId = {}
  decorations.forEach((decoration, index) => {
    if (decoration && typeof decoration.id === 'string') { byId[decoration.id] = { decoration, index } }
  })
  const resolved = {}

  const resolveDecoration = (id, trail) => {
    if (resolved[id]) { return resolved[id] }
    const entry = byId[id]
    if (!entry) { return null }
    const { decoration, index } = entry
    const width = finiteOr(decoration.width, 0.1)
    const own = {
      x: finiteOr(decoration.position?.x, 0),
      y: finiteOr(decoration.position?.y, 0),
      z: clampZ(decoration.z, MAP_Z.decoration),
    }
    let placed = own
    const anchor = decoration.anchor
    if (anchor && typeof anchor.id === 'string' && anchor.id !== id && !trail.includes(anchor.id)) {
      const parent = resolveDecoration(anchor.id, trail.concat(id))
      if (parent) { placed = anchoredPosition(parent, anchor.offset, own.z, mapAspect) }
    }
    resolved[id] = {
      id,
      index,
      x: placed.x,
      y: placed.y,
      z: placed.z,
      width,
      widthPercent: width * 100,
      rotation: finiteOr(decoration.rotation, 0),
      opacity: Math.min(1, Math.max(0, finiteOr(decoration.opacity, 1))),
      image: decoration.image,
      showIf: decoration.showIf,
    }
    return resolved[id]
  }

  Object.keys(byId).forEach(id => resolveDecoration(id, []))

  const visibleDecorations = Object.values(resolved)
    .filter(d => !d.showIf || !d.showIf.level || isComplete(d.showIf.level))
    .sort((a, b) => a.index - b.index)

  const markerPlacements = {}
  for (const marker of markers) {
    if (!marker || marker.key == null) { continue }
    const own = {
      x: finiteOr(marker.position?.x, 0),
      y: finiteOr(marker.position?.y, 0),
      z: clampZ(marker.z, MAP_Z.marker),
    }
    const anchor = marker.anchor
    const parent = anchor && typeof anchor.id === 'string' ? resolved[anchor.id] : null
    markerPlacements[marker.key] = parent ? anchoredPosition(parent, anchor.offset, own.z, mapAspect) : own
  }

  return { decorations: visibleDecorations, markers: markerPlacements }
}

// Offset is percent of the anchor's width on both axes; width is a fraction of the map width, so the
// horizontal move is offset.x * width (in percent of map width) and the vertical move is the same length
// expressed in percent of map height, hence the aspect factor.
function anchoredPosition (parent, offset, ownZ, mapAspect) {
  const ox = finiteOr(offset?.x, 0)
  const oy = finiteOr(offset?.y, 0)
  return {
    x: parent.x + ox * parent.width,
    y: parent.y + oy * parent.width * mapAspect,
    z: Math.max(ownZ, parent.z + ANCHOR_Z_STEP),
  }
}

// The inverse of anchoredPosition, for the editor: a dragged anchored item keeps its anchor and gets a new offset.
function offsetForPosition (parent, position, mapAspect) {
  return {
    x: (position.x - parent.x) / parent.width,
    y: (position.y - parent.y) / (parent.width * mapAspect),
  }
}

// Sort key for drawing: z first, then the order the renderer assigned (array order within a kind).
function byDrawOrder (a, b) {
  return (a.z - b.z) || (a.order - b.order)
}

module.exports = { MAP_Z, resolveMapPlacements, anchoredPosition, offsetForPosition, byDrawOrder }

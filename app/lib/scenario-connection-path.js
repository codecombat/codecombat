// Scenario connections on a graph-map HackStack campaign are drawn by hackstack
// (src/components/game/LevelConnections.tsx) as quadratic curves in a 100x100 viewBox
// stretched over the map image. The campaign editor draws the same curve so authors
// see the line players get. Keep the numbers here in step with that file.
const PERCENT_FULL = 100
const CURVATURE = 0.18 // control-point offset relative to the segment length
const MIN_BOW = 4
const MAX_BOW = 22

// Positions are percent of the map with y from the bottom; the path is in viewBox units with y from the top.
function toSvg (position) {
  return { x: position.x, y: PERCENT_FULL - position.y }
}

function controlPoint (p1, p2, curveSide) {
  const dx = p2.x - p1.x
  const dy = p2.y - p1.y
  const length = Math.hypot(dx, dy) || 1
  const mx = (p1.x + p2.x) / 2
  const my = (p1.y + p2.y) / 2
  let side
  if (curveSide === 'left') {
    side = -1
  } else if (curveSide === 'right') {
    side = 1
  } else {
    const centre = PERCENT_FULL / 2
    const cross = dx * (my - centre) - dy * (mx - centre)
    side = cross >= 0 ? 1 : -1
  }
  const bow = Math.max(MIN_BOW, Math.min(MAX_BOW, CURVATURE * length)) * side
  return { x: mx + (-dy / length) * bow, y: my + (dx / length) * bow }
}

function scenarioConnectionPath (from, to, curveSide) {
  const p1 = toSvg(from)
  const p2 = toSvg(to)
  const c = controlPoint(p1, p2, curveSide)
  return `M ${p1.x},${p1.y} Q ${c.x},${c.y} ${p2.x},${p2.y}`
}

module.exports = { PERCENT_FULL, scenarioConnectionPath }

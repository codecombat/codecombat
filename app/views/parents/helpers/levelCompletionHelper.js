export function getProgressStatusHelper (levelSessions, { slug, fromIntroLevelOriginal }) {
  let status = 'not-started'
  if (!levelSessions || (!slug && !fromIntroLevelOriginal)) return status
  const ls = levelSessions.filter(ls => ls.levelID === slug || (fromIntroLevelOriginal && ls?.level?.original === fromIntroLevelOriginal))
  if (ls.length) status = 'in-progress'
  ls.forEach(session => {
    if (session.state.complete) status = 'complete'
  })
  return status
}

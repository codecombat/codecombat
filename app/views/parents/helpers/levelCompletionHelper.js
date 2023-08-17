import Level from '../../../models/Level'

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

export function getStudentCode (levelSession) {
  if (levelSession?.code?.['hero-placeholder']?.plan) {
    return { codeLanguage: levelSession.codeLanguage, code: levelSession?.code?.['hero-placeholder']?.plan }
  } else if (levelSession?.code?.['hero-placeholder-1']?.plan) {
    return { codeLanguage: levelSession.codeLanguage, code: levelSession?.code?.['hero-placeholder-1']?.plan }
  }
  return null
}

export function getSolutionCode (level, { lang = null }) {
  const solutions = getSolutions(level)
  console.log('sol', level, solutions, lang)
  if (lang) {
    const sol = solutions.find(s => s.language === lang)
    if (sol) return sol.source
  }
  return solutions.length ? solutions[0].source : null
}

export function getStudentAndSolutionCode (level, levelSessions) {
  const ls = levelSessions.find(ls => ls.levelID === level.slug)
  const studentCodeObj = getStudentCode(ls)
  const solutionCode = getSolutionCode(level, { lang: studentCodeObj?.codeLanguage })

  return { studentCode: studentCodeObj?.code, solutionCode }
}

function getSolutions (level) {
  const levelModel = new Level(level)
  return levelModel.getSolutions()
}

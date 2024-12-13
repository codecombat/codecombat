import utils from '../../../../../app/core/utils'

export function getLevelUrl ({ ozariaType, introLevelSlug, courseId, codeLanguage, slug, introContent, moduleNum, _id }) {
  if (courseId === utils.courseIDs.HACKSTACK) {
    return `/ai/scenario/${_id}`
  } else if (utils.isOzaria && !ozariaType && introLevelSlug) {
    return `/play/intro/${introLevelSlug}?course=${courseId}&codeLanguage=${codeLanguage}&intro-content=${introContent || 0}`
  } else if (slug) {
    let url = `/play/level/${slug}?course=${courseId}&codeLanguage=${codeLanguage}`
    if (courseId === utils.courseIDs.JUNIOR) {
      if (moduleNum <= 4) {
        url += '&codeFormat=blocks-icons'
      } else {
        url += '&codeFormat=blocks-text'
      }
    }
    return url
  }
  return null
}

export function getCurriculumGuideContentList ({ introLevels, moduleInfo, moduleNum, currentCourseId, codeLanguage }) {
  const curriculumGuideContentList = []
  let lastIntroLevelSlug = null
  for (const content of moduleInfo?.[moduleNum] || []) {
    const {
      type,
      ozariaType,
      introLevelSlug,
      fromIntroLevelOriginal,
      slug,
      introContent,
      _id,
    } = { type: content.practice ? 'practicelvl' : 'challengelvl', ...content }

    // Potentially this intro doesn't have a header in the curriculum guide yet
    if (introLevelSlug &&
      type !== 'cutscene' &&
      lastIntroLevelSlug !== introLevelSlug
    ) {
      curriculumGuideContentList.push({
        isIntroHeadingRow: true,
        name: utils.i18n(introLevels[fromIntroLevelOriginal], 'displayName'),
        icon: 'intro',
        _id: content._id,
      })
      lastIntroLevelSlug = introLevelSlug
    }

    let icon

    // TODO: Where is the language chosen in the curriculum guide?

    if (!ozariaType) {
      icon = type
      if (content.shareable === 'project') {
        icon = 'capstone'
      } else if (content.practice) {
        icon = 'practicelvl'
      }
    } else if (ozariaType) {
      if (ozariaType === 'practice') {
        icon = 'practicelvl'
      } else if (ozariaType === 'capstone') {
        icon = 'capstone'
      } else if (ozariaType === 'challenge') {
        icon = 'challengelvl'
      }
    }

    if (currentCourseId === utils.courseIDs.HACKSTACK) {
      icon = utils.scenarioMode2Icon(content.mode)
    }

    // todo: hackstack url
    const url = getLevelUrl({ ozariaType, introLevelSlug, courseId: currentCourseId, codeLanguage, slug, introContent, moduleNum, _id })

    if (!url || !icon) {
      console.error('missing url or icon in curriculum guide')
    }
    curriculumGuideContentList.push({
      icon,
      name: utils.i18n(content, 'displayName') || utils.i18n(content, 'name'),
      _id,
      description: getContentDescription(content),
      url,
      // Handle edge case that cutscenes are always in their own one to one intro
      isPartOfIntro: !!introLevelSlug && icon !== 'cutscene',
      isIntroHeadingRow: false,
      slug,
      fromIntroLevelOriginal,
      original: content.original,
      assessment: content.assessment,
      tool: content.tool,
    })
  }
  return curriculumGuideContentList
}

export function generateLevelNumberMap (contentTypes) {
  const levels = contentTypes
    .map(({ original, assessment, icon, _id, practice, isIntroHeadingRow }) => {
      let key = original
      if (isIntroHeadingRow) return null
      if (isOzariaNoCodeLevelHelper(icon)) {
        key = _id
      }
      return {
        _id,
        original,
        key,
        assessment,
        practice: practice || (icon === 'practicelvl'),
      }
    }).filter(Boolean)

  const levelNumberMap = utils.createLevelNumberMap(levels)
  contentTypes.forEach((level) => {
    const original = level.original || level.fromIntroLevelOriginal
    if (!levelNumberMap[original]) {
      levelNumberMap[original] = levelNumberMap[level._id]
    }
  })

  return levelNumberMap
}

function getContentDescription (content) {
  return utils.i18n((content?.documentation?.specificArticles || []).find(({ name }) => name === 'Learning Goals'), 'body') ||
    utils.i18n(content, 'description') ||
    ''
}

export function isOzariaNoCodeLevelHelper (icon) {
  return ['cutscene', 'cinematic', 'interactive'].includes(icon)
}

import utils from '../../../../../app/core/utils'

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
      _id
    } = content

    // Potentially this intro doesn't have a header in the curriculum guide yet
    if (introLevelSlug &&
      type !== 'cutscene' &&
      lastIntroLevelSlug !== introLevelSlug
    ) {
      curriculumGuideContentList.push({
        isIntroHeadingRow: true,
        name: utils.i18n(introLevels[fromIntroLevelOriginal], 'displayName'),
        icon: 'intro'
      })
      lastIntroLevelSlug = introLevelSlug
    }

    let icon, url

    // TODO: Where is the language chosen in the curriculum guide?
    if (!ozariaType) {
      icon = type
      url = `/play/intro/${introLevelSlug}?course=${currentCourseId}&codeLanguage=${codeLanguage}&intro-content=${introContent || 0}`
    } else if (ozariaType) {
      if (ozariaType === 'practice') {
        icon = 'practicelvl'
      } else if (ozariaType === 'capstone') {
        icon = 'capstone'
      } else if (ozariaType === 'challenge') {
        icon = 'challengelvl'
      }
      url = `/play/level/${slug}?course=${currentCourseId}&codeLanguage=${codeLanguage}`
    }

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
      fromIntroLevelOriginal
    })
  }
  console.log('c', curriculumGuideContentList)
  return curriculumGuideContentList
}

function getContentDescription (content) {
  return utils.i18n((content?.documentation?.specificArticles || []).find(({ name }) => name === 'Learning Goals'), 'body') ||
    utils.i18n(content, 'description') ||
    ''
}

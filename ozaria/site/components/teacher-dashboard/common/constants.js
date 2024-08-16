
// name of the vue component of each teacher dashboard page - used for fetching relevant data in teacherDashboard vuex store
export const COMPONENT_NAMES = {
  MY_CLASSES_ALL: 'BaseMyClasses',
  MY_CLASSES_SINGLE: 'BaseSingleClass',
  STUDENT_PROJECTS: 'BaseStudentProjects',
  MY_LICENSES: 'BaseTeacherLicenses',
  RESOURCE_HUB: 'BaseResourceHub',
  PD: 'PD',
  STUDENT_ASSESSMENTS: 'BaseStudentAssessments',
  AI_JUNIOR: 'BaseAIJunior',
  AI_LEAGUE: 'AILeague',
  CURRICULUM_GUIDE: 'BaseCurriculumGuide'
}

export const PAGE_TITLES = {
  [COMPONENT_NAMES.MY_CLASSES_ALL]: 'all_classes',
  [COMPONENT_NAMES.MY_LICENSES]: 'my_licenses',
  [COMPONENT_NAMES.RESOURCE_HUB]: 'resource_hub',
  [COMPONENT_NAMES.PD]: 'pd',
  [COMPONENT_NAMES.AI_LEAGUE]: 'ai_league',
  [COMPONENT_NAMES.APCSP]: 'apcsp',
  [COMPONENT_NAMES.CURRICULUM_GUIDE]: 'curriculum_guide'
}

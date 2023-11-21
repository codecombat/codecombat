
// name of the vue component of each teacher dashboard page - used for fetching relevant data in teacherDahsboard vuex store
export const COMPONENT_NAMES = {
  MY_CLASSES_ALL: 'BaseMyClasses',
  MY_CLASSES_SINGLE: 'BaseSingleClass',
  STUDENT_PROJECTS: 'BaseStudentProjects',
  MY_LICENSES: 'BaseTeacherLicenses',
  RESOURCE_HUB: 'BaseResourceHub',
  PD: 'PD',
  STUDENT_ASSESSMENTS: 'BaseStudentAssessments'
  // CURRICULUM_GUIDE: 'BaseCurriculumGuide'
}

export const PAGE_TITLES = {
  [COMPONENT_NAMES.MY_CLASSES_ALL]: 'all_classes',
  [COMPONENT_NAMES.MY_LICENSES]: 'my_licenses',
  [COMPONENT_NAMES.RESOURCE_HUB]: 'resource_hub',
  [COMPONENT_NAMES.PD]: 'pd'
}

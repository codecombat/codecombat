
// name of the vue component of each teacher dashboard page - used for fetching relevant data in teacherDahsboard vuex store
export const COMPONENT_NAMES = {
  MY_CLASSES_ALL: 'BaseMyClasses',
  MY_CLASSES_SINGLE: 'BaseSingleClass',
  STUDENT_PROJECTS: 'BaseStudentProjects',
  MY_LICENSES: 'BaseTeacherLicenses',
  RESOURCE_HUB: 'BaseResourceHub'
  // CURRICULUM_GUIDE: 'BaseCurriculumGuide'
}

export const resourceHubLinks = {
  dashboardTutorial: {
    icon: 'Video',
    label: 'Dashboard Tutorial',
    resourceHubSection: 'gettingStarted'
  },
  howtoCurrGuide: {
    icon: 'Slides',
    label: 'How To: Curriculum Guide',
    link: 'https://docs.google.com/presentation/d/154Fo1d8nVWNBqxx7m_KFSmJ_zyDiMomxKBbK04lMZzg/edit?usp=sharing',
    resourceHubSection: 'gettingStarted'
  },
  howToLicenses: {
    icon: 'Slides',
    label: 'How To: Manage Licenses',
    link: 'https://docs.google.com/presentation/d/1SfM5ZMjae8wm8HESHoXXO0wBnKJmJD53BgtG9XwVW9k/edit?usp=sharing',
    resourceHubSection: 'gettingStarted'
  },
  howToProjects: {
    icon: 'Slides',
    label: 'How To: Student Projects',
    link: 'https://docs.google.com/presentation/d/1KzxUPJ8bbRVSLuesDmhJ22gtzJJ761vgJiZsbYms6oM/edit?usp=sharing',
    resourceHubSection: 'gettingStarted'
  },
  howToProgress: {
    icon: 'Slides',
    label: 'How To: Track Progress',
    link: 'https://docs.google.com/presentation/d/160gl6XT-B3_cd7iKkYOtPVJ2JxEspbenxJXAhqm_TFo/edit?usp=sharing',
    resourceHubSection: 'gettingStarted'
  },
  faq: {
    icon: 'FAQ',
    label: 'Frequently Asked Questions',
    link: '/teachers/resources/faq',
    resourceHubSection: 'gettingStarted'
  },
  pathways: {
    icon: 'Doc',
    label: 'Ozaria & CodeCombat Pathways',
    link: 'https://docs.google.com/drawings/d/1Py8lBN3uGjrvsHdm_2wnO7T0wLPYEW0PCJ7XsMVHEYo/edit?usp=sharing',
    resourceHubSection: 'educatorResources'
  },
  csta: {
    icon: 'Doc',
    label: 'CSTA Standards Alignment',
    link: 'https://docs.google.com/document/d/1sHP75V5WqdQBfavI792mswYDS67pSSf8otNM05Rma5A/edit?usp=sharing',
    resourceHubSection: 'educatorResources'
  },
  distanceLearning: {
    icon: 'Slides',
    label: 'Distance Learning Strategies',
    link: 'https://docs.google.com/presentation/d/1-27EBwUUHn6YdzWzyb5LzZI6OfutxOVtbqEMB2Swbj0/edit?usp=sharing',
    resourceHubSection: 'educatorResources'
  },
  scopeSequence: {
    icon: 'Spreadsheet',
    label: 'Scope & Sequence',
    link: 'https://docs.google.com/spreadsheets/d/1S7qS2zxVccBMVNUQ0Duh6ugyQfhqopGKaSXyhCf-5UA/edit?usp=sharing',
    resourceHubSection: 'educatorResources'
  }
}

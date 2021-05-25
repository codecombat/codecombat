
// name of the vue component of each teacher dashboard page - used for fetching relevant data in teacherDahsboard vuex store
export const COMPONENT_NAMES = {
  MY_CLASSES_ALL: 'BaseMyClasses',
  MY_CLASSES_SINGLE: 'BaseSingleClass',
  STUDENT_PROJECTS: 'BaseStudentProjects',
  MY_LICENSES: 'BaseTeacherLicenses',
  RESOURCE_HUB: 'BaseResourceHub',
  PD: 'PD'
  // CURRICULUM_GUIDE: 'BaseCurriculumGuide'
}

export const PAGE_TITLES = {
  [COMPONENT_NAMES.MY_CLASSES_ALL]: 'all_classes',
  [COMPONENT_NAMES.MY_LICENSES]: 'my_licenses',
  [COMPONENT_NAMES.RESOURCE_HUB]: 'resource_hub',
  [COMPONENT_NAMES.PD]: 'pd'
}

// TODO: Remove these once they are added to the database.
// If you want to add a new resource please add it as a ResourceHubResource in the db.
export const resourceHubLinks = {
  dashboardTutorial: {
    icon: 'Video',
    name: 'Dashboard Tutorial',
    section: 'gettingStarted'
  },
  howtoContentLocking: {
    icon: 'Slides',
    name: 'How To: Control Student Pacing',
    link: 'https://docs.google.com/presentation/d/1jAs_w8RjqbCtCQRGGI2_pRiZGar8rcNjEBcSFUYMF6c/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howtoCreateClass: {
    icon: 'Slides',
    name: 'How To: Create Classes & Add Students',
    link: 'https://docs.google.com/presentation/d/1ZmHMo_v7MenQ-LHnvG27dua7d8toBAvoJBwbS2ZN4jc/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howtoCurrGuide: {
    icon: 'Slides',
    name: 'How To: Curriculum Guide',
    link: 'https://docs.google.com/presentation/d/154Fo1d8nVWNBqxx7m_KFSmJ_zyDiMomxKBbK04lMZzg/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howToLicenses: {
    icon: 'Slides',
    name: 'How To: Manage Licenses',
    link: 'https://docs.google.com/presentation/d/1SfM5ZMjae8wm8HESHoXXO0wBnKJmJD53BgtG9XwVW9k/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howToShareLesson: {
    icon: 'Doc',
    name: 'How To: Share Lesson & Activity Slides',
    link: 'https://docs.google.com/document/d/1JTshzRvg_EGEDY7Kczb5T0X8WKmS0UXTdWZVmvzE9B0/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howToProjects: {
    icon: 'Slides',
    name: 'How To: Student Projects',
    link: 'https://docs.google.com/presentation/d/1KzxUPJ8bbRVSLuesDmhJ22gtzJJ761vgJiZsbYms6oM/edit?usp=sharing',
    section: 'gettingStarted'
  },
  howToProgress: {
    icon: 'Slides',
    name: 'How To: Track Progress',
    link: 'https://docs.google.com/presentation/d/160gl6XT-B3_cd7iKkYOtPVJ2JxEspbenxJXAhqm_TFo/edit?usp=sharing',
    section: 'gettingStarted'
  },
  faq: {
    icon: 'FAQ',
    name: 'Frequently Asked Questions',
    link: '/teachers/resources/faq',
    section: 'gettingStarted'
  },
  pathways: {
    icon: 'Doc',
    name: 'Ozaria & CodeCombat Pathways',
    link: 'https://docs.google.com/drawings/d/1Py8lBN3uGjrvsHdm_2wnO7T0wLPYEW0PCJ7XsMVHEYo/edit?usp=sharing',
    section: 'educatorResources'
  },
  csta: {
    icon: 'Doc',
    name: 'CSTA Standards Alignment',
    link: 'https://docs.google.com/document/d/1sHP75V5WqdQBfavI792mswYDS67pSSf8otNM05Rma5A/edit?usp=sharing',
    section: 'educatorResources'
  },
  distanceLearning: {
    icon: 'Slides',
    name: 'Distance Learning Strategies',
    link: 'https://docs.google.com/presentation/d/1-27EBwUUHn6YdzWzyb5LzZI6OfutxOVtbqEMB2Swbj0/edit?usp=sharing',
    section: 'educatorResources'
  },
  isteStandardsAlignment: {
    icon: 'Doc',
    name: 'ISTE Standards Alignment',
    link: 'https://docs.google.com/document/d/1Nx7lIXyI5mMU_tB9HgPOqdEtzMcpDgXZE_RGjVaMN5o/edit?usp=sharing',
    section: 'educatorResources'
  },
  pacingGuide: {
    icon: 'Spreadsheet',
    name: 'Pacing Guide',
    link: 'https://docs.google.com/spreadsheets/d/1EbWMXI1-0697csaM_NCZLUWvJKed5ayFGlC73I7rztk/edit?usp=sharing',
    section: 'educatorResources'
  },
  scopeSequence: {
    icon: 'Spreadsheet',
    name: 'Scope & Sequence',
    link: 'https://docs.google.com/spreadsheets/d/1S7qS2zxVccBMVNUQ0Duh6ugyQfhqopGKaSXyhCf-5UA/edit?usp=sharing',
    section: 'educatorResources'
  }
}

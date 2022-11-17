// name of the vue component of each dashboard page - used for fetching relevant data in schoolAdminDashboard vuex store
export const COMPONENT_NAMES = {
  MY_SCHOOLS: 'BaseMySchools',
  SCHOOL_ADMIN_LICENSES: 'BaseSchoolAdminLicenses',
  ADMINISTERED_TEACHERS: {
    ALL_CLASSES: 'BaseTeacherAllClasses',
    CLASS_PROGRESS: 'BaseTeacherClassProgress',
    CLASS_PROJECTS: 'BaseTeacherClassProjects',
    TEACHER_LICENSES: 'BaseTeacherLicenses'
  }
}

export const PAGE_TITLES = {
  [COMPONENT_NAMES.MY_SCHOOLS]: 'My Schools',
  [COMPONENT_NAMES.SCHOOL_ADMIN_LICENSES]: 'Admin Licenses'
}

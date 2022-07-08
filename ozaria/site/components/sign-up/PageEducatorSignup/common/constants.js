export const EDUCATOR_ROLES = {
  TEACHER: {
    value: 'Teacher',
    i18n: 'teachers_quote.teacher'
  },
  PARENT: {
    value: 'Parent',
    i18n: 'teachers_quote.parent'
  },
  PRINCIPAL: {
    value: 'Principal',
    i18n: 'teachers_quote.principal'
  },
  TECH_COORD: {
    value: 'Technology Coordinator',
    i18n: 'teachers_quote.tech_coordinator'
  },
  CURR_SPEC_ADV: {
    value: 'Advisor',
    i18n: 'teachers_quote.advisor'
  },
  SUPERIN: {
    value: 'Superintendent',
    i18n: 'teachers_quote.superintendent'
  }
}

export const COUNTRIES = {
  US: 'United States',
  CHINA: 'China'
}

export const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students']
export const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone'])

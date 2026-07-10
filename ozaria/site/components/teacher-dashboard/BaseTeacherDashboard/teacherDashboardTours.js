function createStepWithFallbackAttaches (attaches, config) {
  return {
    ...config,
    beforeShowPromise: function () {
      return new Promise((resolve) => {
        // Try selectors in order
        let existedAttach = null
        for (const attach of attaches) {
          const element = document.querySelector(attach.element)
          if (element) {
            existedAttach = attach
            break
          }
        }
        this.attachTo = existedAttach || attaches[attaches.length - 1]
        resolve()
      })
    },
  }
}
const PLAN_FIRST_CLASS_STEP = {
  attachTo: {
    element: '#GuideDropdown',
    on: 'right',
  },
  text: () => {
    const planYourClassDiv = document.createElement('div')
    planYourClassDiv.innerHTML = `
      <ul>
        <li>${$.i18n.t('teacher_dashboard.plan_your_class1')}</li>
        <li>${$.i18n.t('teacher_dashboard.plan_your_class2')}</li>
        <li>${$.i18n.t('teacher_dashboard.plan_your_class3')}</li>
      </ul>
      `
    return planYourClassDiv
  },
  title: `${$.i18n.t('teacher_dashboard.plan_your_class_title')}:`,
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const TEACHER_TOOLKIP_STEP = {
  attachTo: {
    element: '#TeacherToolDropdown',
    on: 'right',
  },
  text: $.i18n.t('teacher_dashboard.teacher_toolkit_tour_desc'),
  title: $.i18n.t('teacher_dashboard.teacher_toolkit_tour_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('teacher_dashboard.click_dismiss'),
  }],
}

const CLICK_INTO_CLASS_STEP = {
  attachTo: {
    element: '#class-header-shepherd',
    on: 'top',
  },
  advanceOn: {
    selector: '#class-header-shepherd',
    event: 'click',
  },
  text: $.i18n.t('teacher_dashboard.track_progress_desc'),
  title: $.i18n.t('teacher_dashboard.track_progress'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const ADD_STUDENTS_STEP = {
  attachTo: {
    element: '.add-students-icon-btn',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.add_students_step_desc'),
  title: $.i18n.t('teacher_dashboard.add_students_step_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const TEST_STUDENT_STEP = {
  attachTo: {
    element: '#nav-student-mode',
    on: 'left',
  },
  text: $.i18n.t('teacher_dashboard.test_student_step_desc'),
  title: $.i18n.t('teacher_dashboard.test_student_step_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('teacher_dashboard.click_dismiss'),
  }],
  beforeShowPromise: function () {
    return new Promise((resolve) => {
      document.querySelector('#user-account-dropdown .dropdown-menu').style.display = 'block'
      setTimeout(resolve, 100)
    })
  },
  when: {
    destroy: function () {
      document.querySelector('#user-account-dropdown .dropdown-menu').style.display = 'none'
    },
    cancel: function () {
      document.querySelector('#user-account-dropdown .dropdown-menu').style.display = 'none'
    },
  },
}

const CREATE_CLASS_STEP = {
  attachTo: {
    element: '#new-class-btn-shepherd',
    on: 'top',
  },
  text: $.i18n.t('teacher_dashboard.add_classes'),
  title: $.i18n.t('teacher_dashboard.add_classes_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const AI_LEAGUE_START = {
  attachTo: {
    element: '#getting-started-guide',
    on: 'left',
  },
  text: $.i18n.t('teacher_dashboard.ai_league_start_blurb'),
  title: $.i18n.t('teacher_dashboard.ai_league_start_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const AI_LEAGUE_CURRICULUM = {
  attachTo: {
    element: '#ai-league-curriculum',
    on: 'left',
  },
  text: $.i18n.t('teacher_dashboard.ai_league_curriculum_blurb'),
  title: $.i18n.t('teacher_dashboard.ai_league_curriculum_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}
const AI_LEAGUE_CUSTOM = {
  attachTo: {
    element: '#custom-button',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.ai_league_custom_blurb'),
  title: $.i18n.t('teacher_dashboard.ai_league_custom_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('teacher_dashboard.click_dismiss'),
  }],
}

const WELCOME_STEP = {
  text: $.i18n.t('teacher_dashboard.welcome_tour_desc'),
  title: $.i18n.t('teacher_dashboard.welcome_tour_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const ALL_STUDENTS_STEP = {
  attachTo: {
    element: '.allStudents',
    on: 'right',
  },
  text: $.i18n.t('teacher_dashboard.all_students_desc'),
  title: $.i18n.t('teacher_dashboard.all_students_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const CONTENT_SYMBOL_STEP = {
  attachTo: {
    element: '.moduleHeading .content-icons',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.content_symbol_desc'),
  title: $.i18n.t('teacher_dashboard.content_symbol_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const PROGRESS_DOT_STEP = createStepWithFallbackAttaches([
  {
    element: '.golden-backer .dot:first-child',
    on: 'bottom',
  },
  {
    element: '#module-grid',
    on: 'top',
  },
], {
  attachTo: {
    element: '',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.progress_dot_desc'),
  title: $.i18n.t('teacher_dashboard.progress_dot_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
})

const ASSIGN_CONTENT_STEP = {
  attachTo: {
    element: '#grant-course-btn',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.assign_content_desc'),
  title: $.i18n.t('teacher_dashboard.assign_content_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const APPLY_LICENSES_STEP = {
  attachTo: {
    element: '#apply-license-btn',
    on: 'bottom',
  },
  showOn: function () {
    return !!document.querySelector('#apply-license-btn')
  },
  text: $.i18n.t('teacher_dashboard.apply_licenses_desc'),
  title: $.i18n.t('teacher_dashboard.apply_licenses_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
}

const LOCK_CONTENT_STEP = {
  attachTo: {
    element: '.moduleHeading .v-popover .btn',
    on: 'bottom',
  },
  text: $.i18n.t('teacher_dashboard.lock_content_desc'),
  title: $.i18n.t('teacher_dashboard.lock_content_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next'),
  }],
  beforeShowPromise: function () {
    return new Promise((resolve) => {
      // Trigger the popover to show
      const parent = document.querySelector('.moduleHeading .title')
      const popover = parent?.querySelector('.v-popover')
      if (popover) {
        popover.style.display = 'block'
      }
      setTimeout(resolve, 100)
    })
  },
  when: {
    hide: function () {
      // Clean up: hide the popover when step ends
      const parent = document.querySelector('.moduleHeading .title')
      const popover = parent?.querySelector('.v-popover')
      if (popover) {
        popover.style.display = ''
      }
    },
  },
}

const TOUR_REPLAY_STEP = {
  attachTo: {
    element: '#replay-tour-btn',
    on: 'right',
  },
  text: $.i18n.t('teacher_dashboard.tour_replay_desc'),
  title: $.i18n.t('teacher_dashboard.tour_replay_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('teacher_dashboard.click_dismiss'),
  }],
}

export const HS_GUIDE_TOUR_STEPS = [
  WELCOME_STEP,
  ALL_STUDENTS_STEP,
  CONTENT_SYMBOL_STEP,
  PROGRESS_DOT_STEP,
  ASSIGN_CONTENT_STEP,
  APPLY_LICENSES_STEP,
  LOCK_CONTENT_STEP,
  TOUR_REPLAY_STEP,
]

export const FIRST_CLASS_STEPS = [
  CLICK_INTO_CLASS_STEP,
  ADD_STUDENTS_STEP,
  TEST_STUDENT_STEP,
]

export const CREATE_CLASS_STEPS = [
  CREATE_CLASS_STEP,
  PLAN_FIRST_CLASS_STEP,
  TEACHER_TOOLKIP_STEP,
]

export const AI_LEAGUE_STEPS = [
  AI_LEAGUE_START,
  AI_LEAGUE_CURRICULUM,
  AI_LEAGUE_CUSTOM,
]

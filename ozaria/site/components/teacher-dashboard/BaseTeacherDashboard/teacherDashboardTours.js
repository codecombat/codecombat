const PLAN_FIRST_CLASS_STEP = {
  attachTo: {
    element: '#curriculum-guide-btn-shepherd',
    on: 'top'
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
    text: $.i18n.t('teacher_dashboard.click_dismiss')
  }]
}

const CLICK_INTO_CLASS_STEP = {
  attachTo: {
    element: '#class-header-shepherd',
    on: 'top'
  },
  advanceOn: {
    selector: '#class-header-shepherd',
    event: 'click'
  },
  text: $.i18n.t('teacher_dashboard.track_progress_desc'),
  title: $.i18n.t('teacher_dashboard.track_progress'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next')
  }]
}

const CREATE_CLASS_STEP = {
  attachTo: {
    element: '#new-class-btn-shepherd',
    on: 'top'
  },
  text: $.i18n.t('teacher_dashboard.add_classes'),
  title: $.i18n.t('teacher_dashboard.add_classes_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.i18n.t('common.next')
  }]
}

export const FIRST_CLASS_STEPS = [
  CLICK_INTO_CLASS_STEP,
  PLAN_FIRST_CLASS_STEP
]

export const CREATE_CLASS_STEPS = [
  CREATE_CLASS_STEP,
  PLAN_FIRST_CLASS_STEP
]

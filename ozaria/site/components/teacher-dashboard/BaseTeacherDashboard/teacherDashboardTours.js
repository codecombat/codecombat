const PLAN_FIRST_CLASS_STEP = {
  attachTo: {
    element: '#curriculum-guide-btn-shepherd',
    on: 'top'
  },
  text: () => {
    const planYourClassDiv = document.createElement('div')
    planYourClassDiv.innerHTML = `
      <ul>
        <li>${$.t('teacher_dashboard.plan_your_class1')}</li>
        <li>${$.t('teacher_dashboard.plan_your_class2')}</li>
        <li>${$.t('teacher_dashboard.plan_your_class3')}</li>
      </ul>
      `
    return planYourClassDiv
  },
  title: `${$.t('teacher_dashboard.plan_your_class_title')}:`,
  buttons: [{
    action () {
      return this.next()
    },
    text: $.t('teacher_dashboard.click_dismiss')
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
  text: $.t('teacher_dashboard.track_progress_desc'),
  title: $.t('teacher_dashboard.track_progress'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.t('common.next')
  }]
}

const CREATE_CLASS_STEP = {
  attachTo: {
    element: '#new-class-btn-shepherd',
    on: 'top'
  },
  text: $.t('teacher_dashboard.add_classes'),
  title: $.t('teacher_dashboard.add_classes_title'),
  buttons: [{
    action () {
      return this.next()
    },
    text: $.t('common.next')
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

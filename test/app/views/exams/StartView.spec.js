/*
import { shallowMount, createLocalVue } from '@vue/test-utils'
import startView from 'views/exams/StartPage'
import locale from 'locale/locale'
import Vuex from 'vuex'
import { nextTick } from 'vue'

const localVue = createLocalVue()
localVue.use(Vuex)

const EXAM = {
  _id: '-',
  title: 'MTO Fake Exam',
  startDate: new Date('2024-10-01').toISOString(),
  endDate: new Date('2024-11-01').toISOString(),
  duration: 120,
  problems: [
    {
      courseId: '560f1a9f22961295f9427742', // cs1
      instanceId: '560f1a9f22961295f9427742',
      levels: [
        {
          slug: 'long-steps',
        },
      ],
    },
    {
      courseId: '56462f935afde0c6fd30fc8c', // cs3
      instanceId: '56462f935afde0c6fd30fc8c',
      levels: [
        {
          slug: 'rich-and-safe',
        },
      ],
    },
  ],
}
const createComponent = (values = {}, store) => {
  return shallowMount(startView, {
    propsData: values,
    store,
    localVue,
    mocks: {
      $t: (text) => {
        if (text.includes('.')) {
          const res = text.split('.')
          return locale.en.translation[res[0]][res[1]]
        } else {
          return locale.en.translation[text]
        }
      },
    },
    stubs: ['router-link', 'router-view'],
  })
}

describe('In startPage', () => {
  let getters
  let actions
  let store
  let wrapper
  beforeEach(() => {
    getters = {
      getExamById: () => {
        return () => EXAM
      },
      userExam: () => {
        return null
      },
    }
    actions = {
      fetchExamById: () => {},
      fetchUserExam: () => {},
    }
    store = new Vuex.Store({
      modules: {
        exams: {
          namespaced: true,
          getters,
          actions,
        },
      },
    })

    wrapper = createComponent({ examId: '-', path: 'start' }, store)
  })

  it('should render the start page', () => {
    expect(wrapper.find('.start-page').exists()).toBe(true)
    expect(wrapper.find('.start>input').element.value).toEqual('Start the Exam')
  })
})

describe('Loading progressPage if user has start the exam and not expires', () => {
  let getters
  let actions
  let store
  let wrapper
  beforeEach(() => {
    const oneMinuteAgo = new Date() - 60000
    getters = {
      getExamById: () => {
        return () => EXAM
      },
      userExam: () => {
        return {
          userId: '-',
          examId: '-',
          startDate: new Date(oneMinuteAgo).toISOString(),
        }
      },
    }
    actions = {
      fetchExamById: async () => {},
      fetchUserExam: async () => {},
    }
    store = new Vuex.Store({
      modules: {
        exams: {
          namespaced: true,
          getters,
          actions,
        },
      },
    })
    wrapper = createComponent({ examId: '-', path: 'start' }, store)
  })

  it('should render the start page', async (done) => {
    await nextTick()
    expect(wrapper.find('.start-page').exists()).toBe(true)
    expect(wrapper.find('.start>input').element.value).toEqual('Take me to the Exam')
    done()
  })
})

*/
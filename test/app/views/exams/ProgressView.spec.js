import { shallowMount, createLocalVue } from '@vue/test-utils'
import ProgressView from 'views/exams/ProgressPage'
import locale from 'locale/locale'
import Vuex from 'vuex'

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
  return shallowMount(ProgressView, {
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

describe('In progressPage', () => {
  let getters
  let actions
  let store
  let wrapper
  beforeEach(() => {
    const oneMinuteAgo = new Date() - 60000
    getters = {
      getExamById: () => {
        return () => {
          return EXAM
        }
      },
      userExam: () => {
        return {
          userId: '-',
          examId: '-',
          codeLanguage: 'python',
          startDate: new Date(oneMinuteAgo).toISOString(),
        }
      },
    }
    actions = {
      fetchExamById: () => {},
      fetchUserExam: () => {},
      submitExam: () => {},
    }
    store = new Vuex.Store({
      modules: {
        exams: {
          namespaced: true,
          state: {},
          getters,
          actions,
        },
      },
    })
    wrapper = createComponent({ examId: '-', path: 'progress' }, store)
  })

  it('should render the progress page', () => {
    expect(wrapper.find('.progress-page').exists()).toBe(true)
    expect(wrapper.find('.code-language').text()).toEqual('python')
    expect(wrapper.findAllComponents({ name: 'ExamLevel' }).length).toEqual(2)
  })
})

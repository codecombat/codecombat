import { shallowMount, createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import Component from 'ozaria/site/components/teacher-dashboard/modals/ModalEditStudent.vue' // replace with actual path

describe('ModalEditStudent', () => {
  describe('lastPlayed', () => {
    let store
    let sessions
    let projects
    let localVue

    beforeEach(() => {
      localVue = createLocalVue()
      localVue.use(Vuex)
      sessions = [
        { changed: '2022-01-01T00:00:00Z' },
        { changed: '2022-02-01T00:00:00Z' },
      ]

      projects = [
        [{ changed: '2022-03-01T00:00:00Z' }],
        [{ changed: '2022-04-01T00:00:00Z' }],
      ]

      store = new Vuex.Store({
        getters: {
          'teacherDashboard/getMembersCurrentClassroom': () => [],
          'levels/getLevelsForClassroom': () => () => [],
          'baseSingleClass/currentEditingStudent': () => 'student1',
          'teacherDashboard/getCurrentClassroom': () => ({ _id: 'classroom1' }),
          'teacherDashboard/getLevelSessionsMapCurrentClassroom': () => ({ student1: sessions }),
          'teacherDashboard/getAiProjectsMapCurrentClassroom': () => ({ student1: projects }),
        },
        actions: {
          'levels/fetchForClassroom': () => {},
        },
      })
    })

    it('returns correct last played project', () => {
      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed

      expect(lastPlayed.session).toBe(null)
      expect(lastPlayed.project.changed).toBe('2022-04-01T00:00:00Z')
    })

    it('returns correct last played session when no projects exist', () => {
      projects = [
        [],
        [],
      ]

      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed

      expect(lastPlayed.session.changed).toBe('2022-02-01T00:00:00Z')
      expect(lastPlayed.project).toBe(null)
    })

    it('returns correct last played session when no projects exist at all', () => {
      projects = []
      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed

      expect(lastPlayed.session.changed).toBe('2022-02-01T00:00:00Z')
      expect(lastPlayed.project).toBe(null)
    })

    it('returns correct last played project when no sessions exist', () => {
      sessions = []
      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed

      expect(lastPlayed.session).toBe(null)
      expect(lastPlayed.project.changed).toBe('2022-04-01T00:00:00Z')
    })

    it('returns session if that was played later', () => {
      sessions = [
        { changed: '2025-03-01T00:00:00Z' },
        { changed: '2025-04-01T00:00:00Z' },
      ]
      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed

      expect(lastPlayed.session.changed).toBe('2025-04-01T00:00:00Z')
      expect(lastPlayed.project).toBe(null)
    })

    it('returns null if no sessions or projects exist', () => {
      sessions = []
      projects = []
      const wrapper = shallowMount(Component, { store, localVue })
      const lastPlayed = wrapper.vm.lastPlayed
      expect(lastPlayed).toBe(null)
    })
  })

  describe('lastPlayedString', () => {
    const lastPlayed = {
      project: { name: 'LevelNameProjectName', changed: '2022-04-01T10:00:00Z' },
    }

    const store = new Vuex.Store({
      getters: {
        'teacherDashboard/getMembersCurrentClassroom': () => [],
        'levels/getLevelsForClassroom': () => () => [],
        'baseSingleClass/currentEditingStudent': () => 'student1',
        'teacherDashboard/getCurrentClassroom': () => ({ _id: 'classroom1' }),
      },
      actions: {
        'levels/fetchForClassroom': () => {},
      },
    })

    let componentDefinition

    let localVue

    beforeEach(() => {
      localVue = createLocalVue()
      localVue.use(Vuex)
      componentDefinition = {
        store,
        localVue,
        mounted () {},
        computed: {
          lastPlayed: () => {
            return {
              ...lastPlayed,
            }
          },
        },
        methods: {
          formatDate: (date) => {
            return date.toString()
          },
        },
      }
    })

    it('returns correct last played string with project', () => {
      const wrapper = shallowMount(Component, {
        ...componentDefinition,
        computed: {
          ...componentDefinition.computed,
          lastPlayed: () => {
            return {
              project: { name: 'LevelNameProjectName', changed: '2022-04-01T10:00:00Z' },
            }
          },
        },
      })

      const lastPlayedString = wrapper.vm.lastPlayedString

      expect(lastPlayedString).toBe('LevelNameProjectName, on 2022-04-01T10:00:00Z')
    })

    it('returns correct last played string with only level', () => {
      const wrapper = shallowMount(Component, {
        ...componentDefinition,
        computed: {
          ...componentDefinition.computed,
          lastPlayed: () => {
            return {
              level: { name: 'LevelName' },
              session: { changed: '2022-02-01T00:00:00Z' },
            }
          },
        },
      })

      const lastPlayedString = wrapper.vm.lastPlayedString
      expect(lastPlayedString).toBe('LevelName, on 2022-02-01T00:00:00Z')
    })
  })
})
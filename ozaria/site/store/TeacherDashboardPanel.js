import moment from 'moment'
import utils from 'app/core/utils'
import Level from '../../../app/models/Level'
import { getGameContentDisplayNameWithType } from 'ozaria/site/common/ozariaUtils.js'

export const PRACTICE_LEVEL = 'PRACTICE_LEVEL'
export const CAPSTONE_LEVEL = 'CAPSTONE_LEVEL'
export const DRAGGABLE_ORDERING = 'DRAGGABLE_ORDERING'
export const INSERT_CODE = 'INSERT_CODE'
export const DRAGGABLE_STATEMENT_COMPLETION = 'DRAGGABLE_STATEMENT_COMPLETION'

/**
 * Payload for practiceLevelData for displaying on the teacher dashboard panel.
 */
export function practiceLevelData (content, studentSessions) {
  const { original, fromIntroLevelOriginal, practiceThresholdMinutes } = content
  const normalizedOriginal = original || fromIntroLevelOriginal
  const level = new Level(content)

  let language = studentSessions[normalizedOriginal]?.codeLanguage || 'python'
  if (content.type === 'web-dev') {
    language = 'html'
  }
  const solutionCode = level.getSolutionForLanguage(language)?.source || ''

  const starterCode = level.getSampleCodeForLanguage(language) || ''
  const studentCode = studentSessions[normalizedOriginal]?.code?.['hero-placeholder']?.plan || ''

  return {
    type: PRACTICE_LEVEL,
    starterCode,
    studentCode,
    solutionCode,
    language,
    practiceThresholdMinutes,
  }
}

export function extraPracticeLevelData (content, studentSessions) {
  const { original, fromIntroLevelOriginal } = content
  const normalizedOriginal = original || fromIntroLevelOriginal

  return {
    ...practiceLevelData(content, studentSessions),
    session: studentSessions[normalizedOriginal],
    levelTitle: getGameContentDisplayNameWithType(content),
    isExtra: true,
  }
}

/**
 * Payload for practiceLevelData for displaying on the teacher dashboard panel.
 */
export function capstoneLevelData ({
  studentCode,
  gameGoals,
  language,
}) {
  return {
    type: CAPSTONE_LEVEL,
    studentCode,
    gameGoals,
    language,
  }
}

export function draggableOrderingData ({
  prompt,
  submissionText,
  solutionText,
  lastColText,
}) {
  return {
    type: DRAGGABLE_ORDERING,
    prompt,
    submissionText,
    solutionText,
    lastColText,
  }
}

export function draggableStatementCompletionData ({
  prompt,
  submissionText,
  solutionText,
  labels,
}) {
  return {
    type: DRAGGABLE_STATEMENT_COMPLETION,
    prompt,
    submissionText,
    solutionText,
    labels,
  }
}
export function insertCodeData ({
  prompt,
  code,
  studentSubmission,
  solution,
  options,
  interactiveArt,
}) {
  return {
    type: INSERT_CODE,
    prompt,
    code,
    studentSubmission,
    solution,
    options,
    interactiveArt,
  }
}

export default {
  namespaced: true,
  state: {
    open: false,
    panelHeader: 'Module 1 | Hard Coded',
    panelFooter: {
      icon: undefined,
      url: '',
    },
    studentInfo: {
      name: 'Student Name',
      completedContent: '',
    },
    selectedProgressKey: undefined,
    conceptCheck: {
      learningGoal: undefined,
      totalSubmissions: -1,
      timeSpent: -1,
      lastPlayed: '',
      classAverage: -1, // TODO: Punt this temporarily.
    },
    //     panelSessionContent: practiceLevelData({
    //       starterCode: `var name = hero.length('codestatement');`,
    //       studentCode: `const code = hero.length(rawr);\ncode.statement(example);\ncode.statement2(example2);`,
    //       solutionCode: `const code = hero.length(rawr);
    // code.statement(example);
    // code.statement2(example2);`,
    //       language: 'javascript'
    //     })

    //   panelSessionContent: capstoneLevelData({
    //     studentCode: `var name = hero.walkLeft();\nconst var2 = 10;\nhero.walkUp();\nhero.walkDown();`,
    //     language: 'javascript',
    //     gameGoals: [
    //       {
    //         description: 'Create first character using a variable',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Have each character SAY at least one thing',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Use if statements to branch your dialogue',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Another goal that is pulled from the level in some way.',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Set background',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Have your characters ENTER the screen',
    //         completed: Math.random() < 0.5
    //       }
    //     ]
    //   })

    // panelSessionContent: draggableOrderingData({
    //   prompt: 'Drag on the steps on the left into the correct order to make a sandwich.',
    //   submissionText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: true },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: false },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: false },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: true }
    //   ],
    //   solutionText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //   ],
    //   lastColText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //   ]
    // })
    // panelSessionContent: draggableStatementCompletionData({
    //   prompt: 'Drag the blocks into the correct place in the code statement.',
    //   submissionText: [
    //     { text: '"snake"', correct: true },
    //     { text: 'avatars', correct: false },
    //     { text: 'setArt', correct: false }
    //   ],
    //   solutionText: [
    //     { text: 'avatars' },
    //     { text: 'setArt' },
    //     { text: '"snake"' }
    //   ],
    //   labels: [
    //     { text: 'object' },
    //     { text: 'method' },
    //     { text: 'argument' }
    //   ]
    // })
    //   panelSessionContent: insertCodeData({
    //     prompt: 'Add the line of code to call Capella\'s name.',
    //     code: `var character_name = thisis.veryLong(codestatement);\ncode.statement(example);\ncode.statement(example)\n//answer goes here\ncharacter_name = very.short(code)`,
    //     studentSubmission: {
    //       text: 'code.statement(example)',
    //       correct: false
    //     },
    //     solution: {
    //       text: 'correct.statement(example)'
    //     },
    //     options: [
    //       { text: 'code.statement(example)' },
    //       { text: 'code.statement(example2)' },
    //       { text: 'code.statement(example3)' },
    //       { text: 'code.statement(example4)' }
    //     ]
    //   })
    panelSessionContents: undefined,
    panelProjectContent: undefined,
  },

  mutations: {
    openPanel (state) {
      state.open = true
    },
    closePanel (state) {
      state.open = false
    },
    setPanelHeader (state, header) {
      state.panelHeader = header
    },
    setStudentInfo (state, { name, completedContent, practiceThresholdMinutes }) {
      state.studentInfo = { name, completedContent, practiceThresholdMinutes }
    },
    setPanelSessionContents (state, sessionContentObjects) {
      state.panelSessionContents = sessionContentObjects
    },
    setPanelProjectContent (state, projectContentObject) {
      state.panelProjectContent = projectContentObject
    },
    setLearningGoal (state, learningGoal) {
      Vue.set(state.conceptCheck, 'learningGoal', learningGoal)
    },
    setSelectedProgressKey (state, key) {
      state.selectedProgressKey = key
    },
    setTimeSpent (state, timeSpent) {
      Vue.set(state.conceptCheck, 'timeSpent', timeSpent)
    },
    setLastPlayed (state, lastPlayed) {
      Vue.set(state.conceptCheck, 'lastPlayed', lastPlayed)
    },
    setTotalSubmissions (state, totalSubmissions) {
      Vue.set(state.conceptCheck, 'totalSubmissions', totalSubmissions)
    },
    setPanelFooter (state, { icon, url }) {
      state.panelFooter = {
        icon,
        url,
      }
    },
    resetState (state) {
      Vue.set(state.conceptCheck, 'learningGoal', '')
      Vue.set(state.conceptCheck, 'totalSubmissions', -1)
      Vue.set(state.conceptCheck, 'timeSpent', -1)
      Vue.set(state.conceptCheck, 'classAverage', -1)
      Vue.set(state.studentInfo, 'completedContent', '')
      state.panelSessionContents = undefined
      state.panelProjectContent = undefined
      state.selectedProgressKey = undefined
      state.panelFooter = {
        icon: undefined,
        url: '',
      }
    },
  },

  getters: {
    selectedProgressKey (state) {
      return state.selectedProgressKey
    },

    panelFooter (state) {
      return state.panelFooter
    },

    isOpen (state) {
      return state.open
    },

    panelHeader (state) {
      return state.panelHeader
    },

    studentInfo (state) {
      return state.studentInfo
    },

    conceptCheck (state) {
      return state.conceptCheck
    },

    panelSessionContents (state) {
      return state.panelSessionContents
    },

    panelProjectContent (state) {
      return state.panelProjectContent
    },
  },

  actions: {
    // Action that acquires already loaded data and populates the TeacherDashboardPanel.
    showPanelSessionContent ({ commit, dispatch, rootGetters, state }, { student, classroomId, selectedCourseId, moduleNum, contentId }) {
      const levelSessionsMapByUser = rootGetters['levelSessions/getSessionsMapForClassroom'](classroomId)
      const studentSessions = levelSessionsMapByUser[student._id]
      const classroom = rootGetters['teacherDashboard/classroom']
      const classroomLanguage = classroom?.aceConfig?.language || 'python'
      const modules = rootGetters['gameContent/getContentForClassroom'](classroomId)?.[selectedCourseId]?.modules
      const moduleContent = modules[moduleNum]
      const content = moduleContent.find(({ _id }) => _id === contentId)

      const { introContent, ozariaType, original, fromIntroLevelOriginal, type, practiceThresholdMinutes } = content

      let icon, url

      if (!ozariaType) {
        icon = type
        url = `/play/intro/${fromIntroLevelOriginal}?course=${selectedCourseId}&codeLanguage=${classroomLanguage}&intro-content=${introContent || 0}&original=true`
        if (utils.isCodeCombat) {
          url = `/play/level/${content.slug}?course=${selectedCourseId}&codeLanguage=${classroomLanguage}`
        }
      } else if (ozariaType) {
        if (ozariaType === 'practice') {
          icon = 'practicelvl'
        } else if (ozariaType === 'capstone') {
          icon = 'capstone'
        } else if (ozariaType === 'challenge') {
          icon = 'challengelvl'
        }
        url = `/play/level/${contentId}?course=${selectedCourseId}&codeLanguage=${classroomLanguage}`
      }

      if (!url || !icon) {
        console.error('missing url or icon in curriculum guide')
      }

      const normalizedOriginal = original || fromIntroLevelOriginal

      if (content === undefined) {
        throw new Error('Couldn\'t find module content.')
      }

      commit('resetState')
      commit('setPanelFooter', { url, icon })
      commit('setSelectedProgressKey', `${student._id}_${content._id}`)
      commit('setLearningGoal', (content?.documentation?.specificArticles || []).find(({ name }) => name === 'Learning Goals')?.body || '')

      const panelHeader = `Module ${moduleNum} | ${getGameContentDisplayNameWithType(content)}`

      if (['hero', 'course', undefined].includes(content.type)) {
        // For practice levels and challenge levels

        commit('setTimeSpent', utils.secondsToMinutesAndSeconds(Math.ceil(studentSessions[normalizedOriginal].playtime)))
        commit('setLastPlayed', moment(studentSessions[normalizedOriginal].changed).format('lll'))

        dispatch('setPanelSessionContent', {
          header: panelHeader,
          studentName: student.displayName,
          practiceThresholdMinutes,
          dateFirstCompleted: studentSessions[normalizedOriginal].dateFirstCompleted,
          sessionContentObjects: [practiceLevelData(content, studentSessions)],
        })
      } else if (content.type === 'game-dev' || content.type === 'web-dev') {
        const language = studentSessions[normalizedOriginal]?.codeLanguage || 'python'
        const gameGoals = [
          ...(content.goals || []), ...(content.additionalGoals || []).map(({ goals }) => goals).flat(),
        ]

        commit('setTimeSpent', utils.secondsToMinutesAndSeconds(Math.ceil(studentSessions[normalizedOriginal].playtime)))

        const studentSolved = new Set(Object.entries(studentSessions[normalizedOriginal]?.state?.goalStates || {})
          .filter(([_, { status }]) => status === 'success')
          .map(([goalId, _]) => goalId) || [])

        dispatch('setPanelSessionContent', {
          header: panelHeader,
          studentName: student.displayName,
          dateFirstCompleted: studentSessions[normalizedOriginal].dateFirstCompleted,
          sessionContentObjects: [capstoneLevelData({
            studentCode: studentSessions[normalizedOriginal]?.code?.['hero-placeholder']?.plan || '',
            gameGoals: gameGoals.map((result) => {
              return {
                goal: result,
                description: result.name,
                completed: studentSolved.has(result.id),
              }
            }),
            language,
          })],
        })
      } else if (content.type === 'interactive') {
        const firstSolution = rootGetters['interactives/getInteractiveSessionsForClass'](classroomId)?.[student._id]?.[contentId]

        commit('setTotalSubmissions', firstSolution.submissionCount || 0)

        if (content.interactiveType === 'draggable-statement-completion') {
          const elementsMap = new Map(content.draggableStatementCompletionData.elements.map((element) => [element.elementId, element]))

          dispatch('setPanelSessionContent', {
            header: panelHeader,
            studentName: student.displayName,
            dateFirstCompleted: firstSolution.dateFirstCompleted,
            sessionContentObjects: [draggableStatementCompletionData({
              prompt: content.promptText,
              submissionText: firstSolution.submissions[0].submittedSolution.map((id, idx) => {
                return {
                  text: utils.i18n(elementsMap.get(id), 'text'),
                  correct: content.draggableStatementCompletionData.solution[idx] === id,
                }
              }),
              solutionText: content.draggableStatementCompletionData.solution.map((id) => ({
                text: utils.i18n(elementsMap.get(id), 'text'),
              })),
              labels: content.draggableStatementCompletionData.labels.map((label) => ({
                text: utils.i18n(label, 'text'),
              })),
            })],
          })
        } else if (content.interactiveType === 'draggable-ordering') {
          const interactiveData = content.draggableOrderingData
          const elementsMap = new Map(interactiveData.elements.map((element) => [element.elementId, element]))

          dispatch('setPanelSessionContent', {
            header: panelHeader,
            studentName: student.displayName,
            dateFirstCompleted: firstSolution.dateFirstCompleted,
            sessionContentObject: [draggableOrderingData({
              prompt: content.promptText,
              submissionText: firstSolution.submissions[0].submittedSolution.map((id, idx) => {
                return {
                  text: utils.i18n(elementsMap.get(id), 'text'),
                  correct: interactiveData.solution[idx] === id,
                }
              }),
              solutionText: interactiveData.solution.map((id) => ({
                text: utils.i18n(elementsMap.get(id), 'text'),
              })),
              lastColText: interactiveData.labels.map((label) => ({
                text: utils.i18n(label, 'text'),
              })),
            })],
          })
        } else if (content.interactiveType === 'insert-code') {
          const interactiveData = content.insertCodeData

          const elementsMap = new Map(interactiveData.choices.map((element) => [element.choiceId, element]))

          dispatch('setPanelSessionContent', {
            header: panelHeader,
            studentName: student.displayName,
            dateFirstCompleted: firstSolution.dateFirstCompleted,
            sessionContentObject: [insertCodeData({
              prompt: content.promptText,
              code: interactiveData.starterCode,
              studentSubmission: {
                text: utils.i18n(elementsMap.get(firstSolution.submissions[0].submittedSolution), 'text'),
                correct: firstSolution.submissions[0].correct,
              },
              solution: { text: utils.i18n(elementsMap.get(interactiveData.solution), 'text') },
              options: interactiveData.choices.map(element => ({
                text: utils.i18n(element, 'text'),
              })),
              interactiveArt: content.defaultArtAsset,
            })],
          })
        } else {
          console.error(`Unhandled interactive type in TeacherDashboardPanel: '${content.interactiveType}'`)
        }
      }
      if (content.practiceLevels) {
        commit(
          'setPanelSessionContents',
          [
            ...state.panelSessionContents,
            ...content.practiceLevels
              .map((practiceLevelContent) => ({
                ...extraPracticeLevelData(practiceLevelContent, studentSessions),
              }))
              // include levels that are completed or in-progress AND only the next one, but no further ones
              .filter(({ session }, index, array) => session || array[index - 1]?.session),
          ],
        )
      }
    },

    showPanelProjectContent ({ commit, dispatch, rootGetters }, { student, header, classroomId, selectedCourseId, moduleName, aiScenario, aiProjects }) {
      commit('resetState')
      commit('setLearningGoal', aiScenario.mode === 'learn to use' ? aiScenario?.name : '')

      dispatch('setPanelProjectContent', {
        header,
        studentName: student.displayName,
        projectContentObject: {
          aiScenario,
          aiProjects,
        },
      })
    },

    setPanelProjectContent ({ commit }, { projectContentObject, header, studentName, dateFirstCompleted }) {
      commit('setPanelProjectContent', projectContentObject)
      commit('setPanelHeader', header)
      commit('setStudentInfo', {
        name: studentName,
      })
      commit('openPanel')
    },

    setPanelSessionContent ({ commit }, { sessionContentObjects, header, studentName, practiceThresholdMinutes, dateFirstCompleted }) {
      commit('setPanelSessionContents', sessionContentObjects)
      commit('setPanelHeader', header)
      commit('setStudentInfo', {
        name: studentName,
        // Handle undefined dateFirstCompleted for in progress content
        completedContent: dateFirstCompleted ? moment(dateFirstCompleted).format('lll') : '',
        practiceThresholdMinutes,
      })
      commit('openPanel')
    },
  },
}

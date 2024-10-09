import classroomsApi from 'core/api/classrooms'
import campaignsApi from 'core/api/campaigns'
import { courseIDs } from 'core/utils'

import { getCurriculumGuideContentList, generateLevelNumberMap } from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper.js'

// These default projections ensure that all the pages of the teacher dashboard that need gameContent data have all the info they need,
// since gameContent is static in nature and we dont want to fetch it over and over again on every page
// Currently used for single class page, student projects, and curriculum guide.
// Therefore use these defaultProjections for any additional data needed for any of the teacher dashboard pages
const defaultProjections = {
  cinematics: '_id,i18n,name,slug,displayName,description',
  interactives: '_id,i18n,name,slug,displayName,interactiveType,unitCodeLanguage,documentation,draggableOrderingData,insertCodeData,draggableStatementCompletionData,defaultArtAsset,promptText',
  cutscenes: '_id,i18n,name,slug,displayName,description',
  levels: 'original,name,description,slug,concepts,displayName,type,ozariaType,practice,shareable,i18n,assessment,goals,additionalGoals,documentation,heroThang,screenshot,exemplarProjectUrl,exemplarCodeUrl,projectRubricUrl,totalStages,practiceThresholdMinutes',
}

export default {
  namespaced: true,

  state: {
    loading: {
      byClassroom: {},
      byCampaign: {},
    },

    // gameContent: {
    //   byClassroom: {
    //     <classroomId>:{
    //       <courseId>: {
    //         modules: {
    //           <moduleNumber>: [ <List of content broken down into interactives, cutscenes, cinematics, practice levels etc> ]
    //         },
    //         capstone: <capstone level object>
    //       }
    //     }
    //   },
    //   byCampaign: {
    //     <campaignId>: {
    //       modules: {
    //         <moduleNumber>: [ <List of content broken down into interactives, cutscenes, cinematics, practice levels etc> ]
    //       },
    //       capstone: <capstone level object></capstone>
    //     }
    //   }
    // }
    gameContent: {
      byClassroom: {},
      byCampaign: {},
    },
    levelNumberMap: {},
  },

  mutations: {
    toggleLoadingForClassroom: (state, classroomId) => {
      Vue.set(
        state.loading.byClassroom,
        classroomId,
        !state.loading.byClassroom[classroomId],
      )
    },

    toggleLoadingForCampaign: (state, campaignId) => {
      Vue.set(
        state.loading.byCampaign,
        campaignId,
        !state.loading.byCampaign[campaignId],
      )
    },

    addContentForClassroom: (state, { classroomId, contentData }) => {
      Vue.set(state.gameContent.byClassroom, classroomId, contentData)
    },

    addContentForCampaign: (state, { campaignId, contentData }) => {
      Vue.set(state.gameContent.byCampaign, campaignId, contentData)
    },

    addLevelNumber: (state, { levelId, levelNumber }) => {
      Vue.set(state.levelNumberMap, levelId, levelNumber)
    },
    setLevelNumberMap (state, newMap) {
      state.levelNumberMap = newMap
    },
  },

  getters: {
    getContentForClassroom: (state) => (id) => {
      return state.gameContent.byClassroom[id]
    },
    getContentForCampaign: (state) => (id) => {
      return state.gameContent.byCampaign[id]
    },
    getLevelNumber: (state) => (id) => {
      return state.levelNumberMap?.[id]
    },
    levelNumberMap: (state) => {
      return state.levelNumberMap
    },
  },

  actions: {
    fetchGameContentForClassroom: ({ commit, state }, { classroomId, options = {} }) => {
      if (state.gameContent.byClassroom[classroomId] && !options.forceGameContentFetch) {
        return Promise.resolve()
      }
      commit('toggleLoadingForClassroom', classroomId)

      const projectData = {
        cinematics: (options.project || {}).cinematics || defaultProjections.cinematics,
        interactives: (options.project || {}).interactives || defaultProjections.interactives,
        cutscenes: (options.project || {}).cutscenes || defaultProjections.cutscenes,
        levels: (options.project || {}).levels || defaultProjections.levels,
      }

      return classroomsApi.fetchGameContent(classroomId, { data: { project: projectData } })
        .then(res => {
          if (res) {
            if (res[courseIDs.JUNIOR]) {
              //
              // Move practice levels into the previous level's practiceLevels array
              //
              const juniorCourseData = res[courseIDs.JUNIOR]
              const moduleEntries = Object.entries(juniorCourseData.modules)
              for (const [moduleNum, moduleData] of moduleEntries) {
                juniorCourseData.modules[moduleNum] = moduleData.reduce((acc, item) => {
                  const { practice } = item
                  if (practice) {
                    const previous = acc[acc.length - 1]
                    previous.practiceLevels = acc[acc.length - 1].practiceLevels || []
                    previous.practiceLevels.push(item)
                  } else {
                    acc.push(item)
                  }
                  return acc
                }, [])
              }
            }
            commit('addContentForClassroom', {
              classroomId,
              contentData: res,
            })
          } else {
            throw new Error('Unexpected response from fetch content API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch content failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForClassroom', classroomId))
    },

    fetchGameContentForCampaign: ({ commit, state }, { campaignId, language, options = {} }) => {
      if (state.gameContent.byCampaign[campaignId]) {
        return Promise.resolve()
      }
      commit('toggleLoadingForCampaign', campaignId)

      const projectData = {
        cinematics: (options.project || {}).cinematics || defaultProjections.cinematics,
        interactives: (options.project || {}).interactives || defaultProjections.interactives,
        cutscenes: (options.project || {}).cutscenes || defaultProjections.cutscenes,
        levels: (options.project || {}).levels || defaultProjections.levels,
      }

      return campaignsApi.fetchGameContent(campaignId, { data: { project: projectData, cacheEdge: true, language: language || 'python' }, callOz: options.callOz })
        .then(res => {
          if (res) {
            commit('addContentForCampaign', {
              campaignId,
              contentData: res,
            })
          } else {
            throw new Error('Unexpected response from fetch content API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch content failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForCampaign', campaignId))
    },

    async generateLevelNumberMap ({ commit, state, dispatch, getters }, { campaignId, language }) {
      let gameContent = state.gameContent.byCampaign[campaignId]

      if (!gameContent) {
        await dispatch('fetchGameContentForCampaign', {
          campaignId,
          language,
        })
      }
      gameContent = getters.getContentForCampaign(campaignId)
      const allLevels = []
      for (const [moduleNum] of Object.entries(gameContent.modules)) {
        const levelsList = getCurriculumGuideContentList({
          introLevels: gameContent.introLevels,
          moduleInfo: gameContent.modules,
          moduleNum,
        })
        allLevels.push(...levelsList)
      }

      const levelNumberMap = generateLevelNumberMap(allLevels)
      commit('setLevelNumberMap', levelNumberMap)
    },
  },
}

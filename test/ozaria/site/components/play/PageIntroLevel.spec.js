/* eslint-env jasmine */
import { shallowMount } from '@vue/test-utils'
import pageIntroLevel from 'ozaria/site/components/play/PageIntroLevel/index'
import factories from 'test/app/factories'
import api from 'core/api'
import interactiveComponent from 'ozaria/site/components/interactive/PageInteractive'
import cinematicComponent from 'ozaria/site/components/cinematic/PageCinematic'
import store from 'core/store'

const introLevel = {
  _id: 'intro-level-id',
  original: 'intro-level-id',
  slug: 'intro-level-slug',
  introContent: [
    {
      type: 'cinematic',
      contentId: 'cinematic-slug-1'
    },
    {
      type: 'interactive',
      contentId: {
        python: 'interactive-slug-1'
      }
    }
  ]
}

const introLevelSession = {
  state: {
    complete: false
  },
  codeLanguage: 'python'
}

const campaign = factories.makeCampaignObject({ type: 'course' }, { levels: [introLevel] })

const createComponent = (values = {}) => {
  return shallowMount(pageIntroLevel, {
    propsData: values,
    store
  })
}

let pageIntroLevelWrapper

describe('Intro level Page', () => {
  beforeEach((done) => {
    spyOn(api.levels, 'getByIdOrSlug').and.returnValue(Promise.resolve(introLevel))
    spyOn(api.levels, 'upsertSession').and.returnValue(Promise.resolve(introLevelSession))
    spyOn(api.levelSessions, 'update').and.returnValue(Promise.resolve({}))
    spyOn(api.campaigns, 'get').and.returnValue(Promise.resolve(campaign))

    me.set(factories.makeUser({ permissions: ['admin'] }).attributes)
    pageIntroLevelWrapper = createComponent({ introLevelIdOrSlug: introLevel.slug, campaignId: campaign._id })
    _.defer(done)
  })

  it('renders a vue instance', () => {
    expect(pageIntroLevelWrapper.isVueInstance()).toBe(true)
  })

  it('renders the content in correct sequence', () => {
    expect(pageIntroLevelWrapper.contains(cinematicComponent)).toBe(true)
    expect(pageIntroLevelWrapper.contains(interactiveComponent)).toBe(false)
    pageIntroLevelWrapper.find(cinematicComponent).vm.$emit('completed')
    expect(pageIntroLevelWrapper.contains(cinematicComponent)).toBe(false)
    expect(pageIntroLevelWrapper.contains(interactiveComponent)).toBe(true)
  })

  it('sets complete:true in the intro level session when all content completed', () => {
    pageIntroLevelWrapper.find(cinematicComponent).vm.$emit('completed')
    pageIntroLevelWrapper.find(interactiveComponent).vm.$emit('completed')
    expect(api.levelSessions.update).toHaveBeenCalled()
  })
})

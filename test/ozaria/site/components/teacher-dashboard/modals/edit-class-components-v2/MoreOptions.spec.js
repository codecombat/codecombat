import { shallowMount } from '@vue/test-utils'
import usersApi from 'core/api/users'
import MoreOptions from 'ozaria/site/components/teacher-dashboard/modals/edit-class-components-v2/MoreOptions.vue'

describe('MoreOptions AI Level Hints row', () => {
  const getAiDisabled = usersApi.getAiDisabled
  afterEach(() => { usersApi.getAiDisabled = getAiDisabled })

  const mountWith = async (aiDisabled) => {
    usersApi.getAiDisabled = jasmine.createSpy('getAiDisabled').and.returnValue(Promise.resolve({ aiDisabled }))
    const wrapper = shallowMount(MoreOptions, { propsData: { value: { levelChat: true } } })
    wrapper.setData({ moreOptions: true })
    await new Promise(resolve => setTimeout(resolve))
    return wrapper
  }

  it('shows the checkbox when AI is on for the school and district', async function (done) {
    const wrapper = await mountWith(false)
    expect(wrapper.find('#level-chat').exists()).toBe(true)
    expect(wrapper.find('.level-chat .alert-info').exists()).toBe(false)
    done()
  })

  it('shows a notice instead of the checkbox when AI is off for the school or district', async function (done) {
    const wrapper = await mountWith(true)
    expect(wrapper.find('#level-chat').exists()).toBe(false)
    expect(wrapper.find('.level-chat .alert-info').exists()).toBe(true)
    done()
  })
})

import { shallowMount } from '@vue/test-utils'
import MoreOptions from 'ozaria/site/components/teacher-dashboard/modals/edit-class-components-v2/MoreOptions.vue'

describe('MoreOptions AI Level Hints row', () => {
  afterEach(() => { me.unset('aiDisabled') })

  const mountWith = (aiDisabled) => {
    me.set('aiDisabled', aiDisabled)
    const wrapper = shallowMount(MoreOptions, { propsData: { value: { levelChat: true } } })
    wrapper.setData({ moreOptions: true })
    return wrapper
  }

  it('shows the checkbox when AI is on for the signed-in teacher', async function (done) {
    const wrapper = mountWith(false)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('#level-chat').exists()).toBe(true)
    expect(wrapper.find('.level-chat .alert-info').exists()).toBe(false)
    done()
  })

  it('shows a notice instead of the checkbox when AI is off for the signed-in teacher', async function (done) {
    const wrapper = mountWith(true)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('#level-chat').exists()).toBe(false)
    expect(wrapper.find('.level-chat .alert-info').exists()).toBe(true)
    done()
  })
})

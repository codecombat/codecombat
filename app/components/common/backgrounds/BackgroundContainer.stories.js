import BackgroundContainer from './BackgroundContainer.vue'

export default {
  title: 'Backgrounds/BackgroundContainer',
  component: BackgroundContainer,
  argTypes: {
    type: {
      control: {
        type: 'select'
      },
      options: BackgroundContainer.typeOptions,
      defaultValue: BackgroundContainer.typeOptions[0],
      description: 'Type of background'
    },
    height: {
      control: {
        type: 'number'
      },
      defaultValue: 800,
      description: 'Height of the container'
    }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { BackgroundContainer },
  template: `
    <BackgroundContainer v-bind="$props">
      <div class="container" :style="{minHeight: height + 'px', background:'#efefef', borderRadius:'24px'}">Your content here</div>
    </BackgroundContainer>`
})

export const Default = Template.bind({})

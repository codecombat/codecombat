import AvatarComponent from './AvatarComponent.vue'

export default {
  title: 'Elements/AvatarComponent',
  component: AvatarComponent,
  argTypes: {
    img: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AvatarComponent },
  template: '<avatar-component v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  img: 'https://via.placeholder.com/24' // replace with your image url
}

import ProfileCard from './ProfileCard.vue'

export default {
  title: 'Elements/ProfileCard',
  component: ProfileCard,
  argTypes: {
    name: { control: 'text' },
    title: { control: 'text' },
    image: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ProfileCard },
  template: '<profile-card v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  name: 'John Doe',
  title: 'Software Engineer',
  image: 'https://example.com/image.jpg'
}

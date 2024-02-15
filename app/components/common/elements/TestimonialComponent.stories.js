import TestimonialComponent from './TestimonialComponent.vue'

export default {
  title: 'Elements/TestimonialComponent',
  component: TestimonialComponent,
  argTypes: {
    quote: { control: 'text', defaultValue: 'This is a quote' },
    name: { control: 'text', defaultValue: 'John Doe' },
    title: { control: 'text', defaultValue: 'CEO' },
    image: { control: 'text', defaultValue: 'https://via.placeholder.com/150' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TestimonialComponent },
  template: '<testimonial-component v-bind="$props" />'
})

export const Default = Template.bind({
})
Default.args = {
  quote: 'This is a quote from about the product and how it has helped me in my life. It is a very long quote that will wrap to the next line and continue to be a long quote.',
  name: 'John Doe',
  title: 'CEO',
  image: 'https://via.placeholder.com/150'
}

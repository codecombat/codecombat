// Import the component
import FadingImages from './FadingImages.vue'

export default {
  title: 'Images/FadingImages',
  component: FadingImages
}

const Template = (args, { argTypes }) => {
  return {
    props: Object.keys(argTypes),
    components: { FadingImages },
    template: '<FadingImages v-bind="$props" />',
    data: () => ({
      images: [
        { src: '/images/pages/codequest/coding/coding_1.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_2.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_3.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_4.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_5.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_6.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_7.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_8.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_9.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_10.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_11.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_12.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_13.jpg', alt: 'Header image' }
      ]
    })
  }
}

export const ExampleStory = Template.bind({})
ExampleStory.args = {
  images: [
    { src: '/images/pages/codequest/coding/coding_1.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_2.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_3.jpg', alt: 'Header image' }
  ],
  initialIndex: 0,
  duration: 2000
}

export const Default = Template.bind({})
Default.args = {
  images: [
    { src: '/images/pages/codequest/coding/coding_1.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_2.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_3.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_4.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_5.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_6.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_7.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_8.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_9.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_10.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_11.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_12.jpg', alt: 'Header image' },
    { src: '/images/pages/codequest/coding/coding_13.jpg', alt: 'Header image' }
  ]
}

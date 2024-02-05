import BoxPanel from './BoxPanel.vue'

export default {
  title: 'BoxPanel',
  component: BoxPanel
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { BoxPanel },
  template: '<box-panel v-bind="$props" />'
})

export const Horizontal = Template.bind({})
Horizontal.args = {
  title: 'Horizontal Box Panel',
  items: [
    {
      hasPadding: false,
      image: '/images/pages/schools/boxes/maximize_4.png',
      title: 'Item 1',
      text: 'This is item 1',
      link: 'https://example.com/link1',
      linkText: 'Learn More'
    },
    {
      hasPadding: false,
      image: '/images/pages/schools/boxes/maximize_4.png',
      title: 'Item 2',
      text: 'This is item 2',
      link: 'https://example.com/link2',
      linkText: 'Learn More'
    }
  ],
  arrangement: 'horizontal'
}

export const Vertical = Template.bind({})
Vertical.args = {
  title: 'Vertical Box Panel',
  items: [
    {
      hasPadding: true,
      image: '/images/pages/schools/boxes/maximize_4.png',
      title: 'Item 1',
      text: 'This is item 1',
      link: 'https://example.com/link1',
      linkText: 'Learn More'
    },
    {
      hasPadding: false,
      image: '/images/pages/schools/boxes/maximize_4.png',
      title: 'Item 2',
      text: 'This is item 2',
      link: 'https://example.com/link2',
      linkText: 'Learn More'
    }
  ],
  arrangement: 'vertical'
}

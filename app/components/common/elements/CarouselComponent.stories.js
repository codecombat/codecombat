import CarouselComponent from './CarouselComponent.vue'
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import CarouselItem from './CarouselItem.vue'

export default {
  title: 'Containers/CarouselComponent',
  component: CarouselComponent,
  argTypes: {
    showTabs: { control: 'boolean' },
    showDots: { control: 'boolean' },
    hasBackground: { control: 'boolean' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CarouselComponent, CarouselItem, MixedColorLabel },
  template: `<carousel-component v-bind="$props">
    <template v-slot:0><carousel-item title="TITLEEEE" image="/images/pages/home-v3/carousel/1.png"><mixed-color-label text="aaahello __bbbbbello__ ccccmivan"/></carousel-item></template>
    <template v-slot:1><carousel-item title="titleekeeee but this title is long" image="/images/pages/home-v3/carousel/1.png"><mixed-color-label text="hello __bello__ mivan"/></carousel-item></template>
    <template v-slot:2><carousel-item tab-image="/images/pages/standards/carousel/carousel_2.png" image="/images/pages/home-v3/carousel/1.png"><mixed-color-label text="hello __bello__ mivan"/></carousel-item></template>
    <template v-slot:3><carousel-item title="Another Title Regular Length" image="/images/pages/home-v3/carousel/1.png"><mixed-color-label text="hello __bello__ mivan"/></carousel-item></template>
  </carousel-component>`
})

export const Default = Template.bind({})
Default.args = {
  showTabs: true,
  showDots: false,
  hasBackground: true
}

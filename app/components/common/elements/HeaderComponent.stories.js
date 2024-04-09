import HeaderComponent from './HeaderComponent.vue'

export default {
  title: 'Example/HeaderComponent',
  component: HeaderComponent
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { HeaderComponent },
  template: `<header-component v-bind="$props">
    <template v-slot:header-text>
        <h1>This is my long title</h1>
        <p>Our comprehensive implementation  empowers teachers, engages students and delivers successful outcomes.</p>
    </template>
    <template v-slot:image>
        <img src="https://via.placeholder.com/150" alt="placeholder image" />
    </template>
    </header-component>`
})

export const Default = Template.bind({
})
Default.args = {
}

import IframeModal from './IframeModal.vue'

export default {
  title: 'Modals/IframeModal',
  component: IframeModal,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { IframeModal },
  template: `<IframeModal v-bind="$props">
  <template #opener="{ openModal }">
    <button
      class="btn btn-md"
      @click="openModal"
    >
      Open Modal
    </button>
  </template>  
  </IframeModal>`,
})

export const Default = Template.bind({})
Default.args = {
  src: 'https://www.example.com/sample-lesson',
}

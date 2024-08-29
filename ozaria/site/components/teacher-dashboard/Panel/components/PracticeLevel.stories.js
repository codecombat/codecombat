import PracticeLevel from './PracticeLevel.vue'
import moment from 'moment'

export default {
  title: 'Components/PracticeLevel',
  component: PracticeLevel,
  argTypes: {
    panelSessionContent: { control: 'object' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PracticeLevel },
  template: '<practice-level v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  panelSessionContent: {
    session: {
      dateFirstCompleted: moment().subtract(1, 'days').toDate(),
      playtime: 120,
    },
    isExtra: true,
    levelTitle: 'Test Level',
    starterCode: 'print("Hello, World!")',
    language: 'python',
    studentCode: 'print("Hello, User!")\nprint("Hello, Other World!")',
    solutionCode: 'print("Hello, World!")\nprint("Hello, Other World!")'
  }
}

export const InProgress = Template.bind({})
InProgress.args = {
  panelSessionContent: {
    ...Default.args.panelSessionContent,
    session: {
      ...Default.args.panelSessionContent.session,
      dateFirstCompleted: null
    }
  }
}
<template>
  <div class="page-second">
    <CodeLanguageFormatSelect
      v-model="newAce"
    />
    <MoreOptions
      v-model="newOptions"
      :classroom="classroom"
    />
  </div>
</template>

<script>
import CodeLanguageFormatSelect from './CodeLanguageFormatSelect'
import MoreOptions from './MoreOptions'
export default {
  components: {
    CodeLanguageFormatSelect,
    MoreOptions,
  },
  props: {
    classroom: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data () {
    const cFormats = this.classroom?.aceConfig?.codeFormats
    const cFormatDefault = this.classroom?.aceConfig?.codeFormatDefault
    return {
      newAce: {
        codeLanguage: this.classroom?.aceConfig?.language || 'python',
        codeFormats: typeof cFormats === 'undefined' ? ['text-code'] : cFormats,
        codeFormatDefault: typeof cFormatDefault === 'undefined' ? 'text-code' : cFormatDefault,
      },
      newOptions: {
        classroomItems: true,
        disablePaste: false,
        liveCompletion: true,
        remix: false,
        levelChat: true,
        classroomDescription: '',
        averageStudentExp: '',
        classroomType: '',
        classesPerWeek: '',
        minutesPerClass: '',
        classDateStart: '',
        classDateEnd: '',
      },
    }
  },
  watch: {
    newAce: {
      deep: true,
      handler (newV) {
        this.$emit('input', { ...newV, ...this.newOptions })
      },
    },
    newOptions: {
      deep: true,
      handler (newV) {
        this.$emit('input', { ...this.newAce, ...newV })
      },
    },
  },
}
</script>
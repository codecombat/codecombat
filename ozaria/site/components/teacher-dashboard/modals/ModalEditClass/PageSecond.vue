<template>
  <div class="page-second">
    <div class="form-group row small">
      {{ `${pageFirst.name} : ${courseName}` }}
    </div>
    <CodeLanguageFormatSelect
      v-model="newAce"
      :courses="[pageFirst.initCourse]"
    />
    <MoreOptions
      v-model="newOptions"
      :classroom="classroom"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import utils from 'core/utils'
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
    // Shape: { name: String, initCourse: String }
    pageFirst: {
      type: Object,
      default: () => ({}),
      validator: value => Object.keys(value).length === 0 || (('name' in value) && ('initCourse' in value)),
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
  computed: {
    ...mapGetters({
      courses: 'courses/sorted',
    }),
    courseName () {
      const course = this.courses.find(({ _id }) => _id === this.pageFirst?.initCourse)
      if (!course) {
        return ''
      }
      return utils.i18n(course, 'name')
    },
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
<style scoped lang="scss">
.page-second {
  width: 100%;
}
</style>

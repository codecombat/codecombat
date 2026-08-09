<template>
  <div class="page-second">
    <div class="title">
      {{ `${pageFirst.name} - ${courseName}` }}
    </div>
    <CodeLanguageFormatSelect
      v-model="newAce"
      :course="pageFirst.course"
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
    pageFirst: {
      type: Object,
      default: () => ({}),
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
.title {
  text-align: center;
  font-weight: 800;
}
</style>
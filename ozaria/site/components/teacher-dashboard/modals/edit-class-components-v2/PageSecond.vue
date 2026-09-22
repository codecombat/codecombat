<template>
  <div class="page-second container">
    <div class="form-group row small">
      {{ `${pageFirst.name} : ${courseName}` }}
    </div>
    <CodeLanguageFormatSelect
      :value="value"
      :is-new-classroom="isNewClassroom"
      :courses="initCourses"
      @input="$emit('input', $event)"
    />
    <MoreOptions
      :value="value"
      @input="$emit('input', $event)"
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
    // Single source of truth for this page's draft, owned by the parent (ModalEditClassV2) -
    // CodeLanguageFormatSelect and MoreOptions both proxy directly onto it, no local copies.
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
    isNewClassroom: {
      type: Boolean,
      default: false,
    },
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
    // Memoized so CodeLanguageFormatSelect's `courses` prop keeps a stable reference across
    // re-renders instead of a fresh array literal each time, which otherwise causes its
    // course-derived computeds/watchers to re-fire on every unrelated re-render.
    initCourses () {
      return [this.pageFirst.initCourse]
    },
  },
}
</script>
<style scoped lang="scss">
.page-second {
  width: 100%;
}
</style>

<template>
  <li class="exam-level">
    <a
      :href="levelLink"
      target="_blank"
    >
      {{ $t('exams.level_num', { num: index }) }}
    </a>
    <img
      v-if="isCompleted"
      class="check-mark"
      src="/images/ozaria/teachers/dashboard/svg_icons/CheckMark.svg"
      style="filter: invert(48%) sepia(79%) saturate(2476%) hue-rotate(86deg) brightness(118%) contrast(119%);"
    >
  </li>
</template>

<script>
export default {
  name: 'ExamLevel',
  props: {
    level: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
    language: {
      type: String,
      required: true,
    },
    isCompleted: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    levelLink () {
      return `/play/level/${this.level.slug}?course=${this.level.courseId}&course-instance=${this.level.instanceId}&codeLanguage=${this.language}`
    },
  },
  methods: {
    makeTitle (slug) {
      const words = slug.split('-')
      for (let i = 0; i < words.length; i++) {
        const word = words[i]
        words[i] = word.charAt(0).toUpperCase() + word.slice(1)
      }
      return words.join(' ')
    },
  },
}
</script>

<style>
.exam-level {
  display: flex;
  align-items: center;
  gap: 5px;
}
</style>

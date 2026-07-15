<template>
  <div class="guide-glossary">
    <div class="content">
      <p>{{ $t('teacher_dashboard.curriculum_glossary_desc') }}</p>
      <ul class="glossary-lists">
        <li
          v-for="(item, index) in glossaryLists"
          :key="`glossary-item-${index}`"
        >
          {{ item }}
        </li>
      </ul>
    </div>
    <div class="close-text">
      <a @click="hide">{{ $t('teacher_dashboard.curriculum_glossary_close') }}</a>
    </div>
  </div>
</template>

<script>
import { mapMutations } from 'vuex'
export default {
  name: 'CurriculumGlossary',
  props: {
    product: {
      type: String,
      required: true,
    },
  },
  computed: {
    glossaryLists () {
      const text = this.$t('teacher_dashboard.curriculum_glossary_desc_' + this.product)
      return text.split(',') ?? []
    },
  },
  methods: {
    ...mapMutations({
      hideGlossary: 'baseCurriculumGuide/hideGlossary',
    }),
    hide () {
      window.tracker?.trackEvent(`Hide Curriculum Glossaary on ${this.product}`)
      this.hideGlossary(this.product)
    },
  },
}
</script>

<style scoped lang="scss">
.guide-glossary {
  max-width: 800px;
  margin: 20px;
  padding: 15px;
  border: 1px dashed #666;
  .content {
    font-size: 1.8rem;

    .glossary-lists {
      display: grid;
      gap: 5px;
      grid-template-columns: repeat(3, 1fr);
    }
  }

  .close-text {
    font-size: 1.6rem;
    text-align: end;
  }
}
</style>
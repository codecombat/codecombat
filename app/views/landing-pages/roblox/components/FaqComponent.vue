<template>
  <page-section>
    <template #heading>
      {{ $t('schools_page.faq_header') }}
    </template>
    <template #body>
      <FaqItem
        v-for="(item, index) in faqItems"
        :id="'collapse' + (index + 1)"
        :key="index"
        :question="item.question"
        :is-open="openItemId === index"
        @toggle="openItemId = openItemId === index ? null : index"
      >
        <p v-if="!Array.isArray(item.answer)">
          <mixed-color-label :text="item.answer" />
        </p>
        <ul v-else>
          <li
            v-for="(answer, answerIndex) in item.answer"
            :key="answerIndex"
          >
            <mixed-color-label :text="answer" />
          </li>
        </ul>
      </FaqItem>
    </template>
  </page-section>
</template>

<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import MixedColorLabel from '../../../../components/common/labels/MixedColorLabel.vue'
import FaqItem from '../../../../components/common/elements/FaqItem.vue'

export default {
  name: 'FaqComponent',
  components: {
    PageSection,
    FaqItem,
    MixedColorLabel
  },
  data () {
    return {
      openItemId: null,
      faqItems: Array.from(6).map((_, index) => ({
        question: $.i18n.t(`roblox.faq_${index + 1}_question`),
        answer: $.i18n.t(`roblox.faq_${index + 1}_answer`)
      }))
    }
  }
}
</script>

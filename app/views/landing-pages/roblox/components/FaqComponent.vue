<template>
  <page-section class="section">
    <template #heading>
      {{ $t('schools_page.faq_header') }}
    </template>
    <template #body>
      <FaqItem
        v-for="(item, index) in faqItems"
        :id="'collapse' + (index + 1)"
        :key="index"
        class="faq-item"
        :question="item.question"
        :is-open="openItemId === index"
        @toggle="openItemId = openItemId === index ? null : index"
      >
        <p v-if="!Array.isArray(item.answer)">
          {{ item.answer }}
        </p>
        <ul v-else>
          <li
            v-for="(answer, answerIndex) in item.answer"
            :key="answerIndex"
          >
            {{ item.answer }}
          </li>
        </ul>
      </FaqItem>
    </template>
  </page-section>
</template>

<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import FaqItem from '../../../../components/common/elements/FaqItem.vue'

export default {
  name: 'FaqComponent',
  components: {
    PageSection,
    FaqItem,
  },
  data () {
    return {
      openItemId: null,
      faqItems: Array.from({ length: 5 }).map((_, index) => ({
        question: $.i18n.t(`roblox.faq_${index + 1}_question`),
        answer: $.i18n.t(`roblox.faq_${index + 1}_answer`)
      }))
    }
  }
}
</script>

<style scoped lang="scss">
.section {
  background: linear-gradient(102.68deg, #193640 -1.44%, #021E27 100%);
}

::v-deep .faq-item {
  &.faq {
    border-bottom: 1px solid #31636F !important;
  }
  .text {
    &.collapsed {
      .q {
        color: lighten(#397A88, 20%);
      }
    }
  }
  .q {
    color: white;
  }
  .p {
    color: white !important;
  }
}

</style>

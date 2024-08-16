<template>
  <page-section>
    <template #heading>
      {{ $t('schools_page.faq_header') }}
    </template>
    <template #body>
      <div
        id="accordion"
        class="faq-list"
      >
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
      </div>
    </template>
    <template #tail>
      <p
        v-if="showFooter"
        class="p"
      >
        <mixed-color-label
          :text="$t('schools_page.faq_see_more')"
          target="_blank"
        />
      </p>
    </template>
  </page-section>
</template>

<script>
import PageSection from './PageSection.vue'
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import FaqItem from './FaqItem.vue'

export default {
  name: 'FaQs',
  components: {
    PageSection,
    FaqItem,
    MixedColorLabel
  },
  props: {
    faqItems: {
      type: Array,
      required: true
    },
    showFooter: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  data () {
    return {
      openItemId: null
    }
  }
}
</script>
<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.FA-qs {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 40px;
  justify-content: center;
  padding: 100px 135px;
  position: relative;

  @media (max-width: $screen-md-max) {
    padding: 100px 40px;
  }

  .frame {
    align-items: center;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 80px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .heading {
    @extend %font-36;
    position: relative;
    text-align: center;
  }

  .faq-list {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 0;
    position: relative;
    width: 100%;
  }

  .p {
    color: transparent;
    @extend %font-28;
    position: relative;
    text-align: center;
  }

  .span {
    color: $dark-grey;
  }

  .text-wrapper-2 {
    color: var(--color-primary);
  }
}
</style>

<template>
  <page-section class="section">
    <template #heading>
      {{ $t('schools_page.faq_header') }}
    </template>
    <template #body>
      <div
        class="faq-list"
      >
        <FaqItem
          v-for="(item, index) in faqItems"
          :id="'collapse' + (index + 1)"
          :key="index"
          :question="item.question"
          :is-open="openItemId === index"
          class="faq-item"
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
        class="see-more"
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
import PageSection from 'app/components/common/elements/PageSection'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import FaqItem from 'app/components/common/elements/FaqItem.vue'

export default {
  name: 'FaQs',
  components: {
    PageSection,
    FaqItem,
    MixedColorLabel,
  },
  props: {
    faqItems: {
      type: Array,
      required: true,
    },
  },
  data () {
    return {
      openItemId: null,
    }
  },
}
</script>
<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;

.section {
  background: linear-gradient(117.03deg, #193640 0%, #021E27 98.82%);
}

::v-deep div {
  color: white;

  &.heading {
    color: $primary-color;
  }
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
  .text-h3 .heading {
    color: $primary-color !important;
  }
  .mixed-color-label__normal {
    color: white;
  }
  .mixed-color-label__highlight {
    color: $primary-color !important;
  }
}

::v-deep .see-more {
  .mixed-color-label__normal {
    color: white;
  }
  .mixed-color-label__highlight {
    color: $primary-color !important;
  }
}

::v-deep .vector {
  filter: brightness(0) saturate(100%) invert(65%);
}

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

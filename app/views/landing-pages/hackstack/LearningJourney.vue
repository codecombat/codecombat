<template>
  <page-section class="section">
    <template #body>
      <div class="solutions">
        <div class="heading">
          <MixedColorLabel :text="title" />
        </div>
        <div class="menu-content">
          <div
            v-for="(item, index) in items"
            :key="index"
            class="list-item"
          >
            <img
              class="vector"
              :src="item.src"
              :alt="`Vector image to illustrate ${item.text}`"
              loading="lazy"
            >
            <div
              class="text-wrapper"
            >
              <div
                v-for="(line, lineIndex) in item.text.split('[NEWLINE]')"
                :key="`line-${lineIndex}`"
              >
                {{ line }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </page-section>
</template>

<script>
import MixedColorLabel from '../../../components/common/labels/MixedColorLabel.vue'
import PageSection from 'app/components/common/elements/PageSection'

export default {
  name: 'LearningJourney',
  components: {
    MixedColorLabel,
    PageSection,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      items: [
        { src: '/images/pages/hackstack/learn_1.svg', text: $.i18n.t('hackstack_page.learn_1_text') },
        { src: '/images/pages/hackstack/learn_2.svg', text: $.i18n.t('hackstack_page.learn_2_text') },
        { src: '/images/pages/hackstack/learn_3.svg', text: $.i18n.t('hackstack_page.learn_3_text') },
        { src: '/images/pages/hackstack/learn_4.svg', text: $.i18n.t('hackstack_page.learn_4_text') },
        { src: '/images/pages/hackstack/learn_5.svg', text: $.i18n.t('hackstack_page.learn_5_text') },
        { src: '/images/pages/hackstack/learn_6.svg', text: $.i18n.t('hackstack_page.learn_6_text') },
        { src: '/images/pages/hackstack/learn_7.svg', text: $.i18n.t('hackstack_page.learn_7_text') },
      ],
    }
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

::v-deep .frame {
  gap: 20px !important;
}

.section {
  background: #193640;
}

.solutions {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 80px;
  position: relative;
  width: 100%;

  .heading {
    align-self: stretch;
    color: #FFFFFF;
    @extend %font-36;
    position: relative;
    text-align: center;
  }

  ::v-deep .mixed-color-label__normal {
    color: white;
  }

  .menu-content {
    align-items: flex-start;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    gap: 50px;
    justify-content: center;
    position: relative;
    width: 100%;
    flex-wrap: wrap;
  }

  .list-item {
    align-items: center;
    display: flex;
    flex: 1;
    flex-direction: column;
    flex-grow: 1;
    gap: 40px;
    position: relative;
  }

  .vector {
    position: relative;
    width: 70px;
    height: 70px;
    color : "red";
  }

  .text-wrapper {
    align-self: stretch;
    color: #FFFFFF;
    @extend %font-20;
    position: relative;
    text-align: center;
  }
}
</style>

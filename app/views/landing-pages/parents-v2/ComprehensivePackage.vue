<template>
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

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default {
  name: 'ComprehensivePackage',
  components: {
    MixedColorLabel
  },
  props: {
    title: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      items: [
        { src: '/images/pages/parents/package-icons/icon_1.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_0_text') },
        { src: '/images/pages/parents/package-icons/icon_2.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_1_text') },
        { src: '/images/pages/parents/package-icons/icon_3.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_2_text') },
        { src: '/images/pages/parents/package-icons/icon_4.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_3_text') },
        { src: '/images/pages/parents/package-icons/icon_5.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_4_text') },
        { src: '/images/pages/parents/package-icons/icon_6.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_5_text') },
        { src: '/images/pages/parents/package-icons/icon_7.svg', text: $.i18n.t('parents_v2.comprehensive_package_item_6_text') }
      ]
    }
  }
}
</script>

  <!-- Styles remain the same -->

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
.solutions {
    align-items: center;
    display: flex;
    flex-direction: column;
    gap: 80px;
    position: relative;

    .heading {
        align-self: stretch;
        color: #000000;
        @extend %font-36;
        position: relative;
        text-align: center;
    }

    .menu-content {
        align-items: flex-start;
        align-self: stretch;
        display: flex;
        flex: 0 0 auto;
        gap: 30px;
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
        height: 70px;
    }

    .text-wrapper {
        align-self: stretch;
        @extend %font-20;
        position: relative;
        text-align: center;
        color: var(--color-dark-grey);
        width: max-content;
        display: block;
        margin: 0 auto;
    }
}
</style>

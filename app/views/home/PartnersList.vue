<template>
  <div class="frame">
    <div
      v-for="(item, index) in items"
      :key="index"
      class="div"
    >
      <img
        class="image"
        alt="Image"
        :src="item.imageSrc"
      >
      <div
        class="text-wrapper"
      >
        <div
          v-for="(line, lineIndex) in $t(item.text).split('\n')"
          :key="`line-${lineIndex}`"
        >
          {{ line }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PartnersList',
  data () {
    return {
      items: [
        {
          imageSrc: '/images/pages/home-v3/partners/image 20.webp',
          text: 'home_v3.education_partner'
        },
        {
          imageSrc: '/images/pages/home-v3/partners/image 21.webp',
          text: 'home_v3.official_member'
        },
        {
          imageSrc: '/images/pages/home-v3/partners/image 22.webp',
          text: 'home_v3.best_creativity_tool_for_students'
        },
        {
          imageSrc: '/images/pages/home-v3/partners/image 24.webp',
          text: 'home_v3.official_partner'
        },
        {
          imageSrc: '/images/pages/home-v3/partners/image 25.webp',
          text: 'home_v3.hour_of_code_activity_partner'
        },
        {
          imageSrc: '/images/pages/home-v3/partners/image 23.webp',
          text: 'home_v3.top_pick_for_learning'
        }
      ]
    }
  }
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
.frame {
    align-items: center;
    display: inline-flex;
    justify-content: space-around;
    position: relative;
    width: 100%;
    flex-wrap: wrap;
    gap: 20px;

    .div {
        align-items: center;
        display: inline-flex;
        flex: 0 0 auto;
        flex-direction: column;
        gap: 20px;
        justify-content: flex-end;
        position: relative;
    }

    .image {
        height: 63px;
        object-fit: contain;
        position: relative;
        width: 129px;
        object-position: bottom;
    }

    .text-wrapper {
        color: $light-grey;
        @extend %font-18-24;
        font-weight: 400;
        letter-spacing: 0;
        line-height: 27px;
        position: relative;
        text-align: center;
        width: 151px;
    }
}
</style>

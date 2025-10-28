<template>
  <page-section class="section">
    <template #heading>
      {{ $t('league_v2.compete_to_win') }}
    </template>
    <template #body>
      <div class="medals">
        <div
          v-for="(prize, index) in prizes"
          :key="`prize-${index}`"
          class="medal"
        >
          <img
            class="vector"
            :src="prize.src"
            :alt="`Vector image to illustrate ${prize.text}`"
            loading="lazy"
          >
          <div
            class="text-wrapper"
          >
            <div
              v-for="(line, lineIndex) in prize.text.split('[NEWLINE]')"
              :key="`line-${lineIndex}`"
              class="prize-desc"
            >
              {{ line }}
            </div>
          </div>
        </div>
      </div>
      <div class="description text-center">
        <span><a
          target="_blank"
          href="https://drive.google.com/file/d/1QGkGr26fMAP0B36enroyTOI5kYzoBEdr/view"
          rel="noopener noreferrer"
        > {{ $t('league_v2.codecombat_reserves') }}</a></span>
        <span> {{ $t('league_v2.reserved_right') }}</span>
      </div>
    </template>
  </page-section>
</template>
<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
export default {
  components: {
    PageSection,
  },
  data () {
    return {
      prizes: [
        {
          src: '/images/pages/league/prizes/grand_prize.png',
          text: $.i18n.t('league_v2.grand_prize'),
        },
        {
          src: '/images/pages/league/prizes/2nd_place.png',
          text: $.i18n.t('league_v2.second_place'),
        },
        {
          src: '/images/pages/league/prizes/3rd_place.png',
          text: $.i18n.t('league_v2.third_place'),
        },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.section {
  background-color: rgb(25, 54, 64);
}
.medals {
  display: flex;
  width: 80%;
  justify-content: space-around;

  .medal {
    text-align: center;
    flex-basis: 20%;

    img {
      height: 138px;
      margin-bottom: 20px;
    }
    .prize-desc {
      width: 200px;
    }
  }

}
.description {
  margin-top: 20px;
  width: max(90%, 1080px);
}

@media (max-width: $screen-md-min) {
  .medals {
    width: 100%;
    flex-direction: column;

    .prize-desc {
      width: unset !important;
    }
  }

  .description {
    width: 100%;
  }
}

</style>
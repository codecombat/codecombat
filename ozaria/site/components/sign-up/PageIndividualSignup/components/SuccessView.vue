<template>
  <div class="subview success-view">
    <div class="head1">
      <img
        class="check-mark"
        src="/images/pages/account/checkmark.svg"
      >
      <span>
        {{ $t('account.all_set') }}
      </span>
    </div>
    <div class="desc">
      {{ roleDesc }}
    </div>
    <div class="video">
      <YoutubeBox
        class="youtube-video"
        :video-id="'rOXRBQIXvlI'"
      />
    </div>
    <div class="awards-and-partners">
      <div class="head3">
        {{ $t('home_v3.awards_partners') }}
      </div>
      <PartnersList />
    </div>
  </div>
</template>

<script>
import PartnersList from 'app/views/home/PartnersList.vue'
import YoutubeBox from 'app/components/common/image-containers/YoutubeBox.vue'
export default {
  components: {
    PartnersList,
    YoutubeBox,
  },
  props: {
    role: {
      type: String,
      default: 'individual',
    },
  },
  computed: {
    roleDesc () {
      return $.i18n.t(`account.${this.role}_completion`)
    },
  },
}

</script>

<style scoped lang="scss">
.success-view {
  .head1 {
    img, span {
      vertical-align: bottom;
    }
  }
  .video {
    margin-top: 5rem;
  }

  .awards-and-partners {
    width: 100vw;
    background-color: white;
    text-align: center;
    padding: 4rem 2rem;

    .head3 {
      font-size: 26px;
      color: black;
      text-align: center;
      margin-bottom: 1rem;
    }

    ::v-deep .frame {
      .image {
        width: 60px;
      }

      .text-wrapper {
        font-size: 14px;
        line-height: 16px;
      }
    }
  }
}
@media (min-width: 768px) {
  .head1 {
    .check-mark {
      width: 28px;
    }
    span {
      line-height: 28px;
    }
  }

  .youtube-video {
    width: 500px;
  }
  .awards-and-partners {
    margin-top: 40px;
  }
}
@media (max-width: 768px) {
  .head1 {
    .check-mark {
      width: 8rem;
    }
    span {
      line-height: 8rem;
    }
  }

  .youtube-video {
    width: 360px;
  }
  .awards-and-partners {
    margin-top: 10rem;

    .head3 {
      font-size: 4rem;
    }
    ::v-deep .frame {
      gap: unset;

      .image {
        width: min(10vw, 80px);
      }
      .text-wrapper {
        font-size: 2rem;
        line-height: 2.5rem;
      }
    }
  }
}
</style>
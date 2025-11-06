<template>
  <div class="subview">
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
.subview {
  .head1 {
    img, span {
      vertical-align: bottom;
    }
    .check-mark {
      width: 8rem;
    }
    span {
      line-height: 8rem;
    }
  }
  .video {
    margin-top: 5rem;
  }
  .youtube-video {
    width: 360px;
  }

  .awards-and-partners {
    margin-top: 10rem;
    text-align: center;
    padding: 4rem 2rem;
    width: 100%;
    background-color: white;

    .head3 {
      font-size: 4rem;
      color: black;
      text-align: center;
      margin-bottom: 1rem;
    }
    ::v-deep .frame {
      gap: unset;

      .image {
        width: 10vw;
      }
      .text-wrapper {
        font-size: 2rem;
        line-height: 2.5rem;
      }
    }
  }
}
</style>
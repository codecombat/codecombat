<template>
  <div>
    <div class="library">
      <div class="container">
      <section class="row library__heading">
        <h2 class="library__heading-text pixel-text">
          {{ $t('library.engage_members') }}
        </h2>
        <button class="btn library__heading-btn btn-moon" @click="toggleLicenseModal">
          {{ $t('general.contact_us') }}
        </button>
      </section>

      <section class="library__sub">

        <div class="row library__sub-1">
          <div class="library__sub-text col-md-6">
            {{ $t('library.importance_blurb') }}
          </div>
          <div class="library__sub-image col-md-6">
            <img src="/images/pages/library/library-students.png"
              alt="Students in library"
              class="library__sub-image-img img-responsive teal-border">
          </div>
        </div>

        <div class="row library__sub-2">
          <div class="library__sub-image col-md-6">
            <img src="/images/pages/library/teach-real-code.png"
              alt="Teach real code"
              class="library__sub-image-img img-responsive teal-border">
          </div>
          <div class="library__sub-text col-md-6">
            {{ $t("library.games_teach_blurb") }}
          </div>
        </div>

      </section>

      <section class="library__needs">
        <div class="library__needs__heading pixel-text">
          {{ $t("library.platform_built") }}
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.accessible') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.accessible_blurb') }}
            </div>
          </div>
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/kids-in-library.jpeg"
              alt="Students with computer" class="img-responsive teal-border">
          </div>
        </div>

        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/self-paced-intuitive-5.png"
              alt="Self paced and intuitive" class="img-responsive teal-border">
          </div>
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.self_paced_intuitive') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.self_paced_intuitive_blurb') }}
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.engaging_content') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.engaging_content_blurb') }}
            </div>
          </div>
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/parents/power_of_play_capstone.gif"
              alt="Engaging" class="img-responsive teal-border">
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/calgary-login.png"
              alt="Calgary library page" class="img-responsive teal-border">
          </div>
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.api_integrate') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.api_integrate_blurb') }}
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.privacy') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.privacy_blurb') }} {{ $t('library.see') }} <a href="/privacy" target="_blank">{{ $t('library.privacy_policy') }}</a>
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.communication_limit') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.communication_limit_blurb') }}
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.usage_stats') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.usage_stats_blurb') }}
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              {{ $t('library.esports') }}
            </div>
            <div class="library__needs__info__text-sub">
              {{ $t('library.esports_blurb') }}
            </div>
          </div>
        </div>
        <div class="library__continue">
          <img class="img-responsive"
            src="/images/pages/parents/graphic_07.svg" style="margin: 0 auto; transform: translate(-47%, 0);" loading="lazy"/>
        </div>
        <section class="library__footer">
          <div class="library__footer-content row">
            <div class="col-md-offset-2 col-md-8">
              <h2 class="library__footer-text pixel-text">
                {{ $t('library.work_with_us_blurb') }}
              </h2>
              <div class="library__footer-cta">
                <button class="btn library__footer-cta-btn btn-moon" @click="toggleLicenseModal">
                  {{ $t('library.schedule_demo') }}
                </button>
              </div>
            </div>
          </div>
        </section>
      </section>
    </div>
    </div>
    <modal-get-licenses
      v-if="showLicenseModal"
      :subtitle="$t('library.license_modal_subtitle')"
      email-message="Hi CodeCombat team! I’m interested in learning more about CodeCombat and how it can be used for my library or library network membership.

        Name of Library or Library Network:
        State or Region Served:
        My Role:
        My Phone Number:
      "
      :ask-school-info="askSchoolInfo"
      :licenses-needed-text="$t('library.license_modal_members')"
      :licenses-needed-placeholder="$t('library.license_modal_members_placeholder')"
      :modal-title="$t('library.license_modal_contact')"
      @close="toggleLicenseModal"
      />
  </div>
</template>

<script>
import ModalGetLicenses from '../../components/common/ModalGetLicenses'
export default {
  name: 'LibraryMainView',
  components: {
    ModalGetLicenses
  },
  data () {
    return {
      showLicenseModal: false,
      askSchoolInfo: false
    }
  },
  methods: {
    toggleLicenseModal () {
      this.showLicenseModal = !this.showLicenseModal
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
@import "app/styles/style-flat-variables";
@import "app/styles/bootstrap/variables";

.library {
  font-size: 62.5%;
  font-family: "Work Sans", "Open Sans", sans-serif;

  padding-top: 3rem;
  background: linear-gradient(262.39deg, #D7EFF2 -1.56%, #FDFFFF 95.05%);
  &__heading {
    text-align: center;
    margin-bottom: 5rem;

    background-image: url(/images/pages/parents/image_cloud_3.svg);
    background-repeat: no-repeat;

    &-text {
      font-weight: 700;
      font-size: 4.5rem;
      line-height: 6rem;

      margin-bottom: 2rem;
    }
  }

  &__sub {
    background-image: url(/images/pages/parents/image_cloud_4.svg);
    background-repeat: no-repeat;
    background-position: center top;

    margin-bottom: 5rem;
    &-text {
      font-size: 2.4rem;
      line-height: 3rem;
      letter-spacing: 0.44px;
    }

    &-image {
      padding-top: 1rem;
    }

    &-1 {
      margin-bottom: 5rem;
    }
  }

  &__needs {
    background-image: url(/images/pages/parents/image_cloud_1.svg);
    background-repeat: no-repeat;
    background-position: right top;

    &-only-text:nth-child(even) {
      background-image: url(/images/pages/parents/image_cloud_4.svg);
      background-repeat: no-repeat;
      background-position: right top;
    }

    @media (min-width: $screen-md) {
      &-only-text {
        width: 80%;
      }
    }

    &__heading {
      font-weight: 700;
      font-size: 4rem;
      line-height: 5rem;

      background: url(/images/ozaria/home/heading_corner.svg) no-repeat left 0 top 0;
      padding: 12px 0 12px 20px;

      margin-bottom: 3rem;
    }

    &__info {
      margin-bottom: 6rem;

      &__text {
        &-heading {
          font-weight: 700;
          font-size: 2.5rem;
          line-height: 3.8rem;
          letter-spacing: .56px;

          margin-bottom: 1rem;
        }

        &-sub {
          font-size: 2.4rem;
          line-height: 3rem;
          letter-spacing: .444px;
        }
      }

      &-img {
        padding-top: 1rem;
      }

      @media (max-width: $screen-md) {
        &-img {
          display: none;
        }
      }
    }
  }

  &__footer {
    border-radius: 38px;
    border: 4px solid #6AE8E3;
    padding: 3rem;

    text-align: center;

    &-text {
      font-size: 2.6rem;
      line-height: 4rem;
      letter-spacing: 0.444px;
      font-weight: 400;
      margin-bottom: 2rem;
    }
  }
}

.pixel-text {
  font-family: $pixel-headline-font;
  color: $navy;
}

.teal-border {
  border: 10px solid $teal;
  box-sizing: border-box;
  border-radius: 20px;
}
</style>

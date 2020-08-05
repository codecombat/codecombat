<template>
    <div class="jumbotron">
        <div class="row">
            <div class="col-lg-5 col-md-6">
                <h1>{{ $t('parents_landing_2.splash_title') }}</h1>
            </div>
        </div>
        <div class="row">
            <div class="col-lg-4 col-md-5">
                <a v-if="isParentsPage" href="#" class="full-width button" @click="onCtaClick">
                    {{ $t('parents_landing_2.learn_with_instructor') }}
                </a>
                <a v-else href="#" class="full-width button" @click="onCtaClick">
                    {{ $t('parents_landing_2.start_free_trial_today') }}
                </a>
            </div>
        </div>
        <div class="row" v-if="isParentsPage">
            <div class="col-lg-4 col-md-5">
                <a href="#premium" class="full-width button">
                    {{ $t('parents_landing_2.learn_at_own_pace') }}
                </a>
            </div>
        </div>
    </div>

</template>

<script>
  export default {
    props: {
      type: {
        type: String,
        required: true
      }
    },

    computed: {
      isParentsPage: function () {
        return this.type === 'parents'
      }
    },

    methods: {
      onCtaClick (e) {
        e.preventDefault()
        this.$emit('cta-clicked')
      }
    }
  }
</script>

<style scoped>
    .jumbotron {
        padding: 70px;
        margin-bottom: 0;
        min-height: 580px;

        background-image: url("/images/pages/parents/jumbotron@1x.png");
        background-size: cover;
        background-repeat: no-repeat;
        background-position: center;

    }

    .jumbotron h1 {
        margin-bottom: 10px;
    }

    .jumbotron .button {
        margin-top: 30px;
        max-width: 320px;
    }

    @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
        .jumbotron {
            background-image: url("/images/pages/parents/jumbotron@2x.png");
        }
    }

</style>

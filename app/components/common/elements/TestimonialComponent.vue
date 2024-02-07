<template>
  <div class="testimonial">
    <p
      v-if="quote"
      class="testimonial__quote"
    >
      {{ quote }}
    </p>
    <learn-more-button
      v-if="fullReviewLink && fullReviewText"
      :link="fullReviewLink"
    >
      {{ fullReviewText }}
    </learn-more-button>
    <profile-card
      :name="name"
      :title="title"
      :image="image"
    />
  </div>
</template>

<script>
import LearnMoreButton from '../buttons/LearnMoreButton.vue'
import ProfileCard from './ProfileCard.vue'

export default {
  name: 'TestimonialComponent',
  components: {
    ProfileCard,
    LearnMoreButton
  },
  props: {
    quote: {
      type: String,
      default: null,
      required: false
    },
    name: {
      type: String,
      default: null,
      required: false
    },
    title: {
      type: String,
      default: null,
      required: false
    },
    image: {
      type: String,
      default: null,
      required: false
    },
    fullReviewText: {
      type: String,
      default: null,
      required: false
    },
    fullReviewLink: {
      type: String,
      default: null,
      required: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.testimonial {
  display: flex;
  flex-direction: column;
  gap: 40px;

  &__quote {
    @extend %font-24-34;
    color: $dark-grey-2;
    font-style: italic;
    font-weight: 700;
  }
}
</style>

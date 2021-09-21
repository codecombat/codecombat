<template>
  <div class="container-background">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <a
            href="#"
            @click="$emit('click')"
          >
            {{ buttonText }}
          </a>
        </div>
      </div>

      <div class="row subtext" v-if="subtext">
        <div class="col-lg-12 text-center">
          {{ subtext }}
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>

a {
  font-family: Work Sans;
  font-style: normal;
  font-weight: bolder;
  font-size: 20px;
  line-height: 16px;
  color: #131B25;

  min-width: 268px;
  min-height: 50px;

  padding: 16px 36px;

  background: #fcbb00;
  border-radius: 9.5px;
}

a:hover {
  background: #fcd200;
  text-decoration: none;
}

.subtext  {
  margin-top: 15px;
  font-family: 'Work Sans', sans-serif;
  font-size: 16px;
  line-height: 24px;
  font-weight: 300;
  color: #131B25;
}

</style>

<script>
export default {
  props: {
    buttonText: {
      type: String,
      default: 'Schedule a Free Class'
    },
    subtext: {
      type: String,
      default: ''
    }
  }
}
</script>

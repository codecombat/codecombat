<template>
  <div class="container-background">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <a
            href="#"
            @click="$emit('click')"
          >
            Schedule a Free Class
          </a>
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

</style>

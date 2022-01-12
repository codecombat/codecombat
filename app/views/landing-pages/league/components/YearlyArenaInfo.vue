<template>
  <div id="yearly-arenas" class="row flex-row">
    <div
      class="col-sm-4 text-center xs-pb-20"
      v-for="arena in arenas"
      :key="arena.name"
    >
      <h3 class="arena-name">{{ $t(`league.${arena.i18nTitle}`) }} {{ $t(`league.${arena.i18nType}`) }}</h3>
      <div class="arena-period">{{ arena.period }}</div>
      <img
        class="img-responsive arena-img"
        :src="arena.imgPath"
        loading="lazy"
        :alt="arena.name"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'YearlyArenaInfo',
  data () {
    return {
      arenas: [
        {
          name: 'Tundra Tower Cup',
          i18nTitle: 'tundra_tower',
          i18nType: 'cup',
          period: 'Jan - Apr 2022',
          imgPath: '/images/pages/league/tundra-tower-cup.png'
        },
        {
          name: 'Sandstorm Blitz',
          i18nTitle: 'sandstorm',
          i18nType: 'blitz',
          period: 'May - Aug 2022',
          imgPath: '/images/pages/league/sand-storm-blitz.png'
        },
        {
          name: 'Lava Lake Clash',
          i18nTitle: 'lava_lake',
          i18nType: 'clash',
          period: 'Sep - Dec 2022',
          imgPath: '/images/pages/league/lava-lake-clash.png'
        }
      ]
    }
  }
}
</script>

<style scoped lang="scss">
.arena-img {
  width: 300px;
  height: 300px;
  object-fit: scale-down;
  margin-left: auto;
  margin-right: auto;
}
.arena-name {
  color: #30EFD3;
  font-size: 28px;
  line-height: 40px;
}
.arena-period {
  margin-bottom: 15px;
}
</style>

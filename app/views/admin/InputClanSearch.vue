<script>
export default {
  data: (() => ({
    searchString: '',
    autoComplete: []
  })),

  methods: {
    debounceInput: _.debounce(async function (e) {
      const fuzzyString = e.target.value
      if (fuzzyString === '') {
        this.autoComplete = []
        return
      }
      const res = await fetch(`/db/clan?project=slug,name,displayName&term=${fuzzyString}&limit=10`)
      const json = await res.json()
      if (res.status !== 200) {
        noty({
          text: json.message,
          layout: 'topCenter',
          type: 'error',
          timeout: 5000
        })
        return
      }

      this.autoComplete = json
    }, 500)
  }
}
</script>

<template>
  <div class="form-group">
    <label>Clan/Team search</label>
    <input @input="debounceInput" id="clan-search" class="form-control" v-model="searchString"/>
    <ul>
      <li v-for="{ slug, name, displayName } in autoComplete" :key="slug">
        <a :href="`/league/${slug}`">{{ displayName || name }}</a>
      </li>
    </ul>
  </div>
</template>

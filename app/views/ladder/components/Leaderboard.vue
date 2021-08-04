<script>
  /**
   * TODO: Extend or create an alternative leaderboard compatible with teams (humans/ogres)
   * TODO: This leaderboard is not only shown on the league url but also the ladder url.
   */
  import utils from 'core/utils'

  export default Vue.extend({
    name: 'leaderboard-component',
    props: {
      scoreType: {
        type: String,
        default: 'arena'
      },
      league: {
        type: Object,
        default: null
      },
      level: {
        type: Object,
        default: () => {}
      },
      playerCount: {
        type: Number,
        default: 0
      },
      clanId: {
        type: String,
        default: '_global'
      },
      title: {
        type: String,
        default: ''
      },
      tableTitles: {
        type: Array,
        default () {
          return []
        }
      }
    },
    data () {
      return {
        selectedRow: [],
        ageFilter: false,
      }
    },
    computed: {
      ageBrackets () {
        let brackets = utils.ageBrackets
        if (this.$store.state.features.china) {
           brackets = utils.ageBracketsChina
        }
        return brackets.map((b) => {
          return {
            name: this.getAgeBracket(b.slug),
            slug: b.slug
          }
        })
      }
    },
    mounted () {
      let histogramWrapper = $('#histogram-display-humans')
      let histogramData = null
      let url = `/db/level/${this.level.get('original')}/rankings-histogram?team=humans&levelSlug=${this.level.get('slug')}`
      if (this.league) {
        url += '&leagues.leagueID=' + this.league.id
      }
      $.when(
        $.get(url, (data) => histogramData = data)
      ).then(() => this.generateHistogram(histogramWrapper, histogramData, 'humans'))
    },
    methods: {
      loadMore () {
        this.$emit('load-more')
      },
      generateHistogram (histogramElement, histogramData, teamName) {
        console.log('generate hist 1')
        // renders twice, hack fix
        if ($('#' + histogramElement.attr('id')).has('svg').length)
          return
        if (!histogramData.length)
          return histogramElement.hide()

        histogramData = histogramData.map((d) => d * 100)
        let margin = {
          top: 20,
          right: 20,
          bottom: 30,
          left: 15
        }
        let width = 470 - margin.left - margin.right
        let height = 125 - margin.top - margin.bottom
        let axisFactor = 1000
        let minX = Math.floor(Math.min(...histogramData) / axisFactor) * axisFactor
        let maxX = Math.ceil(Math.max(...histogramData) / axisFactor) * axisFactor
        let x = d3.scale.linear().domain([minX, maxX]).range([0, width])
        let data = d3.layout.histogram().bins(x.ticks(20))(histogramData)
        let y = d3.scale.linear().domain([0, d3.max(data, (d) => d.y)]).range([height, 10])

        // create the x axis
        let xAxis = d3.svg.axis().scale(x).orient('bottom').ticks(5).outerTickSize(0)

        let svg = d3.select('#histogram-display-humans').append('svg')
                    .attr('width', width + margin.left + margin.right)
                    .attr('height', height + margin.top + margin.bottom)
                    .append('g')
                    .attr('transform', `translate(${margin.left}, ${margin.top})`)
        let barClass = 'humans-bar'

        let bar = svg.selectAll('.bar')
                     .data(data)
                     .enter().append('g')
                     .attr('class', barClass)
                     .attr('transform', (d) => `translate(${x(d.x)}, ${y(d.y)})`)

        bar.append('rect')
                     .attr('x', 1)
                     .attr('width', width/20)
                     .attr('height', (d) => height - y(d.y))
        /* let scorebar = svg.selectAll('.specialbar')
         *                   .data([playerScore])
         *                   .enter().append('g')
         *                   .attr('class', 'specialbar')
         *                   .attr('transform', "translate(#{x(playerScore)}, 0)") */

        /* scorebar.append('rect')
         *         .attr('x', 1)
         *         .attr('width', 3)
         *         .attr('height', height) */
        let rankClass = 'rank-text humans-rank-text'

        let message = `${histogramData.length.toLocaleString()} players`
        /* if(@leaderboards[teamName].session)
         *   //# TODO: i18n for these messages
         *   if(this.league)
         *     //# TODO: fix server handler to properly fetch myRank with a leagueID
         *     message = "#{histogramData.length} players in league" */
        /* else if(@leaderboards[teamName].myRank <= histogramData.length) {
         *   message = "##{@leaderboards[teamName].myRank} of #{histogramData.length}"
         *   message += "+" if histogramData.length >= 100000
         * } */
        /* else if(@leaderboards[teamName].myRank is 'unknown')
         *   message = "#{if histogramData.length >= 100000 then '100,000+' else histogramData.length} players"
         * else
         *   message = 'Rank your session!' */
        svg.append('g')
           .append('text')
           .attr('class', rankClass)
           .attr('y', 0)
           .attr('text-anchor', 'end')
           .attr('x', width)
           .text(message)

        //#Translate the x-axis up
        svg.append('g')
           .attr('class', 'x axis')
           .attr('transform', 'translate(0, ' + height + ')')
           .call(xAxis)

        histogramElement.show()

      },
      toggleAgeFilter () {
        this.ageFilter = !this.ageFilter
      },
      filterAge (slug) {
        this.$emit('filter-age', slug)
        this.ageFilter = false
      },
      computeClass (slug, item='') {
        if (slug == 'name') {
          return {'name-col-cell': 1, ai: /(Bronze|Silver|Gold|Platinum|Diamond) AI/.test(item)}
        }
        if (slug == 'team') {
          return {capitalize: 1, 'clan-col-cell': 1}
        }
        if (slug == 'language') {
          return {'code-language-cell': 1}
        }
      },
      computeStyle (item, index){
        if (this.tableTitles[index].slug == 'language') {
          return {'background-image': `url(/images/common/code_languages/${item}_icon.png)`}
        }
      },
      scoreForDisplay (row) {
        if (this.scoreType === 'codePoints') {
          return row.totalScore.toLocaleString()
        }
        let score = (((row.leagues || []).find(({ leagueID }) => leagueID === this.clanId) || {}).stats || {}).totalScore || row.totalScore
        if (/(Bronze|Silver|Gold|Platinum|Diamond) AI/.test(row.creatorName) && score == row.totalScore) {
          // Hack: divide display score by 2, since the AI doesn't have league-specific score
          score /= 2
        }
        return Math.round(score * 100).toLocaleString()
      },

      getClan (row) {
        return (row.creatorClans || [])[0] || {}
      },

      getAgeBracket (item) {
        return $.i18n.t(`ladder.bracket_${(item || 'open').replace(/-/g, '_')}`)
      },

      getCountry (code) {
        return utils.countryCodeToFlagEmoji(code)
      },

      getCountryName (code) {
        return utils.countryCodeToName(code)
      },

      computeTitle (slug, item) {
        if(slug == 'country') {
          return this.getCountryName(item)
        }
        else {
          return ''
        }
      },
      computeBody  (slug, item) {
        if(slug == 'country') {
          return this.getCountry(item)
        } else if(slug == 'fight'){
          return "<a href='" + `/play/level/${this.level.get('slug')}?team=humans&opponent=${item}` + (this.league ? `&league=${this.league.id}`: '')  + "'><span>" + $.i18n.t('ladder.fight') +"</span></a>"
        } else {
          return item
        }
      },
      classForRow (row) {
        if (row.creator === me.id) {
          return 'my-row'
        }

        if (window.location.pathname === '/league' && row.fullName) {
          return 'student-row'
        }

        return ''
      },
      onClickSpectateCell (rank) {
        let index = this.selectedRow.indexOf(rank)
        if (index != -1) {
          this.$delete(this.selectedRow, index)
        }
        else {
          this.selectedRow = Array.concat(this.selectedRow, [rank]).slice(-2)
        }
        this.$emit('spectate', this.selectedRow)
      }

    }
  });
</script>

<template lang="pug">
  .table-responsive(:class="{'col-md-6': scoreType=='arena'}")
    div(id="histogram-display-humans", class="histogram-display", data-team-name='humans' v-if="scoreType == 'arena'")
    table.table.table-bordered.table-condensed.table-hover.ladder-table
      thead
        tr
          th(colspan=13)
            span {{ title }}
            span &nbsp;
            span {{ $t('ladder.leaderboard') }}
            span(v-if="playerCount > 1")
              span  -&nbsp;
              span {{ playerCount.toLocaleString() }}
              span  players

        tr
          th(v-for="t in tableTitles" :key="t.slug" :colspan="t.col" :class="computeClass(t.slug)")
            | {{ t.title }}
            span.age-filter(v-if="t.slug == 'age'")
              .glyphicon.glyphicon-filter(@click="toggleAgeFilter")
              #age-filter(:class="{display: ageFilter}")
                .slug(v-for="bracket in ageBrackets" @click="filterAge(bracket.slug)")
                  span {{bracket.name}}

          th.iconic-cell
            .glyphicon.glyphicon-eye-open

      tbody
        tr(v-for="row, rank in rankings" :key="rank" :class="classForRow(row)")
          template(v-if="row.type==='BLANK_ROW'")
            td(colspan=3) ...
          template(v-else)
            td(v-for="item, index in row" :key="'' + rank + index" :colspan="tableTitles[index].col" :style="computeStyle(item, index)" :class="computeClass(tableTitles[index].slug, item)" :title="computeTitle(tableTitles[index].slug, item)" v-html="index != 0 ? computeBody(tableTitles[index].slug, item): ''")
            td.spectate-cell.iconic-cell(@click="onClickSpectateCell(rank)")
              .glyphicon(:class="{'glyphicon-eye-open': selectedRow.indexOf(rank) != -1}")

    #load-more.btn.btn-sm(data-i18n='editor.more', @click="loadMore")
</template>

<style scoped lang="scss">
  .ladder-table {
    /* background-color: #F2F2F2; */
    background-color: white;
  }
  .ladder-table td {
    padding: 2px 2px;
  }

  .ladder-table .code-language-cell {
    height: 16px;
    background-position: center;
    background-size: 16px;
    background-repeat: no-repeat;
    padding: 0 10px
  }

  .ladder-table tr {
    font-size: 16px;
    text-align: center;
  }
  .ladder-table tbody tr:hover td{
    background-color: #FFFFFF;
  }

  .ladder-table th {
    text-align: center;
  }

  .name-col-cell, .clan-col-cell {
    max-width: 170px;
    text-overflow: ellipsis;
    white-space: nowrap;
    overflow: hidden;
  }

  .capitalize {
    text-transform: capitalize;
  }

  .name-col-cell.ai {
    color: #3f44bf;
  }

  .my-row {
    background-color: #d1b147;
  }

  .student-row {
    background-color: #bcff16;
  }

  .age-filter {
    position: relative;

    .glyphicon {
      cursor: pointer;
    }

    #age-filter {
      position: absolute;
      display: none;
      background-color: #fcf8f2;
      border: 1px solid #ddd;
      border-radius: 5px;
      right: 0;
      width: 5em;

      &.display {
        display: block;
      }

      .slug {
        margin: 5px 10px;
        cursor: pointer;
      }
    }
  }
</style>

<style lang="scss">
  #histogram-display-humans {
    height: 130px;
    background-color: white;
    display: flex;
    justify-content: center;

    svg {
      overflow: visible;

      .humans-bar rect {
        shape-rendering: crispEdges;
      }
      
      .humans-bar text{
        fill: #fff;
      }
      
      .specialbar rect {
        fill: #555555;
      }
      
      .axis path , .axis line{
        fill: none;
        stroke: #555555;
        shape-rendering: crispEdges;
      }
      
      .humans-bar {
        fill: #bf3f3f;
        shape-rendering: crispEdges;
      }
      text {
        fill: #555555;
      }
      
      .rank-text {
        font-size: 15px;
        fill: #555555;
      }
      
      .humans-rank-text {
        fill: #bf3f3f;
      }
      
    }
  }
</style>

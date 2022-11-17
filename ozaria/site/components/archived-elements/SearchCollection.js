export default class SearchCollection extends Backbone.Collection {
  constructor (modelURL, model, term, projection) {
    super()
    this.model = model
    this.term = term
    this.projection = projection
    this.url = `${modelURL}?project=`
    if (this.projection != null ? this.projection.length : undefined) {
      this.url += 'created'
      for (let projected of Array.from(this.projection)) {
        this.url += ',' + projected
      }
    } else {
      this.url += 'true'
    }
    if (this.term) {
      return this.url += `&term=${this.term}`
    }
  }

  comparator(a, b) {
    let score = 0
    if (a.getOwner() === me.id) { score -= 9001900190019001 }
    if (b.getOwner() === me.id) { score += 9001900190019001 }
    score -= new Date(a.get('created'))
    score -= -(new Date(b.get('created')))
    if (score < 0) {
      return -1
    }

    return (score > 0) ? 1 : 0
  }
}

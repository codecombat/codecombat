module.exports = class DialogueAnimator
  jqueryElement: null
  childrenToAdd: null
  charsToAdd: null
  childAnimator: null

  constructor: (html, @jqueryElement) ->
    d = $('<div></div>').html(html)
    @childrenToAdd = _.map(d[0].childNodes, (e) -> return e)
    @t0 = new Date()
    @charsAdded = 0
    @charsPerSecond = 25

  tick: ->
    if not @charsToAdd and not @childAnimator
      @addNextElement()

    if @charsToAdd
      @addSingleChar()
      return

    if @childAnimator
      @childAnimator.tick()
      if @childAnimator.done()
        @childAnimator = null

  addNextElement: ->
    return unless @childrenToAdd.length
    nextElem = @childrenToAdd[0]
    @childrenToAdd = @childrenToAdd[1..]
    if nextElem.nodeName is '#text'
      @charsToAdd = nextElem.nodeValue
    else
      value = nextElem.innerHTML
      newElem = $(nextElem).html('')
      @jqueryElement.append(newElem)
      if value
        @charsAdded += @childAnimator.getCharsAdded() if @childAnimator
        @childAnimator = new DialogueAnimator(value, newElem)

  addSingleChar: ->
    elapsed = (new Date()) - @t0
    nAdded = @getCharsAdded()
    nToHaveBeenAdded = Math.round @charsPerSecond * elapsed / 1000
    nToAdd = Math.min nToHaveBeenAdded - nAdded, @charsToAdd.length
    @jqueryElement.html(@jqueryElement.html() + @charsToAdd.slice(0, nToAdd))
    @charsToAdd = @charsToAdd.slice(nToAdd)
    if @charsToAdd.length is 0
      @charsToAdd = null
    @charsAdded += nToAdd

  getCharsAdded: ->
    @charsAdded + (@childAnimator?.charsAdded ? 0)

  done: ->
    return false if @childrenToAdd.length > 0
    return false if @charsToAdd
    return false if @childAnimator
    return true

{BufferedProcess, CompositeDisposable} = require 'atom'

Template = """
  <ul class="centered background-message">
    <li class="message"></li>
  </ul>
"""

module.exports =
class BackgroundTipsElement extends HTMLElement
  StartDelay: 1000
  DisplayDuration: 10000
  FadeDuration: 300

  createdCallback: =>
    @index = -1

    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.onDidAddPane => @updateVisibility()
    @disposables.add atom.workspace.onDidDestroyPane => @updateVisibility()
    @disposables.add atom.workspace.onDidChangeActivePaneItem => @updateVisibility()

    @startTimeout = setTimeout((=> @start()), @StartDelay)

  attachedCallback: =>
    @innerHTML = Template
    @message = @querySelector('.message')

  destroy: =>
    @stop()
    @disposables.dispose()
    @destroyed = true

  attach: =>
    paneView = atom.views.getView(atom.workspace.getActivePane())
    top = paneView.querySelector('.item-views')?.offsetTop ? 0
    @style.top = top + 'px'
    paneView.appendChild(this)

  detach: =>
    @remove()

  updateVisibility: =>
    if @shouldBeAttached()
      @start()
    else
      @stop()

  shouldBeAttached: ->
    atom.workspace.getPanes().length is 1 and not atom.workspace.getActivePaneItem()?

  start: =>
    return if not @shouldBeAttached() or @interval?
    @attach()
    @showNextTip()
    @interval = setInterval((=> @showNextTip()), @DisplayDuration)

  stop: =>
    @remove()
    clearInterval(@interval) if @interval?
    clearTimeout(@startTimeout)
    clearTimeout(@nextTipTimeout)
    @interval = null

  showNextTip: =>
    @getFortune (fortune) =>
      @message.classList.remove('fade-in')
      @nextTipTimeout = setTimeout =>
        @message.innerHTML = fortune.replace(/\n/g, '<br>')
        @message.classList.add('fade-in')
      , @FadeDuration

  getFortune: (cb) ->
    output = ''
    errorOutput = ''
    fortuneCommand = atom.config.get('fortune-background-tips.fortuneCommand').split(' ')
    command = fortuneCommand[0]
    args = fortuneCommand[1..]
    stdout = (text) -> output += text
    stderr = (text) -> errorOutput += text
    exit = (code) ->
      if code is 0
        cb output
      else
        cb "Couldn't get forutne; #{command} exited with code: #{code}<br>#{errorOutput}"
    proc = new BufferedProcess({command, args, stdout, stderr, exit})
    proc.onWillThrowError ({error, handle}) ->
      handle()
      if error.errno = 'ENOENT'
        cb "Command '#{command}' not found; please check your fortune-background-tips settings"
      else
        cb "Couldn't spawn #{command}: #{error.message}"

module.exports = document.registerElement 'fortune-background-tips', prototype: BackgroundTipsElement.prototype

{CompositeDisposable} = require 'atom'

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable

    if atom.packages.isPackageActive('background-tips')
      pack = atom.packages.getActivePackage('background-tips')
      pack.deactivate()

    @subscriptions.add atom.packages.onDidActivatePackage (pack) ->
      pack.deactivate() if pack.name is 'background-tips'

    BackgroundTipsView = require './background-tips-view'
    @backgroundTipsView = new BackgroundTipsView()

  deactivate: ->
    @subscriptions.dispose()
    @backgroundTipsView.destroy()

  config:
    fortuneCommand:
      order: 1
      title: 'fortune Command'
      default: 'fortune -s'
      type: 'string'
      description: "The command (plus arguments) used to run 'fortune'"

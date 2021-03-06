utils                   = require 'utils'
{ mode_hints }          = require 'mode-hints/mode-hints'
{ updateToolbarButton } = require 'button'
{ searchForMatchingCommand
, isEscCommandKey
, isReturnCommandKey
, findStorage }         = require 'commands'

modes = {}

modes['normal'] =
  onEnter: (vim, storage) ->
    storage.keys ?= []
    storage.commands ?= {}

  onLeave: (vim, storage) ->
    storage.keys.length = 0

  onInput: (vim, storage, keyStr, event) ->
    storage.keys.push(keyStr)

    { match, exact, command } = searchForMatchingCommand(storage.keys)

    if match
      if exact
        commandStorage = storage.commands[command.name] ?= {}
        command.func(vim, commandStorage, event)
        storage.keys.length = 0
      return true
    else
      storage.keys.length = 0

modes['insert'] =
  onEnter: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: true})
  onLeave: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: false})
    utils.blurActiveElement(vim.window)
  onInput: (vim, storage, keyStr) ->
    if isEscCommandKey(keyStr)
      vim.enterMode('normal')
      return true

modes['find'] =
  onEnter: (vim, storage, options) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()

    findBar.onFindCommand()
    findBar._findField.focus()
    findBar._findField.select()

    return unless highlightButton = findBar.getElement("highlight")
    return unless highlightButton.checked != options.highlight
    highlightButton.click()

  onLeave: (vim) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value
    findBar.close()

  onInput: (vim, storage, keyStr) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    if isEscCommandKey(keyStr) or isReturnCommandKey(keyStr)
      vim.enterMode('normal')
      return true
    else
      findBar._findField.focus()

modes['hints'] = mode_hints

exports.modes = modes

PulsarKeyboardMacrosView = require './pulsar-keyboard-macros-view'
{CompositeDisposable} = require 'atom'

KeymapManager = require '@pulsar-edit/atom-keymap'
keymaps = new KeymapManager
keystrokeForKeyboardEvent = keymaps.keystrokeForKeyboardEvent
#keydownEvent = keymaps.keydownEvent
charCodeFromKeyIdentifier = keymaps.charCodeFromKeyIdentifier
characterForKeyboardEvent = (event) ->
  event.key if event.key.length is 1 and not (event.ctrlKey or event.metaKey)

class MacroCommand
  @viewInitialized: false

  @resetForToString: ->
    MacroCommand.viewInitialized = false

  # override this method
  execute: ->

  # override this method
  toString: ->

  # override this method
  toSaveString: ->

  @loadStringAsMacroCommands: (text) ->
    result = {}
    lines = text.split('\n')
    index = 0
    while index < lines.length
      line = lines[index++]
      if line.length == 0
        continue
      #if line[0] != '>' or line.length < 2
      if line[0] != '>'
        console.error 'illegal format when loading macro commands.'
        return null

      if line.length == 1
        name = ''
      else
        name = line.substring(1)
      #console.log('name: ', name)

      cmds = []

      while (index < lines.length) and (lines[index][0] == '*')
        line = lines[index++]
        if line[0] != '*' or line.length < 2
          console.error 'illegal format when loading macro commands.'
          return null

        switch line[1]
          when 'I'
            while (index < lines.length) and (lines[index][0] == ':')
              line = lines[index++]
              if line.length < 2
                continue

              events = []
              for i in [1..line.length-1]
                event = MacroCommand.keydownEventFromString(line[i])
                events.push event

              cmds.push(new InputTextCommand(events))

          when 'D'
            line = lines[index++]
            if line[0] != ':' or line.length < 2
              console.error 'illegal format when loading macro commands.'
              return null
            cmd = new DispatchCommand('')
            cmd.command_name = line.substring(1) # fix this line
            cmds.push(cmd)

          when 'K'
            while (index < lines.length) and (lines[index][0] == ':')
              line = lines[index++]
              s = line.substring(1)
              event = MacroCommand.keydownEventFromString(s)
              cmds.push(new KeydownCommand(event))

          else
            console.error 'illegal format loading macro commands.'
            return null

      result[name] = cmds
      # end while

    result

  @keydownEvent: (dic) ->
    new KeyboardEvent("keydown", dic)

  @keydownEventFromString: (keystroke) ->
    hasCtrl = keystroke.indexOf('ctrl-') > -1
    hasAlt = keystroke.indexOf('alt-') > -1
    hasShift = keystroke.indexOf('shift-') > -1
    hasCmd = keystroke.indexOf('cmd-') > -1
    s = keystroke.replace('ctrl-', '')
    s = s.replace('alt-', '')
    s = s.replace('shift-', '')
    key = s.replace('cmd-', '')
    event = @keydownEvent({
      key: key
      ctrl: hasCtrl
      alt: hasAlt
      shift: hasShift
      cmd: hasCmd
    })
    event


class InputTextCommand extends MacroCommand
  constructor: (@events) ->
    super()

  execute: ->
    for e in @events
      if e.key == 'U+20' or e.keyCode == 0x20
        # space(0x20)
        atom.workspace.getActiveTextEditor().insertText(' ')
      else if e.key == 'U+9' or e.keyCode == 0x09
        # tab(0x09)
        atom.workspace.getActiveTextEditor().insertText('\t')
      else
        if character = characterForKeyboardEvent(e, @dvorakQwertyWorkaroundEnabled)
          atom.workspace.getActiveTextEditor().insertText(character)

  toString: (tabs) ->
    result = ''
    for e in @events
      s = atom.keymaps.keystrokeForKeyboardEvent(e)
      result += tabs + 'atom.keymaps.simulateTextInput(\'' + s + '\')\n'
    result

  toSaveString: ->
    result = '*I\n'
    for e in @events
      character = characterForKeyboardEvent(e)
      switch e.keyCode
        when 0x20 # space
          character = ' '
        when 0x09 # tab
          character = '\t'
      s = ':' + character + '\n'
      #s = ':' + e.key + ',' + (e.keyCode if e.keyCode)  + ',' + (e.which if e.which) + '\n'
      result += s
    result

class DispatchCommand
  constructor: (@command_name) ->

  execute: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      view = atom.views.getView(editor)
      atom.commands.dispatch(view, @command_name)

  toString: (tabs) ->
    result = ''
    if !MacroCommand.viewInitialized
      result += tabs + 'editor = atom.workspace.getActiveTextEditor()\n'
      result += tabs + 'view = atom.views.getView(editor)\n'
      MacroCommand.viewInitialized = true
    result += tabs + 'atom.commands.dispatch(view, "' + @command_name + '")\n'
    result

  toSaveString: ->
    '*D\n:' + @command_name + '\n'

class KeydownCommand extends MacroCommand
  constructor: (@events) ->
    super()

  execute: ->
    for e in @events
      atom.keymaps.handleKeyboardEvent(e)

  toString: (tabs) ->
    result = ''
    if !MacroCommand.viewInitialized
      result += tabs + 'editor = atom.workspace.getActiveTextEditor()\n'
      result += tabs + 'view = atom.views.getView(editor)\n'
      MacroCommand.viewInitialized = true

    for e in @events
      result += tabs + "event = document.createEvent('KeyboardEvent')\n"
      result += tabs + "bubbles = true\n"
      result += tabs + "cancelable = true\n"
      result += tabs + "view = null\n"
      result += tabs + "alt = #{e.altKey}\n"
      result += tabs + "ctrl = #{e.ctrlKey}\n"
      result += tabs + "cmd = #{e.metaKey}\n"
      result += tabs + "shift = #{e.shiftKey}\n"
      result += tabs + "keyCode = #{e.keyCode}\n"
      result += tabs + "key = #{e.key}\n"
      result += tabs + "location ?= KeyboardEvent.DOM_KEY_LOCATION_STANDARD\n"
      result += tabs + "event.initKeyboardEvent('keydown', bubbles, cancelable, view,  key, location, ctrl, alt, shift, cmd)\n"
      result += tabs + "Object.defineProperty(event, 'keyCode', get: -> keyCode)\n"
      result += tabs + "Object.defineProperty(event, 'which', get: -> keyCode)\n"
      result += tabs + "atom.keymaps.handleKeyboardEvent(event)\n"
    result

  toSaveString: ->
    result = '*K\n'
    for e in @events
      result += ':' + keystrokeForKeyboardEvent(e) + '\n'
    result


# Plugin
class PluginCommand extends MacroCommand
  constructor: (@plugin, @options) ->
    super options
    @options = options

  execute: ->
    @plugin.execute(@options)

  toString: (tabs) ->
    @plugin.toString(tabs)

  toSaveString: ->
    @plugin.toSaveString(@options)

  instansiateFromSavedString: (str) ->
    @plugin.instansiateFromSavedString(str)

###
# Plugin Interface
class PluginInterface
  execute: (@options) ->

  toString: (tabs) ->

  toSaveString: ->

  instansiateFromSavedString: (str) ->
###


module.exports =
    MacroCommand: MacroCommand
    InputTextCommand: InputTextCommand
    KeydownCommand: KeydownCommand
    DispatchCommand: DispatchCommand
    PluginCommand: PluginCommand

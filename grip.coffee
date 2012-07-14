if typeof appshell != 'undefined'
  shell = appshell
else
  shell =
    fs:
      showOpenDialog: (a, b, c, d, e, callback) ->
        callback(null, "main.g")

      readFile: (f, e, callback) ->
        callback(null, "example code here")

USE_ACE = false

GRIP_THEME =
  isDark: false
  cssText: "/* grip */"
  cssClass: "ace-grip"

if USE_ACE
  define 'ace/mode/example', (require, exports, module) ->
    oop = require "ace/lib/oop"
    { Mode: TextMode } = require "ace/mode/text"
    { Tokenizer } = require "ace/tokenizer"
    { ExampleHighlightRules } = require "ace/mode/example_highlight_rules"

    t3 = new ExampleHighlightRules().getRules()

    Mode = ->
        @$tokenizer = new Tokenizer(new ExampleHighlightRules().getRules())
        ``
    
    oop.inherits Mode, TextMode

    ((proto)->
      # Extra logic goes here. (see below)
      #
    ).call(Mode.prototype)

    exports.Mode = Mode
    ``
    
  define 'ace/mode/example_highlight_rules', (require, exports, module) ->
    oop = require "ace/lib/oop"
    { TextHighlightRules } = require "ace/mode/text_highlight_rules"

    ExampleHighlightRules = ->
        @$rules = new TextHighlightRules().getRules()
        ``

    oop.inherits ExampleHighlightRules, TextHighlightRules
    exports.ExampleHighlightRules = ExampleHighlightRules
    ``
else
  CodeMirror.defineMode "grip", (config, parserConfig) ->
    styles = [
      "keyword"
      "identifier"
      "string"
      "comment"
    ]

    return {
      startState: ->
        line: 1
        col: 1
        linePos: 0
        lineEndsAt: -1
        
      token: (stream, state) ->
        if stream.sol()
          stream.skipToEnd()
          state.lineEndsAt = stream.column()
          state.lineText = stream.current()
          state.lineTokens = state.lineText.split " "
          stream.backUp(state.lineText.length - state.lineTokens[0].length - 1)
          state.tok = 1
        else
          for i in [0 .. state.lineTokens[state.tok].length]
            stream.next()

          state.tok += 1

        return styles[state.tok - 1]

      indent: (state, textAfter) ->
        console.log "indenting"
        return 0
    }

    #bla bla
    #
  CodeMirror.defineMIME "x-grip", "grip"

$ ->
  code = "function myScript(){return 100;}\n"

  Mousetrap.bind 'f5', -> window.location.reload true

  if USE_ACE
    ed = ace.edit "editor"
   
    ed.setTheme GRIP_THEME
    ed.session.setMode "ace/mode/example"
    ed.setValue code

  else
    ed = CodeMirror ((cm) -> $("#editor").replaceWith(cm); cm.setAttribute("id", "editor")),
      value: code
      mode:  "grip"
      lineNumbers: true
      lineWrapping: true
      extraKeys:
        F5: -> window.location.reload true
    
    gutter = ed.getGutterElement()
    $tabbar = $("#tabbar ul")
      
  layout = $('#mainarea').layout
    applyDefaultStyles: false
    enableCursorHotkey: false
    spacing_open: 7
    spacing_closed: 7
    livePaneResizing: true
    triggerEventsDuringLiveResize: true
    onresize: (name, el, state, option, layoutName) ->
      ed.refresh()

      $tabbar.position
        my: "left"
        at: "right"
        of: gutter
        offset: "6"
        using: (pos) -> $tabbar.css left: pos.left

  ed.refresh()

  fs = shell.fs
  
  Commands =
    'New Project': ->
      fs.showOpenDialog false, false, "Open File", "D:", ["js"], (err, paths) ->
        unless err
          return if paths.length <= 0
          fs.readFile paths[0], "utf8", (err, contents) ->
            unless err
              ed.setValue contents
            else
              console.log "error reading file"
        else
          console.log "error: showOpenDialog"

    'About': ->
      console.log "Display about message"

    'Exit': ->
      appshell.app.quit()

    'Debug': ->
      console.log "Display about message"
 
  menu = $("#menu").superfish().delegate 'li.cmd', 'mousedown', (e) ->
    cmd = e.target.innerText
    Commands[cmd]?()
  
  projectTree = $("#projectTree").jstree
    json_data:
        data: [
            {
                data: "styles"
                metadata: { id : 23 }
                children: [ "grip.css", "jstree.grip.css" ]
            },
            {
                attr: { "id" : "li.node.id1" }
                data:
                    title: "Project.g",
                    attr: { "href" : "#" }
            }
        ]
    plugins: ["json_data", "themes", "dnd", "ui", "crrm"]
    themes:
      theme: "grip"
      url: "jstree.grip.css"
      dots:  true
      icons: true
  

_ = require 'underscore-plus'
{$$, View} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
ButtonsView = require './buttons-view'
PathView = require './path-view'
escapeHTML = require 'underscore.string/escapeHTML'
AnsiToHtml = require 'ansi-to-html'
fsp = require 'fs-plus'

module.exports =
class ProcessOutputView extends View

  constructor: (@main, @processController) ->
    super(@main, @processController);
    @lastScrollTop = 0;
    @scrollLocked = false;
    @ansiConvert = new AnsiToHtml({stream:true});
    @lineIndex = 0;
    @patterns = @processController.configController.patterns;

    @addProcessDetails();
    @setScrollLockEnabled(@processController.config.scrollLockEnabled);

  @content: (main, processController) ->
    @div =>
      @div {class:"process-palette-process", style:'margin-bottom:5px', outlet:"header"}, =>
        @button {class:'btn btn-xs icon-three-bars inline-block-tight', outlet:'showListViewButton', click:'showListView'}
        @button {class:'btn btn-xs icon-playback-play inline-block-tight', outlet:'runButton', click:'runButtonPressed'}
        @span {class:'header inline-block text-highlight', outlet: 'commandName'}
        @span {class:'keystroke inline-block highlight', outlet:'keystroke'}
        @span {class:'btn-group'}, =>
          @button {class:'btn btn-xs icon-trashcan', style:'margin-left:15px', outlet:'clearButton', click:'clearOutput'}
          @button {class:'btn btn-xs icon-lock', style:'margin-right:15px', outlet:'scrollLockButton', click:'toggleScrollLock'}
        @subview "buttonsView", new ButtonsView(main, processController.configController, processController);
      @div {class:"process-palette-output-panel native-key-bindings", tabindex: -1, outlet:'outputPanel'}

  initialize: ->
    @disposables = new CompositeDisposable();

    fontFamily = atom.config.get("editor.fontFamily");
    @outputPanel.css("font-family", fontFamily);

    @addEventHandlers();
    @addToolTips();
    @refreshScrollLockButton();
    @processController.addProcessCallback(@);
    @outputChanged();

  addProcessDetails: =>
    @commandName.text(_.humanizeEventName(@processController.config.getCommandName()));

    if @processController.config.keystroke
      @keystroke.text(_.humanizeKeystroke(@processController.config.keystroke));
      @keystroke.show();
    else
      @keystroke.text("");
      @keystroke.hide();

  addEventHandlers: ->
    # Prevent the buttons from getting focus.
    @showListViewButton.on 'mousedown', (e) ->
      e.preventDefault();

    @runButton.on 'mousedown', (e) ->
      e.preventDefault();

    @scrollLockButton.on 'mousedown', (e) ->
      e.preventDefault();

    @clearButton.on 'mousedown', (e) ->
      e.preventDefault();

    @outputPanel.on 'mousedown', (e) =>
      # Only do this while the process is running.
      if @processController.process != null
        @setScrollLockEnabled(true);

    @outputPanel.on 'scroll', (e) =>
      @lastScrollTop = @outputPanel.scrollTop();
      @disableScrollLockIfAtBottom();

  addToolTips: ->
    @disposables.add(atom.tooltips.add(@showListViewButton, {title: 'Show palette'}));
    @disposables.add(atom.tooltips.add(@scrollLockButton, {title: 'Scroll lock'}));
    @disposables.add(atom.tooltips.add(@clearButton, {title: 'Clear output'}));
    @disposables.add(atom.tooltips.add(@runButton, {title: 'Run process'}));

  disableScrollLockIfAtBottom: ->
    if @processController.process == null
      return;

    if ((@outputPanel.height() + @outputPanel.scrollTop()) == @outputPanel.get(0).scrollHeight)
      # Only do this while the process is running.
      if (@outputPanel.scrollTop() > 0)
        @setScrollLockEnabled(false);
    else
      @setScrollLockEnabled(true);

  parentHeightChanged: (parentHeight) ->
    @calculateHeight();

  attached: ->
    @outputChanged();

  show: ->
    super();
    @outputChanged();

  calculateHeight: =>
    @outputPanel.height(@main.mainView.height() - @header.height() - 5);

  processStarted: =>

  processStopped: =>

  setScrollLockEnabled: (enabled) ->
    if @scrollLocked == enabled
      return;

    @scrollLocked = enabled;
    @refreshScrollLockButton();

  showListView: ->
    @main.showListView();

  runButtonPressed: ->
    @processController.configController.runProcess();

  toggleScrollLock: ->
    @setScrollLockEnabled(!@scrollLocked);

  refreshScrollLockButton: ->
    @scrollLockButton.removeClass("btn-warning");

    if @scrollLocked
      @scrollLockButton.addClass("btn-warning");

  streamOutput: (output) =>
    @outputChanged();

  clearOutput: ->
    @lastScrollTop = 0;
    @outputPanel.text("");
    @outputChanged();

  outputChanged: ->
    @calculateHeight();

    if @scrollLocked
      @outputPanel.scrollTop(@lastScrollTop);
    else
      @outputPanel.scrollTop(@outputPanel.get(0).scrollHeight);

    @refreshScrollLockButton();

  outputToPanel: (text) ->
    addNewLine = false;

    for line in text.split('\n')
      if addNewLine
        @outputPanel.append("<br>");
        @lineIndex++;
      @appendLine(line);
      addNewLine = true;

  # append line to output panel
  #   uses three kinds of patterns:
  #     - WLN = whole-line expressions
  #     - PLN = part-of-line expressions
  #     - PTH = path expressions
  #   - PTHs are roughly the same as PLNs
  #   - PTHs are converted to PathViews if a corresponding file exists
  #   - other PLNs are converted to span objects
  #   - converting is done sequentially: match(line) while(remaining) match(remaining)
  #   - resulting objects are collected together with strings between them (line_exprs)
  #   - while converting, the matching parts are replaced by place-holders (<PATH> and <pattern-name>) in the originally line
  #   - this way the place-holder can be matched afterwards
  #   - WLNs can be detected by using `^` at the start
  #   - WLNs is matched against the line with the place-holders
  #   - the first matching WLN outputs a span object of the collected array and stops matching
  appendLine: (line) ->

    #console.log("<< " + line)

    #@outputPanel.append @sanitizeOutput(line) + "<br>"

    ##### process path patterns
    line_exprs = []
    remaining = line
    any_match = true
    while remaining.length > 0 and any_match
      any_match = false
      for pattern in @patterns
        #console.log(["pattern", pattern.config.name, pattern.config.isLineExpression, pattern.config.isPathExpression, pattern])
        if pattern.config.isPathExpression
          match = pattern.match(remaining)
          if match?
            #console.log(["path match", match.match, remaining])
            if fsp.isFileSync(match.path)
              any_match = true
              #console.log(["path exist", match.match, remaining])
              cwd = @processController.getCwd()
              line_exprs.push match.pre
              obj = new PathView(cwd, match)
              obj.name = "path"
              line_exprs.push obj
              remaining = match.post
              break # process remaining
            remaining = match.post
            line_exprs.push match.pre + match.match
    if remaining.length >= 0
      line_exprs.push remaining

    ##### process inline patterns patterns
    parts = line_exprs
    line_exprs = []
    for part in parts
      if typeof part == "string"
        remaining = part
        any_match = true
        while remaining.length > 0 and any_match
          any_match = false
          for pattern in @patterns
            #console.log(["pattern", pattern.config.name, remaining])
            if pattern.config.isInlineExpression
              match = pattern.match(remaining)
              if match?
                any_match = true
                #console.log(["expr match", match, remaining])
                line_exprs.push match.pre
                obj = $$ -> @span {class: pattern.config.name}, => @raw(match.match)
                obj.name = pattern.config.name
                line_exprs.push obj
                remaining = match.post
                break # process remaining
        if any_match
          continue # next part
        if remaining.length >= 0
          line_exprs.push remaining
      else
        line_exprs.push part

    if line_exprs.length == 0
      line_exprs = [line]

    #console.log(["line_exprs", line_exprs])
    #console.log(">> " + line_processed)

    ##### replace all objects in line for whole-line matching
    line_processed = ""
    for part in line_exprs
      if typeof part == "string"
        line_processed += part
      else
        line_processed += "<" + part.name + ">"
    #console.log("== " + line_processed)

    ##### whole-line matching
    for pattern in @patterns
      if pattern.config.isLineExpression
        match = line_processed.match(pattern.regex)
        if match?
          #console.log(["line match", match.match, line_processed])
          line_span = $$ -> @span {class: pattern.config.name}
          for part in line_exprs
            if typeof part == "string"
              line_span.append $$ -> @text(part)
            else
              line_span.append part
          @outputPanel.append(line_span)
          return

    for part in line_exprs
      if typeof part == "string"
        part = @sanitizeOutput(part)
      @outputPanel.append(part)

  # Tear down any state and detach
  destroy: ->
    if @processController
      @processController.removeProcessCallback(@);

    @buttonsView.destroy();
    @disposables.dispose();
    @element.remove();

  getElement: ->
    return @element;

  sanitizeOutput: (output) ->
    # Prevent HTML in output from being parsed as HTML
    output = escapeHTML(output);
    # Convert ANSI escape sequences (ex. colors) to HTML
    output = @ansiConvert.toHtml(output);

    return output;

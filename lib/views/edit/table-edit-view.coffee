{$, View} = require 'atom-space-pen-views'
TableRowView = require './table-row-view'

module.exports =
class TableEditView extends View

  constructor: (@columns) ->
    super(@columns);
    @rowViews = [];

  @content: (columns) ->
    colWidth = 100 / columns.length;

    @div {class: 'process-palette-table-edit-view'}, =>
      @div {class: 'table-view'}, =>
        @table =>
          @colgroup =>
            @col {style:"width:0%"}
            for column in columns
              @col {style:"width:#{colWidth}%"}
          @thead =>
            @tr click: 'clickHeader', =>
              @th ' '
              for column in columns
                @th column, {class: 'text-highlight'}
          @tbody {outlet: 'tableBody'}
      @div {class: 'button-view'}, =>
        @button 'Add', {class: "btn btn-sm", outlet: 'addButton', click: 'addEmptyRow'}

  initialize: ->
    @addButton.on 'mousedown', (e) -> e.preventDefault();

  reset: ->
    while @rowViews.length > 0
      @removeRowView(@rowViews[0]);

  addRow: (row) ->
    rowView = @addEmptyRow();
    rowView.setValues(row);

  addEmptyRow: ->
    rowView = new TableRowView();
    rowView.initialize(@, @getColumnCount());
    @tableBody[0].appendChild(rowView);
    @rowViews.push(rowView);
    return rowView;

  removeRowView: (rowView) ->
    @rowViews.splice(@rowViews.indexOf(rowView), 1);
    @tableBody[0].removeChild(rowView);

  getRows: ->
    rows = [];
    for rowView in @rowViews
      rows.push(rowView.getValues());
    return rows;

  setRows: (rows) ->
    for rowView in @rowViews
      rowView.setValues(rows.shift());

  getColumnCount: ->
    return @columns.length;

  updateView: ->
    tableView = $(@).find(".table-view")
    if tableView.find(":checked").length
      tableView.addClass "items-selected"
    else
      tableView.removeClass "items-selected"

  clickHeader: -> @move(null)

  startDragging: (e) ->
    console.log ["startDragging", e]
    dragArea = $(@)
    dragArea.addClass 'process-palette-dragging'
    #@subs.add dragArea, '[contenteditable]',         => @stopEditing()
    #$(@).mouseup (e) => @stopDragging e
    dragArea.mouseup (e) => @stopDragging e
    #$(@).mousemove (e) => @whileDragging e
    dragArea.mousemove (e) => @whileDragging e
    #@subs.add @,     'mousedown', '.new-btn', (e) => @newBtnMouseDown e
    #@subs.add @,     'mousedown', '.btn',     (e) => @btnMousedown    e
    #@subs.add @,     'keydown',   '.btn',     (e) => @btnKeyDown      e
    #@subs.add @,     'click',     '.btn',     (e) => @btnClick        e

  stopDragging: (e) ->
    console.log ["stopDragging", e]
    dragArea = $(@)
    dragArea.removeClass 'process-palette-dragging'
    #$(@).off "mouseup"
    dragArea.off "mouseup"
    #$(@).off "mousemove"
    dragArea.off "mousemove"
    target = $(e.target).parentsUntil("tr").parent()
    console.log ["drop on", target, target[0]]
    #console.log target[0].editors[0].getModel().getText()
    #@tableView.move(target[0])

  whileDragging: (e) ->
    #console.log ["whileDragging", e]
    #e.stopPropagation()

  move: (insertionPoint) ->
    rows = []
    putaside = []

    # find insertionPoint or set it at top (= already passed)
    insertionPointPassed = not insertionPoint

    for rowView in @rowViews
      selected = rowView.selected
      if selected
        rowView.select(false)

      if rowView == insertionPoint              # at insertion point
        insertionPointPassed = true
        for row in putaside                     #     add remembered rows
          rows.push(putaside.shift())

      if not insertionPointPassed               # up to insertion point
        if selected
          putaside.push(rowView.getValues())    #     remember selected rows
        else
          rows.push(rowView.getValues())        #     add other rows

      else                                      # after insertion point
        if selected
          rows.push(rowView.getValues())        #     add selected rows
        else
          putaside.push(rowView.getValues())    #     remember normal rows
                                                # after all
    for row in putaside                         #     add remembered rows
      rows.push(putaside.shift())
    @setRows rows                               #     save rows to table

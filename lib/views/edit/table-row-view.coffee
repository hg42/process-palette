{$, $$, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class TableRowView extends HTMLElement

  initialize: (@tableView, @columnCount) ->

    checkElement = document.createElement("td");
    jcheck = $(checkElement);
    checkButton = $$ ->
      @input {type: 'checkbox', class: "select", checked: true}
    checkButton.click (e) => @check(e);
    #checkButton.on 'mousedown', (e) -> e.preventDefault();
    #checkButton.on 'mouseup', (e) -> e.preventDefault();
    jcheck.append(checkButton);
    @appendChild(checkElement);

    @editors = [];

    for column in [0...@columnCount]
      td = document.createElement("td");
      editor = new TextEditorView(mini: true);
      jtd = $(td);
      jtd.append(editor);
      @appendChild(td);
      @editors.push(editor);

    deleteElement = document.createElement("td");
    jdelete = $(deleteElement);
    deleteButton = $$ ->
      @button {class: "btn btn-sm icon icon-x delete"}
    deleteButton.click => @delete();
    deleteButton.on 'mousedown', (e) -> e.preventDefault();
    jdelete.append(deleteButton);
    @appendChild(deleteElement);

    $(@).on 'click', (e) => @tableView.move(@) if @ == e.currentTarget

  check: (e) ->
    @select_($(@).find(":checked").length > 0)
    e.stopPropagation()

  select: (value) ->
    checkbox = $(@).find(".select")
    console.log ["select", checkbox]
    setTimeout(
      (->
        console.log ["setTimeout", checkbox]
        checkbox.prop("checked", value)
        ),
      3000
      )
    @select_(value)

  select_: (value) ->
    if value
      @selected = true
      $(@).addClass "selected"
    else
      @selected = false
      $(@).removeClass "selected"
    @tableView.updateView()

  delete: ->
    @tableView.removeRowView(@);

  setValues: (values) ->
    for i in [0 ... values.length]
      value = values[i];

      if !value?
        value = '';

      @editors[i].getModel().setText(value);

  getValues: ->
    values = [];

    for editor in @editors
      values.push(editor.getModel().getText());

    return values;

module.exports = document.registerElement("table-row-view", prototype: TableRowView.prototype, extends: "tr")

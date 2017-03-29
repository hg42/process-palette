{$, $$, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class TableRowView extends HTMLElement

  initialize: (@tableView, @columnCount) ->

    selectElement = document.createElement("td");
    jselect = $(selectElement);
    @selectButton = $$ ->
      @input {type: 'checkbox', class: "select input-checkbox"}
    @selectButton.click (e) => @clickSelect(e);
    #@selectButton.on 'mousedown', (e) -> e.preventDefault();
    #@selectButton.on 'mouseup', (e) -> e.preventDefault();
    jselect.append(@selectButton);
    @appendChild(selectElement);

    @editors = [];

    for column in [0...@columnCount]
      td = document.createElement("td");
      editor = new TextEditorView(mini: true);
      #editor = $$ ->
      #  @textarea {class: "input-textarea", rows: 1}
      jtd = $(td);
      jtd.append(editor);
      @appendChild(td);
      @editors.push(editor);

    deleteElement = document.createElement("td");
    jdelete = $(deleteElement);
    deleteButton = $$ ->
      @button {class: "btn btn-sm btn-warning inline-block-tight icon icon-x delete"}
    deleteButton.click => @delete();
    deleteButton.on 'mousedown', (e) -> e.preventDefault();
    jdelete.append(deleteButton);
    @appendChild(deleteElement);

    #$(@).on 'click', (e) => @tableView.move(@) if @ == e.currentTarget
    $(@).click (e) => @tableView.move(@) if @ == e.currentTarget
    #$(@).on 'mousedown', (e) -> e.preventDefault();
    #$(@).on 'mouseup', (e) -> e.preventDefault();

  clickSelect: (e) ->
    @select_($(@).find(":checked").length > 0)
    e.stopPropagation()

  select: (value) ->
    #@selectButton.prop("checked", value)
    @selectButton.val(value)
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
      value = values[i]
      if !value?
        value = ''
      #$(@editors[i]).val(value)
      @editors[i].getModel().setText(value);

  getValues: ->
    values = [];
    for editor in @editors
      #values.push($(editor).val())
      values.push(editor.getModel().getText());
    return values;

module.exports = document.registerElement("table-row-view", prototype: TableRowView.prototype, extends: "tr")

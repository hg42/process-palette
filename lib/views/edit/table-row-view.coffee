{$, $$, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class TableRowView extends HTMLElement

  initialize: (@tableView, @columnCount) ->

    selectElement = document.createElement("td");
    jselect = $(selectElement);
    @selectButton = $$ ->
      @input {type: 'checkbox', class: "select input-checkbox"}
    @selectButton.click (e) => @clickSelect(e);
    jselect.append(@selectButton);
    @appendChild(selectElement);

    @editors = [];

    for column in [0...@columnCount]
      td = document.createElement("td");
      editor = new TextEditorView();
      editor.addClass('multi-line-editor');
      editor.getModel().setSoftTabs(true);
      editor.getModel().setSoftWrapped(true);
      editor.getModel().setLineNumberGutterVisible(false);
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

    $(@).click (e) =>
      jtarget = $(e.target)
      if jtarget.is("tr") or jtarget.is("td")
        @tableView.move(@)
        e.stopPropagation()

  setChecked: (checkbox, checked) ->
    if checkbox?
      if !checked?
        checked = false
      if checked != checkbox.is(":checked")
        checkbox.trigger("click");

  clickSelect: (e) ->
    @select_($(@).find(":checked").length > 0)
    e.stopPropagation()

  select: (value) ->
    @setChecked @selectButton, value
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
      @editors[i].getModel().setText(value);

  getValues: ->
    values = [];
    for editor in @editors
      values.push(editor.getModel().getText());
    return values;

module.exports = document.registerElement("table-row-view", prototype: TableRowView.prototype, extends: "tr")

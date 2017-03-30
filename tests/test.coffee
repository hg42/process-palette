
console.log "---------- hello"

if 1
  {$, $$} = require 'atom-space-pen-views'

  console.log $.fn.jquery

if 0

  re = ""
  re += "(?:\n\\bfile:?\\s+|\n\\bsource:?\\s+|\n\\bat:?\\s+\n)?"
  re += "['\"]?([-\\w/+.]+)['\"]?\n"
  re += "\\s*[(](\\d+)[)]"
  re = re.replace(/\n/g, "")

  console.log re

  re = new RegExp(re)

  text = "xxx ../output-tests/test-multiple-paths.txt (4) yyy"

  matches = re.exec(text)

  console.log matches

echo "  -- blafusel ./test-multiple-paths.zsh:3 hurzmiburz /not/a/real/file-txt ../tests/test-multiple-paths.zsh:4 SomeErrorHorror foo test-multiple-paths.zsh:5 Test-Error bar"
echo "  -- blafusel more-errors ./test-multiple-paths.zsh:3 hurzmiburz Another_Error ../tests/test-multiple-paths.zsh:4 foo test-multiple-paths.zsh:5 bar"

# this does not work yet
echo "  -- blafusel \"./test-multiple-paths.txt\" hurzmiburz '/not/a/real/file.txt' \"../output-tests/test-multiple-paths.txt\" SomeErrorHorror foo 'test-multiple-paths.txt' Test-Error bar"

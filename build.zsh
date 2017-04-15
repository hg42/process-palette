
#echo $*
#set

if ${build_file:-false}; then
  if [[ $1 == *.txt ]]; then
    chdir $cwd
    while read line; do
      if [[ $line == EXPECT: ]]; then break; fi
      if [[ $line == \#* ]]; then break; fi
      echo $line
    done < $1
    exit
  fi
  if [[ $1 == *.coffee ]]; then
    chdir $cwd
    run_coffee $*
    exit
  fi
  echo cannot build file $1
  exit
fi

#zsh ./tests/test-multi-inline-patterns.zsh
apm test

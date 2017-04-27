
#echo $*
#set
#echo dir=$dir
#echo cwd=$cwd
#echo pwd=$(pwd)

if ${build_file:-false}; then
  file=$1
  if [[ $(basename $file) == test-*.txt ]]; then
    chdir $cwd
    while read line; do
      if [[ $line == EXPECT: ]]; then break; fi
      if [[ $line == \#* ]]; then break; fi
      echo $line
    done < $file
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
#apm test
if [[ $cwd == */spec/* ]]; then
  atom --test $cwd
else
  atom --test spec
fi

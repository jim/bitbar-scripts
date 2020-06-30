#!/usr/local/bin/fish 

set dir (dirname (status -f))
cd $dir/..
eval (direnv export fish ^ /dev/null)
bitbar/build/clocks
#!/usr/local/bin/fish 

source (dirname (status -f))/../bootstrap_ruby.fish
eval (direnv export fish ^ /dev/null)
direnv exec (which ruby) ruby/calendar_menu.rb
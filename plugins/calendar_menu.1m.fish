#!/usr/local/bin/fish 

source (dirname (status -f))/../bootstrap_ruby.fish
direnv hook fish | source
direnv exec (which ruby) ruby/calendar_menu.rb
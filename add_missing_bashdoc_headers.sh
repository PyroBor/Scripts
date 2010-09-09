#!/bin/sh
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## sed script that adds headers to functions for bashdoc
##
#---
dash_line="#---"
sed -i "
:z 
/^[:space:]*$/  {
	# append next line
	n

	/^$/ { bz }
	#if is blank forget about it :)
	/main *()/ { bz }
	/usage *()/ { bz }
	/help *()/ { bz }
	/strip_parameters *()/ { bz }
	/process_parameters *()/ { bz }
   # also the functions that can be more files (main, help, process_parameters,
   # strip_parameters, usage). There are problems if there is more then one
   # function with same name. 

	# lets search for functions
    /\w*()/ {

       #we have function in front
      /^function/ {
        s/\(function\) \(\w*\) *()/$dash_line\n##\n$dash_line\n\1 \2()/
        }
        #we don't... we add it. 
      /^function/! {
        s/^\([a-z_^=]*\) *()/$dash_line\n##\n$dash_line\nfunction \1()/
      }

	}	
}

# we should also have function name_function()
# so lets change that even if we have header
/\w*()/ {
     #we don't... we add it. (doesn't matter if header is ok.)
     /^function \w*()/! {
          s/^\([a-z_^=]*\) *()/function \1()/
#           p
      }
}
" $1

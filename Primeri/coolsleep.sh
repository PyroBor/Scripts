#!/bin/bash
function coolsleep
{
local time_to_sleep=$1
until [[ $time_to_sleep == "0" ]]; do
	echo -n "$time_to_sleep "
	sleep 1
	let time_to_sleep--
done
echo
}

coolsleep 20
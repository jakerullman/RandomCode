function wifi(){
	_interface=`networksetup -listallhardwareports | grep -E '(Wi-Fi|AirPort)' -A 1 | grep -o "en."`
	_opt=$1
	if test "x${_opt}" = "x" ; then
		echo "$FUNCNAME (on|off)"
		return 1
	elif test "${_opt}" = "on" -o "${_opt}" = "off" ; then
		for in in $_interface ; do
			networksetup -setairportpower $in $_opt
		done
	fi
}
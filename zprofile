# zpforile

for i in /etc/profile.d/*.sh ; do
		if [ "$i" != "/etc/profile.d/bash_completion.sh" ]; then
    	[ -r $i ] && source $i
		fi
done


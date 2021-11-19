#
# run make to compile and link to ~/bin

compile:
	echo "Compiling inc.sh"
	shc -f inc.sh -o inc
	echo "Create/Update ~/bin/inc link"
	ln -sf ${PWD}/inc ~/bin/inc
	ln -sf ${PWD}/bash_completion.d/inc /opt/homebrew/etc/bash_completion.d/
pre:
	echo "Installing prerequisites"
	if [[ "$(uname)" -eq "Darwin" ]];then
		brew install shc
	elif [[ "$(uname)" -eq *"Ubuntu"* ]];then
		apt install shc
	else
		yum -y install shc
	fi

# all:
# 	pre
# 	compile

clean:
	echo "Removing compiled inc"
	rm inc
	rm ~/bin/inc
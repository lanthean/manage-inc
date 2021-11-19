#!/usr/local/bin/bash
###
# @Author	Martin Bortel
# @Web		http://martinbortel.cz
# @Email	me@martinbortel.cz
# @Created	04/07/2013
# 
# @Package	~/bin
#
###
VERSION='2.0.0'
COPYRIGHT='lanthean@protonmail.com, https://github.com/lanthean'

## Static functions
function f_s_init () {
  # def vars
	user="$(/usr/bin/whoami)"
	handle='incident (plaintext/markdown/filetree) management'
	script_name='manage-inc.sh'
	EXP_ARGS=1
	year="$(date +"%Y")"
	def_path=~/inc
	path=$def_path/main
	user_downloads=/Users/lanthean/Downloads
	##
	# in case decision is made to distribute incident/h2s/jira issues to separate directories ./incidents; ./h2s; ./jira
	# (at this moment manually created soft links are in place)
	inc_path=$def_path/inc
	h2s_path=$def_path/h2s
	jira_path=$def_path/jira
	done_path=$def_path/done
	##
	backtoops=$def_path/back2ops
	path24x7=$def_path/24x7/$year
	team=$path/team
	delim="__"
	id_def="xxxxxx000000xxxxxx"
	INC_MATCH="(INC[0-9]{8})|(CS[0-9]{8})"
	id=$id_def
	# Function variables declaration
	# f_get_remove
	id_ch=1; team_ch=1; cust_ch=1; sfid_ch=1; desc_ch=1; prio_ch=1;
	
	## disable logging [true|false]
	#LOG_DISABLED=true
	## 

	LOG_FILE=$def_path/log/incidents.log
	LOG_LEVEL=d
  if [ ! -d /opt/generic_bash_functions ];then
    echo "/opt/generic_bash_functions not found, attemting to clone from lanthean's github"
	  pushd /opt
    sudo git clone https://github.com/lanthean/generic_bash_functions.git
    popd
    sudo chown -R $USER:staff /opt/generic_bash_functions
  fi
	source /opt/generic_bash_functions/generic_bash_functions
	} 
function f_s_boc () { 
	#start with something nice to say
	#echo "### Welcome $user
	# I will handle $handle for You now.."
	echo "###"
	#echo "#"
	} 
function f_s_eoc () { 
	#say good bye
	#echo "# It was my pleasure to serve You Ser.
	### Good bye "
	#echo "#"
	log t "eof"
	echo "###"
	} 

## getters/setters
function f_manage_users () { 
	if [ $user == "martin" ]; then
		return
	elif [ $user == "root" ]; then
		user="martin"
		#path="/data/documents/acision/incidents"
		return
	else
		#LOG_FILE=/home/martin/documents/acision/incidents/log/incidents.log
		log w "User not martin nor root. "
		user="martin"
		return false
	fi
	} 
function f_get_user_consent() {
	if [[ -z $1 ]];then
		message="Do You want to continue?"
	else
		message=$1
	fi
	read -p "|	${message} [Y/n]: " yn
	if [[ $yn == "n" ]];then
		log w "User abort"
		f_s_eoc
		exit 0
	else
		return
	fi
	}
function f_get_inc_filter () { 
	if [ "$id" == "$id_def" ]; then
		# no ID entered in argument, fetch one interactively
		read -p "|	Please input the incident ID: " id
		# check if user wants to see INC in back2ops
		if [ $# -gt 0 ];then
			case $1 in
				"-b" | "--backtoops" )
					path=$backtoops
					;;
				"-d" | "--done" )
					path=$done_path
					;;
			esac
		fi	
	fi #ID entered as argument?
	if [ -z "$id" ];then
		# log should be handled by calling function -> No ID inserted
		grepped=0
		nlines=0
		log t "f_get_inc_filter: No $id available - I cannot continue."
		return
	else
		grepped=$(ls "$path" | grep "$id")
		nlines=$(ls "$path" | grep "$id" | wc -l)
		# log t "nlines: ${nlines#0}; grepped: ${grepped#0}"
	fi
	path=$def_path/main
	} 
function f_get_rename () { 
	read -p "|	What do you want to edit (empty: cancel|quit) [i=id|t=team|c=cust|s=sfid|d=desc|p=prio] ? " choice
	case $choice in
		[Ii] )
			read -p "|	Enter new ID: " id
			id_ch=0
			f_get_rename
			;;
		[Tt] )
			read -p "|	Enter new Team: " team
			team_ch=0
			f_get_rename
			;;
		[Cc] )
			read -p "|	Enter new Customer: " cust
			cust_ch=0
			f_get_rename
			;;
		[Dd] )
			read -p "|	Enter new Description: " $desc_raw
			desc="${desc_raw// /_}"
			desc_ch=0
			f_get_rename
			;;
		[Ss] )
			read -p "|	Enter new SF-ID: " sfid
			sfid_ch=0
			f_get_rename
			;;
		[Pp] )
			read -p "|	Enter new Priority: " prio
			prio_ch=0
			f_get_rename
			;;
		* )
			log w "Nothing to change."
			return
			;;
	esac
	#log "f_get_rename:""id=""$id"" desc=""$desc"" stat=""$stat"" prio=""$prio"
 } 
function f_get_log() { 
	if [ "$LOG_DISABLED" = true ]; then
		log w "I am sorry, but the log has been disabled and is not available."
		return
	else
		log i "Incident management log listing in progress"
		less $LOG_FILE
	fi
	} 
function f_get_support_cases() {
	# Incidents	
	log t "inc_file: ${inc_file}"
	log t "grep: ${grep}"
	if [ -f $inc_file ];then
		rm $inc_file
		touch $inc_file
	fi
	for dir in $(ls -t $path | egrep "(^[0-9]{6,})" | egrep -i "$grep");do 
		W="" S="" U="" STATUS="" PRIORITY=""
		if [[ $(ls "$path/$dir/" | grep "ticket" | wc -l) -ge 1 ]]; then
			# workaround=$(cat $path/$dir/ticket.* | grep --text "@Workaround" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused")
			# workaround=${workaround//[$'\r\n']}
			# solution=$(cat $path/$dir/ticket.* | grep --text "@Solution" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused|([0-9]{3,6})")
			# solution=${solution//[$'\r\n']}
			update=$(cat $path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})")
			update=${update//[$'\r\n']}
			status=$(cat $path/$dir/ticket.* | grep --text "@Status")
			status=${status//[$'\r\n']}
			priority=$(cat $path/$dir/ticket.* | grep --text "@Pri")
			priority=${priority//[$'\r\n']}
			# W="${workaround:14:10}[W]"
			# S="${solution:13:10}[S]"
			U="${update:10:10}[U]"
			STATUS="${status:10:14}"
			PRIORITY="${priority:8:3}"
			# log t "workaround: ${W}"
			# log t "solution: ${S}"
			# log t "update: ${update}; U: ${U}"
			# log t "status: ${status}"
			# log t "STATUS: ${STATUS}"
			# log t "priority: ${priority}"
			# log t "PRIORITY: ${PRIORITY}"
		fi
		if [ "$W" == "[W]" ];then
			W="n/a[W]"
		elif [[ $W == *"paused"* ]];then
			W="paused[W]"
		fi
		if [ "$S" == "[S]" ];then
			S="n/a[S]"
		elif [[ $S == *"paused"* ]];then
			S="paused[S]"
		fi
		if [ "$U" == "[U]" ];then		
			U="n/a[U]"
		fi

		##
		# Table display
		# printf "%-72s %-5s %-2s %-9s %13s %13s %13s\n" "$dir" "--?h" "$PRIORITY" "$STATUS" "$W" "$S" "$U"
		# log t "$dir $PRIORITY $STATUS $W $S $U"
		# printf "%-75s %-3s %-10s %13s %13s %13s\n" "$dir" "$PRIORITY" "$STATUS" "$W" "$S" "$U" >> $inc_file
		printf "%-85s |%-3s |%-11s |%13s\n" "$dir" "$PRIORITY" "$STATUS" "$U" >> $inc_file
	done 
	}
function f_get_development_cases() {
	# JIRA	
	if [ -f $jira_file ];then
		rm $jira_file
		touch $jira_file
	fi
	# search for "CUS-[0-9]{at least 3 occurences}"
	for dir in `ls -t $path | egrep "(CUS-[0-9]{3})" | egrep -i "$grep" | grep -v "H2S"`;do 
		P="" S="" U="" STATUS=""
		if [ -f $path/$dir/ticket.* ]; then
			progress=`cat $path/$dir/ticket.* | grep --text "@Progress" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused"`
			# workaround=`cat $path/$dir/ticket.* | grep --text "@Workaround" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused"`
			solution=`cat $path/$dir/ticket.* | grep --text "@Solution" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused|([0-9]{3,6})"`
			update=`cat $path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})"`
			status=`cat $path/$dir/ticket.* | grep --text "@Status"`
			P="${progress:13:10}[P]"
			# W="${workaround:14:10}[W]"
			S="${solution:13:10}[S]"
			U="${update:10:10}[U]"
			STATUS="${status:10:14}"

		fi
		# if [ "$W" == "[W]" ];then
		# 	W="n/a[W]"
		# elif [[ $W == *"paused"* ]];then
		# 	W="paused[W]"
		# fi
		if [ "$S" == "[S]" ];then
			S="n/a[S]"
		elif [[ $S == *"paused"* ]];then
			S="paused[S]"
		fi
		if [ "$U" == "[U]" ];then		
			U="n/a[U]"
		fi

		##
		# Table display
		printf "%-85s |%-15s |%13s |%13s\n" "$dir" "$STATUS" "$S" "$U" >> $jira_file
	done 
	}
function f_get_h2s_cases() {
	# H2S 
	if [ -f $h2s_file ];then
		rm $h2s_file
		touch $h2s_file
	fi
	for dir in `ls -t $path | egrep "(H2S)" | egrep -i "$grep"`;do 
		P="" S="" U="" STATUS=""
		if [ -f $path/$dir/ticket.* ]; then
			progress=`cat $path/$dir/ticket.* | grep --text "@Progress" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused"`
			# workaround=`cat $path/$dir/ticket.* | grep --text "@Workaround" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused"`
			# solution=`cat $path/$dir/ticket.* | grep --text "@Solution" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused|([0-9]{3,6})"`
			update=`cat $path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})"`
			status=`cat $path/$dir/ticket.* | grep --text "@Status"`
			P="${progress:13:10}[P]"
			# W="${workaround:14:10}[W]"
			# S="${solution:13:10}[S]"
			U="${update:10:10}[U]"
			STATUS="${status:10:14}"
		fi
		if [ "$P" == "[P]" ];then
			P="n/a[P]"
		elif [[ $P == *"paused"* ]];then
			P="paused[P]"
		fi
		# if [ "$W" == "[W]" ];then
		# 	W="n/a[W]"
		# elif [[ $W == *"paused"* ]];then
		# 	W="paused[W]"
		# fi
		# if [ "$S" == "[S]" ];then
		# 	S="n/a[S]"
		# elif [[ $S == *"paused"* ]];then
		# 	S="paused[S]"
		# fi
		if [ "$U" == "[U]" ];then		
			U="n/a[U]"
		fi

		##
		# Table display
		# printf "%-79s %-10s %13s %13s %13s\n" "$dir" "$STATUS" "$W" "$S" "$U" >>  $h2s_file
		printf "%-85s |%-15s |%13s |%13s\n" "$dir" "$STATUS" "$P" "$U" >>  $h2s_file
	done
	}

## Functions
function f_readinp () { 
	## Read user's input
		team="CUS" #read -p "|	Team (SMSC/CUST): " team
		read -p "|	Customer: " cust
	  read -p "|	SF-ID: " sfid
		read -p "|	Short description of the incident: " desc
		read -p "|	Priority of the incident: " prio
		read -p "|	Status of the incident: " stat
	  read -p "|	Release: " release
	  read -p "|	Systems: " systems
		read -p "|	Contact: " contact
	#id=H2S_CUS-1809
	#cust=korektel_iq
	#sfid=S16-25984
	#desc=MCO-SOP
	#prio=B
	#stat=NEW
	#release=
	#systems=
	#contact="Mohan Pasupathy"
	} 
function f_create_downloads_link() {
	id=$1
	if [[ $id == *"H2S"* ]];then
		downloads_path="${user_downloads}/h2s"
		id=${id:4}
	else
		downloads_path="${user_downloads}/inc"
	fi
	log t "downloads path: ${downloads_path}"
	if [[ -L $downloads_path/$id ]];then
		log w "Link to ~/Downloads/$id already exists."
	elif [[ -d $downloads_path/$id ]];then
    log w "There is a directory in place of the new link location - reversing"
    ln -s $downloads_path/$id $path/$physical_directory/
	else
		physical_directory=$(ls ${path} | grep ${id})
		log i "Creating link to ${downloads_path}/${id}."
		log t "ln -sn ${path}/${physical_directory} ${downloads_path}/${id}"
		ln -sn ${path}/${physical_directory} ${downloads_path}/${id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link."
			log e "Link to ${downloads_path}/${id} was not created."
		fi
	fi
	}
function f_update_downloads_link_to_done() {
	id=$1
	if [[ $id == *"H2S"* ]];then
		downloads_path="${user_downloads}/h2s"
		id=${id:4}
	else
		downloads_path="${user_downloads}/inc"
	fi
	log t "downloads path: ${downloads_path}"
	if [[ -L $downloads_path/$id ]];then
		physical_directory=$(ls ${done_path} | grep ${id})
		log i "Updating link to ${downloads_path}/${id}."
		log t "ln -sfn ${done_path}/${physical_directory} ${downloads_path}/${id}"
		ln -sfn ${done_path}/${physical_directory} ${downloads_path}/${id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link."
			log e "Link to ${downloads_path}/${id} was not updated."
		fi
	elif [[ -d $downloads_path/$id ]];then
    log w "There is a directory in place of the new link location - reversing"
    ln -s $downloads_path/$id $done_path/$physical_directory/
	fi
	}
function f_remove_downloads_link() {
	id=$1
	if [ -L ~/Downloads/inc/${id} ];then
		log i "Removing link to ~/Downloads/inc/${id}."
		rm ~/Downloads/inc/${id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link."
			log e "Link to ~/Downloads/inc/${id} was not deleted."
		fi
	else
		log w "Link to ~/Downloads/inc/${id} does not exist."
	fi
	}	
function f_create_new_inc () { 
	# New incident
	# Let's create a new incident
	log i "Creating new incident"
	f_readinp
	#if [ $team == "" ]; then
	#	team="CUST"
	#else
	#	team="$delim""$team"
	#fi
	# newinc="$id""$delim""$team""$delim""$cust""$delim""$sfid""$delim""$desc""$delim""$prio"
	newinc="$id""$delim""$team""$delim""$cust""$delim""${desc// /_}"
	log i "Waiting for user confirmation of new incident: $newinc"
	read -p "|	Is it OK? [Y/n] " yn
	case $yn in
		[Nn]* )
			log i "User abort! Quitting.."
			return
			;;
		* )
			# echo "case f_create_new_inc"
			`mkdir $path/$newinc`
			log t "mkdir ${path}/${newinc}"
			
			DATE=`date +%Y\\\/%m\\\/%d` # fucking sed - escaped for sed parsing onwards
			UPDATE=${DATE}
			STATUS=${stat}
			PRI=${prio}
			ID=${id}
			SFID=${sfid}
			TOPIC=${desc}
			CUSTOMER=${cust}
			PRODUCT=
			SYSTEMS=${systems}
			RELEASE=${release}
			CONTACT=${contact}

			# echo "$path/$newinc/ticket" v "$DATE" "$UPDATE" "$PRI" "$ID" "$SFID" "$TOPIC" "$CUSTOMER" "$PRODUCT" "$SYSTEMS" "$RELEASE" "$CONTACT" "$STATUS"
			# read -p "Press any key to continue"
			$HOME/bin/newincf "$path/$newinc/ticket" v "$DATE" "$UPDATE" "$PRI" "$ID" "$SFID" "$TOPIC" "$CUSTOMER" "$PRODUCT" "$SYSTEMS" "$RELEASE" "$CONTACT" "$STATUS"

			# f_check_links
			if [ $? == 0 ]; then
				log i "Done: incident successfully created"
			else
				log e "Check previous err messages for details"
			fi

      # Create link to ~/Downloads
			f_create_downloads_link ${ID}

			;;
	esac
	} 
function f_parse_inc_name() {
  # Get main variables from inc path name
  # e.g. id; description
  # $1 = filename
  # return array
  filename=$1
	arr=( ${filename//$delim/ } )
  echo $arr
	}
function f_rename () { 
	## Rename Incident folder
	log t "id: $id"
	f_get_inc_filter
	if [ "$nlines" -gt 1 ]; then
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	elif [ "$nlines" -eq 0 ]; then
		log e "No ID inserted or similar"
		id=$id_def
		f_get_inc_filter
	else
	
		log i "Renaming incident $id"

		filename=$(ls $path | grep $id)
		arr=( ${filename//$delim/ } )
		log i "id	... ${arr[0]}"
		log i "team	... ${arr[1]}"
    log i "cust	... ${arr[2]}"
		log i "desc	... ${arr[3]}"
		log i "sf-id	... ${arr[4]}"
	#	log i "prio	... ${arr[5]}"
	
		f_get_rename 
		if [ $id_ch -eq 0 -o $team_ch -eq 0 -o $cust_ch -eq 0 -o $sfid_ch -eq 0 -o $desc_ch -eq 0 -o $prio_ch -eq 0 ]; then
			if [ $id_ch -eq 1 ]; then
				id=${arr[0]}
			fi
			if [ $team_ch -eq 1 ]; then
				team=${arr[1]}
			fi
			if [ $cust_ch -eq 1 ]; then
				cust=${arr[2]}
			fi
			if [ $desc_ch -eq 1 ]; then
				desc=${arr[3]}
			fi
			if [ $sfid_ch -eq 1 ]; then
				sfid=${arr[4]}
			fi
			#if [ $prio_ch -eq 1 ]; then
			#	prio=${arr[5]}
			#fi
			#newfilename="$id""$delim""$team""$delim""$cust""$delim""$sfid""$delim""$desc""$delim""$prio"
			newfilename="$id""$delim""$team""$delim""$cust""$delim""$desc"
	    log i $newfilename
			log i "Renaming in progress.."
			read -p "|  Is it OK? [Y/n] " yn
			case $yn in
				[Nn]* )
					log i "Nothing to do, quitting.."
					return
					;;  
				* ) 
					# Remove old link in ~/Downloads
					f_remove_downloads_link ${arr[0]}
					`mv $path/$filename $path/$newfilename`
					# Create new link in ~/Downloads
					f_create_downloads_link $id
					log i "Successfully renamed"
					log "cd $path/$newfilename"
					;;  
			esac
		else
			log w "No changes, quitting.."
		fi
	fi
	} 
function f_open() {
	if [[ -z $grepped ]] || [[ $grepped == 0 ]];then
		log e "I do not know what to open"
	else
		log t "Opening $path/$grepped/ticket.*"
		if [[ $(ls "$path/$grepped/" | grep "ticket" | wc -l) -ge 1 ]];then
			vim $path/$grepped/ticket.*
		else
			log e "There is no ticket.{ntx,txt,md} in ${path}/${grepped}"
		fi
	fi
	}
function f_remove () { 
	#	log "[e] Function not implemented yet! Quiting.."
	#	return
	log w "Remove action in progress"
	f_get_inc_filter
	if [ $nlines -eq 1 ]; then
		log w "Removing inc $grepped"
		log w "Waiting for user confirmation."
		read -p "|  Do you really want to delete this incident? [y/N/[t]rash] " yn
		case $yn in 
			[Yy]* )
				log w "User confirmed, deleting $grepped"
				log t "`pwd`"
				log t "rm -rf ./$grepped"
				rm -rf $grepped
				log w "Inc removed with success"
				;;
			[Tt]* )
				log w "Moving inc to trash"
				if [ -d $path/trash ];then
					mv $grepped $path/trash
				else
					log w "Trash folder does not exists, creating.. $path/trash"
					mkdir $path/trash
					mv $grepped $path/trash
				fi
				log w "Incident successfully moved to trash"
				;;
			* )
				log w "User abort, nothing to be removed"
				return
				;;
		esac
	else
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	fi
	} 
function f_backtoops() { 
	log i "BackToOPS action in progress"
	f_get_inc_filter
	if [ $nlines -eq 1 ]; then
		log i "Sending inc $grepped"
		log i "Waiting for user confirmation."
		read -p "|  Do you really want to move this incident to $backtoops folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log "mv $grepped $backtoops"
				mv $grepped $backtoops
				log i "Inc moved to $backtoops folder with success"
				;;
			* )
				log i "User abort, nothing to be removed"
				return
				;;
		esac
	else
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	fi
	f_remove_downloads_link $id
	} 
function f_done() { 
	log i "DONE action in progress"
	f_get_inc_filter
	if [ $nlines -eq 1 ]; then
		log i "Sending inc $grepped"
		log i "Waiting for user confirmation."
		read -p "|  Do you really want to move this incident to $done_path folder? [Y/n] " yn
		case $yn in 
			[Nn]* )
				log i "User abort, nothing to be removed"
				return
				;;
			* )
				log i "User confirmed, moving $grepped"
				log t "mv $grepped $done_path"
				mv $grepped $done_path
				log i "Inc moved to $done_path folder with success"
        log i "Update inc link in ${user_downloads}/inc"
        log t "grepped: ${grepped}"
        inc_arr=$(f_parse_inc_name $grepped)
        log t "id: ${inc_arr[0]}"
        f_update_downloads_link_to_done ${inc_arr[0]}
				;;
		esac
	else
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	fi
	} 
function f_return() { 
	log i "Return from BackToOPS action in progress"
	f_get_inc_filter -b
	if [ $nlines -eq 1 ]; then
		log i "Sending inc $grepped"
		log i "Waiting for user confirmation."
		read -p "|  Do you really want to move this incident to $path folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log t "mv $backtoops/$grepped $path"
				mv $backtoops/$grepped $path
				log i "Inc moved to $path folder with success"
				;;
			* )
				log i "User abort, nothing to be removed"
				return
				;;
		esac
	else
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	fi
	} 
function f_team() { 
	log i "Team reassignment action in progress"
	f_get_inc_filter
	if [ $nlines -eq 1 ]; then
		log i "Sending inc $grepped"
		log i "Waiting for user confirmation."
		read -p "|  Do you really want to move this incident to $team folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log t "mv $grepped $team"
				mv $grepped $team 
				log i "Inc moved to $team folder with success"
				;;
			* )
				log i "User abort, nothing to be removed"
				return
				;;
		esac
	else
		log e "multiple hits, please try with more detailed inc description"
		id=$id_def
		f_get_inc_filter
	fi
	} 

function f_args () { 
	log t "\$1=$1"
	case $1 in
		"-dl" | "downloadlink" ) #check soft link to ~/Downloads
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_create_downloads_link $id
			return
			;;
		"-l" | "links" ) #check soft links
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_check_links
			return
			;;
		"-r" | "rename" ) #remove an incident function
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_rename $@
			return
			;;
		"-M" | "remove" ) #remove an incident function
			f_remove $@
			return
			;;
		"-b" | "bto" | "backtoops" ) #incident reassigned back to OPS function
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_backtoops $@
			return
			;;
		"-d" | "done" ) #incident reassigned back to OPS function
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_done $@
			return
			;;
		"-u" | "rti" | "return" ) #incident reassigned back from OPS to me function
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_return $@
			return
			;;
		"-t" | "team" ) #incident reassigned within team function
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_team $@
			return
			;;
		"log" ) #list incident management log
			f_get_log $@
			return
			;;
		"pr" ) #pr listing function
			if [ "$2" eq "-b" ];then
				f_ls null -b -pr $2
			else
				f_ls null -pr $2
			fi
			return
			;;
		"l" | "lst" | "list" ) #listing function
			/usr/bin/clear
			echo $path
			f_s_boc
			f_ls $@
			return
			;;
		"li" | "lj" | "ld" | "lh" )
			/usr/bin/clear
			echo $path
			f_s_boc
			f_ls_prototype $@
			return
			;;
		"ls" | "lstate" ) #listing function
			/usr/bin/clear
			echo $path
			f_s_boc
			f_ls $@
			return
			;;
		"wc" | "lines" ) #lines count function
			f_wc $@
			return
			;;
		"--help" | "-h" | "-?" )
			log i "[h]  Script: "$script_name
			log i "[h]  Help: Listing of available extensions"
			f_args -lh
			log i "[h]  wc			... in default mode will show how many incidents are there in my queue"
			log i "[h]  wc -v		... show how many incidents are there while filtering the \$3 out of the result"
			log i "[h]  log			... show incident management log"
			log i "[h]  [-M] remove		... delete incident | [M]ove incident to trash"
			log i "[h]  [-t] team		... move incident to $team folder"
			log i "[h]  [-d] done		... move incident to $done_path folder"
			log i "[h]  [-b][bto] backtops	... move incident to $backtoops folder"
			log i "[h]  [-u][rti] return 	... move incident back from $backtoops"
			log i "[h]  [-r] rename		... rename incident"
			log i "[h]  [-n] new		... create new incident"
			log i "[h]  [-l] links		... check soft links"
			log i "[h]  If no argument, wizard is started, asking for an ID. Then handling of this partial incident or a new on is started. Have an incident number/ID ready."
			return
			;;
		"-lh"|"-hl" ) #listing help for ls function
			log i "[h]  [l]s			... in default mode will list all apropriate INC directories.
							[W]orkaround, [S]olution,[U]pdate dates from ./INC../ticket.{ntx,txt,md}"
			log i "[li]    			... list only incidents"
			log i "[lj]    			... list only development/assessment JIRA tasks"
			log i "[lh]    			... list only H2S JiRA tasks"
			log i "[h]  ls -f		... full path"
			log i "[h]  ls -v		... filter \$3 out of the result"
			log i "[h]  ls -I		... filter \$3 case sensitive"
			log i "[h]  ls -n		... ls -l incidents by name [crosscheck with ARS|Nikita]"	
			log i "[h]  ls -24		... ls -rl 24x7 and Emergency incidents from $year"	
			return
			;;
		"-v" | "--version" | "version" | "copyright")
			log i "Version: `echo $VERSION`"
			log i "(c) `echo $COPYRIGHT`"
			return
			;;
		$(awk '{a=0}/[0-9]{4,}/{a=1}a' <<<$1) | $(awk '{a=0}/C[A-Z][A-Z]-[0-9]{3,}/{a=1}a' <<<$1))
		# $1 = case reference (e.g. 380123) or JIRA reference (e.g. CUS-3050)
			log d "id passed awk test as $1"
			id=$1
			f_id_as_first_argument
			return
			;;
		"." )
			fl_ticket=$(ls . | grep ticket)
			log i "Opening $fl_ticket"
			vim ./$fl_ticket
			;;
		* )
			log e "Wrong argument \"$1\", quitting.. to see help use --help or -h"
			return
			;;
	esac
	} 

function f_ls () { 
	if [ $# -gt $EXP_ARGS ]; then
		case $2 in 
			"-f" )
				if [ "$#" -lt 3 ];then
					log i "full path"
					log t "`ls -dhlt -1 $path/** --color=auto | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})"`"
				else
					log i "full path with grep -i $3"
					log t "`ls -dhlt -1 $path/** --color=auto | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | grep -i $3`"
				fi
				;;
			"-v" )
				log i "grep -vi $3"
				log t "`ls -hlt $path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | grep -vi $3`"
				;;
			"-I" )
				log i "grep case sensitive $3"
				#log -c "`ls -hlt $path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | egrep "$3"`"
				f_ls_prototype $@
				echo
				;;
			"-n" )
				log i "crosscheck with ARS|Nikita"
				log t "`ls -hl $path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(H2S_CUS-[0-9]{4})"`"
				;;
			"-b" | "-bto" )
				log i "list back2ops issues"
				path=$backtoops
				f_ls_prototype $@
				path=$def_path/main
				;;
			"-d" | "--done" )
				log i "list DONE issues"
				path=$done_path
				f_ls_prototype $@
				path=$def_path/main
				;;
			"-h" )
				f_args -lh
				return
				;;
			"-pr" )
				PRgrep="___PR[0-9]{6}|___JIRA-[0-9]{1,5}"
				if [ "$#" -lt 3 ];then
					log i "Listing PRs"
					log t "`ls -hlt --color=auto --group-directories-first $path | grep ^d | egrep "(INC[0-9]{8})" | egrep $(PRgrep)`"
				else 
					log i "Listing pr with \"grep $3\""
					log t "`ls -hlt --color=auto --group-directories-first $path | grep ^d | egrep "(INC[0-9]{8})" | egrep $(PRgrep) | grep -i $3`"
				fi
				return
				;;
			"-24" )
				if [ "$#" -lt 3 ]; then
					log i "Listing 24x7 incidents | Emergencies"
					log t "`ls -Rhlt --color=auto --group-directories-first $path24x7 | grep ^d | egrep "(INC[0-9]{8})"`"
				else 
					log i "Listing 24x7 incidents | Emergencies with \"grep $3\""
					log t "`ls -Rhlt --color=auto --group-directories-first $path24x7 | grep ^d | egrep "(INC[0-9]{8})" | grep -i $3`"
				fi
				return
				;;
			"l")
				log i "Listing inc, jira and h2s"
				f_ls_prototype $@
				return
				;;
			"li")
				log i "Listing only incidents"
				f_ls_prototype $@
				return
				;;
			"lj" | "ld")
				log i "Listing only jira"
				f_ls_prototype $@
				return
				;;
			"lh")
				log i "Listing only h2s"
				f_ls_prototype $@
				return
				;;
			*)
				log i "Listing inc with \"grep $2\""
				f_ls_prototype $@
				return
				;;
		esac 
	else
		f_ls_prototype $@
		#f_ls null #=: BEWARE - LOOP!
		echo "###"
		f_wc null
	
	fi  
	} 
function f_ls_prototype () { 
	title_suffix=""
	inc_file=/tmp/inc.manage-inc
	jira_file=/tmp/jira.manage-inc
	h2s_file=/tmp/h2s.manage-inc
	if [ "$2" == "-bto" -o "$2" == "-b" -o "$2" == "-d" -o "$2" == "--done" ]; then
		grep=$3
		if [[ $2 == "-d" ]] || [[ $2 == "--done" ]];then
			path=$done_path
			title_suffix="[DONE]"
		fi
	elif [[ $2 == "-s" ]];then
		grep=""
	else
		grep=$2
	fi
	li_sort="sort -t | -k4,4r -k3,3 -k2,2 -k1,1"
	lj_sort="sort -t | -k4,4r -k2,2 -k 1,1"
	lh_sort="sort -t | -k4,4r -k2,2 -k 1,1"
	case $1 in
	"ls")
		# Incidents
		f_get_support_cases
	 	# JIRA
	 	f_get_development_cases
	 	# H2S
	 	f_get_h2s_cases
		echo "| Customization Support "
		cat $inc_file | $li_sort
    log i "| Number of active #$(wc -l $inc_file)"

		echo ""
		echo "| JIRA issues / Development "
		cat $jira_file | $lj_sort
    log i "| Number of active #$(wc -l $jira_file)"

		echo ""
		echo "| H2S's"
		cat $h2s_file | $lh_sort
    log i "| Number of active #$(wc -l $h2s_file)"
		;;
	"li")
		f_get_support_cases
		[[ $2 == "-s" ]] && li_sort="sort -t | $3"
		log t "$li_sort"
					# \n$(cat $inc_file | sort --debug -k7.8nr -k7.5nr -k7.2nr -k4 -k 1,1)"
		log i "| Customization Support ${title_suffix}\
					\n$(cat $inc_file | $li_sort)"
    log i "| Number of active #$(wc -l $inc_file)"
		;;
	"lj" | "ld")
	 	f_get_development_cases
		log i "| Customization JIRA \
					\n$(cat $jira_file | $lj_sort)"
    log i "| Number of active #$(wc -l $jira_file)"
		;;
	"lh")
	 	f_get_h2s_cases
		log i "| Customization H2S \
					\n$(cat $h2s_file | $lh_sort)"
    log i "| Number of active #$(wc -l $h2s_file)"
		;;
	* )
		# Incidents
		f_get_support_cases
	 	# JIRA
	 	f_get_development_cases
	 	# H2S
	 	f_get_h2s_cases
		log i "| Customization Support \
					\n$(cat $inc_file | $li_sort)\
					\n"
		log i "| JIRA issues / Development\
					\n$(cat $jira_file | $lj_sort)\
					\n"
		log i "| H2S's\
					\n$(cat $h2s_file | $lh_sort)"
		;;
	esac
	return
	} 
function f_wc () { 
	if [ $# -gt $EXP_ARGS ]; then
		case $2 in
			"-v")
				log i "Linecount with \"grep -vi $3\""
				log i "	...	 `ls $path | egrep $INC_MATCH | grep -vi $3 | wc -l`	...	"
				;;
			"-I")
				log i "Linecount of $3"
				log i "	...	 `ls $path | egrep $INC_MATCH | egrep "$3" | wc -l`	...	"
				echo
				;;
			*)
				log i "Linecount with \"grep $2\""
				log i "	...	 `ls $path | egrep $INC_MATCH | grep $2 | wc -l`	...	"
				;;
		esac
	else
		# f_wc_prototype
		f_wc_prototype

	fi
	} 
function f_wc_prototype () { 

		log i "Number of CUST incidents in my queue.."
		log i "	...	`ls $path | egrep "(^[0-9]{6})" | egrep "$3" | wc -l`	...	"
	
		log i "Number of JIRA issues / Development in queue.."
		log i "	...	`ls $path | egrep "(CUS-[0-9]{3})" | egrep "$3" | grep -v "H2S" | wc -l`	...	"

		log i "Number of H2S in my queue.."
		log i "	...	`ls $path | egrep "(H2S)" | egrep "$3" | wc -l`	...	"
	
		log i "Number of SMSC incidents in my queue.."
		log i "	...	`ls $path | egrep "(INC[0-9]{7}"$delim"SMSC)|(CS[0-9]{7}"$delim"SMSC)" | egrep "$3" | wc -l`	...	"
	} 

function f_check_links() { 
	EMPTY_OUTPUT=true
	for dirname in $(ls $path);do
		if [[ $dirname == "H2S"* ]];then
			if [[ ! -d $h2s_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				if [[ -L $h2s_path/$dirname ]];then
					echo $h2s_path/$dirname
					rm $h2s_path/$dirname
				fi
				ln -s $path/$dirname $h2s_path/$dirname
				if [[ $? == 0 ]];then
					log i "link for $dirname successfully created"
				else
					log e "link for $dirname was not created"
				fi
			fi
		elif [[ $dirname == "INC"* ]];then
			if [[ ! -d $inc_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				if [[ -L $inc_path/$dirname ]];then
					echo $inc_path/$dirname
					rm $inc_path/$dirname
				fi
				ln -s $path/$dirname $inc_path/$dirname
				if [[ $? == 0 ]];then
					log i "link for $dirname successfully created"
				else
					log e "link for $dirname was not created"
				fi
			fi
		elif [[ $dirname == "CUS"* ]];then
			if [[ ! -d $jira_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				if [[ -L $jira_path/$dirname ]];then
					echo $jira_path/$dirname
					rm $jira_path/$dirname
				fi
				ln -s $path/$dirname $jira_path/$dirname
				if [[ $? == 0 ]];then
					echo "[i] link for $dirname successfully created"
				else
					echo "[e] link for $dirname was not created"
				fi
			fi
		fi
	done
	if [[ $EMPTY_OUTPUT == true ]];then
		log i "nothing to do"
	fi
	} 
function f_id_as_first_argument () {
	# log "[d] NOARGS"
	f_get_inc_filter
	# ls "$path" | grep "$id" > /dev/null 2>&1

	if [ $nlines -eq 0 ]; then
		# No incident matching criteria found - create new one
		f_get_user_consent "Case does not exist, do You want to create it?"
		f_create_new_inc
	elif [ $nlines -eq 1 ]; then
		# Incident already exists
		log w "Incident already exists: ${grepped}"
		read -p "|	Do you want to [O]pen ${id} or [r]ename it or [n]either? [O/r/n] " ron
	    case $ron in
			[Nn]* ) 
				log w "User abort"
				return
				;;
			[Rr]* ) 
				log i "Renaming.."
				f_rename
				;;
			* ) 
				log i "Opening.."
				f_open
				;;
		esac

	elif [ -z $grepped ]; then
		# User input empty - finish with error
		log e "No ID inserted"
	else
		# User input matches multiple hits - finish with error
		log e "[e] Multiple matches, quitting.."
	fi #new/[i]rename/[e]multiple hit

	}

### Main {{
f_s_init
f_s_boc
if [ $EXP_ARGS -le $# ]; then
	f_args $@
else
	f_id_as_first_argument
fi #EXP_ARGS
unset d
f_s_eoc
#eo:Main }}
#EOF
##
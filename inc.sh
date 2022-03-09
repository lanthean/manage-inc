#!/usr/local/bin/bash
###
#                                                                            oo                   
#                                                                                               
#           88d8b.d8b. .d8888b. 88d888b. .d8888b. .d8888b. .d8888b.          dP 88d888b. .d8888b. 
#           88'`88'`88 88'  `88 88'  `88 88'  `88 88'  `88 88ooood8 88888888 88 88'  `88 88'  `"" 
#           88  88  88 88.  .88 88    88 88.  .88 88.  .88 88.  ...          88 88    88 88.  ... 
#           dP  dP  dP `88888P8 dP    dP `88888P8 `8888P88 `88888P'          dP dP    dP `88888P' 
#                                                   .88                                        
#                                               d8888P                                         
#           https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Nancyj-Fancy&text=manage-inc
#
# @Author   lanthean@protonmail.com
# @Created	04/07/2013
#
# @Package  manage-inc
###

timer_start=$(date +"%s%N")
VERSION='2.2.3'
COPYRIGHT='lanthean@protonmail.com, https://github.com/lanthean'

# available LOG_LEVEL values: t,d,i,w,e
LOG_LEVEL=i

## Static functions
function f_s_init() {
  # def vars
	user="$(/usr/bin/whoami)"
	handle='incident (plaintext/markdown/filetree) management'
	script_name='inc'
	EXP_ARGS=1
	year="$(date +"%Y")"
	def_path=~/inc
	main_path=$def_path/main

	## disable logging [true|false]
	# LOG_DISABLED=true
	LOG_FILE=$def_path/log/incidents.log

	VIM=mvim

	TODOTXT_FILE="${HOME}/Dropbox/Apps/Todotxt+/work.todo"
	TODOTXT_DUE_DATE=$(date "+%F")

	# Support case STATUS:
	INC_NEW_STATUS=""
	INC_NEW="NEW"
	INC_RSP="RESPONDED"
	INC_ACT="ACTIVE"
	INC_AWC="ACTIVE WC"
	INC_RST="RESTORED"
	INC_RWC="RESTORED WC"
	INC_RES="RESOLVED"
	INC_CLS="CLOSED"

	##
	# in case decision is made to distribute incident/h2s/jira issues to separate directories ./incidents; ./h2s; ./jira
	# (at this moment manually created soft links are in place)
	inc_path=$def_path/inc
	h2s_path=$def_path/h2s
	jira_path=$def_path/dev
	done_path=$def_path/done
	##
	backtoops_path=$def_path/back2ops
	_24x7_path=$def_path/24x7/$year
	team_path=$main_path/team
	delim="__"
	id_def="xxxxxx000000xxxxxx"
	INC_MATCH="(INC[0-9]{8})|(CS[0-9]{8})|(CUS-[0-9]{4,})|([0-9]{6})"
	id=$id_def
	max_lines=999 #47

	if [[ $(uname) == "Darwin" ]];then
		user_downloads=/Users/$user/Downloads
	else
		user_downloads=/home/$user/Downloads
	fi

	if [ ! -d /opt/gbf ];then
		echo "/opt/gbf not found, attemting to clone from lanthean's github"
		pushd /opt
		sudo git clone https://github.com/lanthean/gbf.git
		popd
		sudo chown -R $USER:staff /opt/gbf
	fi
	source /opt/gbf/generic_bash_functions
	} 
function f_s_boc() { 
	#start with something nice to say
	#echo "### Welcome $user
	# I will handle $handle for You now.."
	echo "###"
	#echo "#"
	} 
function f_s_eoc() { 
	#say good bye
	# log t "f_s_eoc(): \$1=$1, \$2=$2"
	[[ $# -eq 2 ]] && log "$1" "$2"
	log t "f_s_eoc(): eof"
	echo "###"
	exit 0
	} 

## getters/setters
function f_get_user_consent() {
	if [[ -z $1 ]];then
		message="Do You want to continue?"
	else
		message=$1
	fi
	read -p "|	${message} [Y/n]: " yn
	if [[ $yn == "n" ]];then
		if [[ ! -z $2 ]];then
			log d "f_get_user_consent(): executing -> $2"
			$($2)
		fi
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
		log t "f_get_inc_filter(): no case ID available, query user"
		read -p "|	Please input the incident ID: " id
	fi

	# check if user wants to see INC in back2ops
	if [ $# -gt 0 ];then
		case $1 in
			"-b" | "--backtoops" )
				log t "back to ops main_path will be used (${backtoops_path})"
				main_path=$backtoops_path
				;;
			"-d" | "--done" )
				log t "done main_path will be used (${done_path})"
				main_path=$done_path
				;;
		esac
	fi

	grepped=$(ls "$main_path" | grep "$id")
	nlines=$(ls "$main_path" | grep "$id" | wc -l)		
	if [ -z "$id" ];then
		grepped=0
		nlines=0
		log t "f_get_inc_filter: No $id available"
		return
	else
		grepped=$(ls "$main_path" | grep "$id")
		nlines=$(ls "$main_path" | grep "$id" | wc -l)
	fi
	log t "nlines: ${nlines}; grepped: ${grepped}"
	main_path=$def_path/main
	} 
function f_get_rename() {
	# docstring
	#
	# $1 = arg - desc (type)
	#
	# return: 0 - success

	read -p "|	What do you want to edit (empty: cancel|quit) [i=id|t=team|c=cust|s=sfid|d=desc|p=prio] ? " choice
	case $choice in
		[Ii] )
			read -p "|	Enter new ID: " id
			log t "id: $id"
			id_ch=1
			f_get_rename
			;;
		[Tt] )
			read -p "|	Enter new case type ([I]NC, [H]2S, [D]EV): " __case_type
			log t "input case_type: $case_type"
			f_get_case_type
			log t "normalized case_type: $case_type"
			type_ch=1
			f_get_rename
			;;
		[team] )
			read -p "|	Enter new Team: " team
			log t "team: $team"
			team_ch=1
			f_get_rename
			;;
		[Cc] )
			read -p "|	Enter new Customer: " cust
			log t "cust: $cust"
			cust_ch=1
			f_get_rename
			;;
		[Ss] )
			read -p "|	Enter new SF-ID: " sfid
			log t "sfid: $sfid"
			sfid_ch=1
			f_get_rename
			;;
		[Dd] )
			read -p "|	Enter new Description: " desc_raw
			desc=${desc_raw// /_}
			log t "desc_raw: $desc_raw"
			log t "desc: $desc"
			desc_ch=1
			f_get_rename
			;;
		* )
			log d "Nothing to change."
			return
			;;
	esac
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
	if [ -f $inc_file ] ;then
		rm $inc_file
		touch $inc_file
	fi
	for dir in $(ls -t $main_path | grep "${delim}INC${delim}" | egrep -i "$grep");do 
		W="" S="" U="" STATUS="" PRIORITY=""
		if [[ $(ls "$main_path/$dir/" | grep "ticket" | wc -l) -ge 1 ]]; then
			update=$(cat $main_path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})")
			update=${update//[$'\r\n']}
			status=$(cat $main_path/$dir/ticket.* | grep --text "@Status")
			status=${status//[$'\r\n']}
			priority=$(cat $main_path/$dir/ticket.* | grep --text "@Pri")
			priority=${priority//[$'\r\n']}
			U="${update:10:10}[U]"
			STATUS="${status:10:14}"
			PRIORITY="${priority:8:7}"
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

		arr=( ${dir//$delim/ } )

		_id=${arr[0]}
		# f_create_downloads_link $_id
		log t "_id=${_id}"
		_type=${arr[1]}
		log t "_type=${_type}"
		_team=${arr[2]}
		log t "_team=${_team}"
		_customer=${arr[3]}
		log t "_customer=${_customer}"
		_description=${arr[4]}
		log t "_description=${_description}"
		##
		# Table display
		if [[ $1 == "todotxt" ]];then
			echo "@${_type,,} +${_id} ${_team} ${_customer} ${_description}" >> $inc_file
		else
			printf "%-8s | %3s | %3s | %-15s | %-80s |%-7s |%-11s |%13s\n" "$_id" "$_type" "$_team" "$_customer" "$_description" "$PRIORITY" "${STATUS^^}" "$U" >> $inc_file
		fi
	done 
	}
function f_get_development_cases() {
	# JIRA	
	if [ -f $jira_file ];then
		rm $jira_file
		touch $jira_file
	fi
	# search for "CUS-[0-9]{at least 3 occurences}"
	for dir in $(ls -t $main_path | grep "${delim}DEV${delim}" | egrep -i "$grep" | grep -v "H2S");do 
		P="" S="" U="" STATUS=""
		if [ -f $main_path/$dir/ticket.* ]; then
			progress=$(cat $main_path/$dir/ticket.* | grep --text "@Progress" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused")
			solution=$(cat $main_path/$dir/ticket.* | grep --text "@Solution" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused|([0-9]{3,6})")
			update=$(cat $main_path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})")
			status=$(cat $main_path/$dir/ticket.* | grep --text "@Status")
			P="${progress:13:10}[P]"
			S="${solution:13:10}[S]"
			U="${update:10:10}[U]"
			STATUS="${status:10:14}"
		fi
		if [ "$S" == "[S]" ];then
			S="n/a[S]"
		elif [[ $S == *"paused"* ]];then
			S="paused[S]"
		fi
		if [ "$U" == "[U]" ];then		
			U="n/a[U]"
		fi

		arr=( ${dir//$delim/ } )
		_id=${arr[0]}
		# f_create_downloads_link $_id
		log t "_id=${_id}"
		_type=${arr[1]}
		log t "_type=${_type}"
		_team=${arr[2]}
		log t "_team=${_team}"
		_customer=${arr[3]}
		log t "_customer=${_customer}"
		if [[ ${#arr[*]} -gt 5 ]];then
			_description="${arr[4]} - ${arr[5]}"
			log t "_description=${_description}"		
		else
			_description=${arr[4]}
			log t "_description=${_description}"
		fi
		# log t "#arr: ${#arr[@]}; arr[1]: ${arr[1]}, arr[2]: ${arr[2]}, arr[3]: ${arr[3]}, arr[4]: ${arr[4]}, arr[5]: ${arr[5]}, "
		# if [ ${#arr[@]} -gt 4 ];then
	 	# 	_description=${arr[4]}
		# 	log t "_description=${_description}"
		# else
	 	# 	_description=${arr[3]}
		# 	log t "_description=${_description}"
		# fi
		##
		# Table display
		if [[ $1 == "todotxt" ]];then
			echo "@${_type,,} +${_id} ${_team} ${_customer} ${_description}" >> $jira_file
		else
			printf "%-8s | %3s | %3s | %-20s | %-80s |%-13s |%-13s\n" "$_id" "$_type" "$_team" "$_customer" "$_description" "$S" "$U" >> $jira_file
		fi
	done 
	}
function f_get_h2s_cases() {
	# H2S 
	log t "f_get_h2s_cases() - \$1=$1; \$2=$2; \$3=$3; "
	if [ -f $h2s_file ];then
		log t "f_get_h2s_cases() - recreate ${h2s_file}"
		rm $h2s_file
		touch $h2s_file
	else
		log t "f_get_h2s_cases() - create ${h2s_file}"
		touch $h2s_file
	fi
	log t "f_get_h2s_cases(): main_path: ${main_path}; grep: ${grep}"
	log t "\$(ls -t $main_path | grep "${delim}H2S${delim}" | egrep -i "$grep")"
	for dir in $(ls -t $main_path | grep "${delim}H2S${delim}" | egrep -i "$grep");do 
		log t "dir: ${dir}"
		P="" S="" U="" STATUS=""
		if [ -f $main_path/$dir/ticket.* ]; then
			progress=$(cat $main_path/$dir/ticket.* | grep --text "@Progress" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused")
			# workaround=$(cat $main_path/$dir/ticket.* | grep --text "@Workaround" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused")
			# solution=$(cat $main_path/$dir/ticket.* | grep --text "@Solution" | egrep "([0-9]{2})/([0-9]{2})/([0-9]{4})|paused|([0-9]{3,6})")
			update=$(cat $main_path/$dir/ticket.* | grep --text "@Update" | egrep "([0-9]{2,4})/([0-9]{2})/([0-9]{2,4})")
			status=$(cat $main_path/$dir/ticket.* | grep --text "@Status")
			P="${progress:13:10}[P]"
			# W="${workaround:14:10}[W]"
			# S="${solution:13:10}[S]"
			U="${update:10:10}[U]"
			STATUS="${status:10:19}"
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

		arr=( ${dir//$delim/ } )
		_id=${arr[0]}
		# f_create_downloads_link $_id
		log t "_id=${_id}"
		_type=${arr[1]}
		log t "_type=${_type}"
		_team=${arr[2]}
		log t "_team=${_team}"
		_customer=${arr[3]}
		log t "_customer=${_customer}"
		if [ ${#arr[@]} -gt 5 ];then
	 		_sfid=${arr[4]}
			log t "_sfid=${_sfid}"
	 		_description=${arr[5]}
			log t "_description=${_description}"
		else
	 		_description=${arr[4]}
			log t "_description=${_description}"
		fi

		##
		# Table display
		if [[ $1 == "todotxt" ]];then
			echo "@${_type,,} +${_id} ${_team} ${_customer} ${_description}" >> $h2s_file
		else
			printf "%-8s | %3s | %3s | %-15s | %-60s |%-20s |%-13s |%13s\n" "$_id" "$_type" "$_team" "$_customer" "$_description" "${STATUS^^}" "$P" "$U" >> $h2s_file
		fi
		# printf "%-79s %-10s %13s %13s %13s\n" "$dir" "$STATUS" "$W" "$S" "$U" >>  $h2s_file
		# if [[ $1 == "todotxt" ]];then
		# 	printf "%-3s %-82s %-7s %-11s %13s\n" "@h2s" "+$_id" "$_" >>  $h2s_file
		# else
		# 	printf "%-85s |%-15s |%13s |%13s\n" "$dir" "$STATUS" "$P" "$U" >>  $h2s_file
		# fi
		log t "f_get_h2s_cases() - eo"
	done
	}
function f_get_id() {
	# docstring
	#
	# $1 = grepped / filename - name of the directory of the case in $main_path (string)
	#
	# return: 0 - success
	filename=$1
	if [[ $nlines -gt 1 ]];then
		log e "f_get_id() - multiple hits"
		return 1
	fi
	arr=$(f_parse_inc_name $filename)
	log t "f_parse_inc_name() - filename: ${filename}"
	log t "f_parse_inc_name() - arr: ${arr}"
	log t "f_get_id() - id: $id (pre)"
	id=${arr[0]}
	log t "f_get_id() - id: $id (post)"
	return 0
	}
function f_get_case_type() {
	# Get (prepare) correct case_type (INC, H2S or DEV)
	#
	# return: void
	case_type=${case_type^^}
	case $case_type in
		"H"* )
			case_type="H2S"
		;;
		"D"* )
			case_type="DEV"
		;;
		# "" )
		# 	[ $id == *"CUS-"* ] && case_type="DEV"
		# 	[ $id == *"CUS-"* ] || case_type="INC"
		# ;;
		* )
			case_type="INC"
		;;
	esac
	}
function f_get_status() {
	# Set correct case status
	#
	# return: void
	# INC_NEW="new"
	# INC_RSP="responded"
	# INC_ACT="active"
	# INC_AWC="active WC"
	# INC_RST="restored"
	# INC_RWC="restored WC"
	# INC_RES="resolved"
	# INC_CLS="closed"
	if [[ $# -gt 2 ]];then
		id=$2
		__status=$3
	else
		__status=$2
	fi
	log d "f_get_status(): $*"
	case $__status in
		"new" )	INC_NEW_STATUS=${INC_NEW};;
		"rsp" )	INC_NEW_STATUS=${INC_RSP};;
		"act" )	INC_NEW_STATUS=${INC_ACT};;
		"awc" )	INC_NEW_STATUS=${INC_AWC};;
		"rst" )	INC_NEW_STATUS=${INC_RST};;
		"rwc" )	INC_NEW_STATUS=${INC_RWC};;
		"res" )	INC_NEW_STATUS=${INC_RES};;
		"cls" )	INC_NEW_STATUS=${INC_CLS};;
		* ) log e "f_get_status(): use these [ new | rsp | act | awc | rst | rwc | res | cls ]";;
	esac
	}
function f_get_help() {
	log i "[h]  Script: "$script_name
	log i "[h]  Help: Listing of available extensions"
	f_get_listing_help
	log i "[h]  wc			... in default mode will show how many incidents are there in my queue"
	log i "[h]  wc -v		... show how many incidents are there while filtering the \$3 out of the result"
	log i "[h]  log			... show incident management log"
	log i "[h]  [-s] ID status	... [--set-status] set new status + update @Update to current date"
	log i "[h] 			... e.g. \$ inc -s <inc_id> [ new | rsp | act | awc | rst | rwc | res | cls ]"
	log i "[h] 			... also \$ inc <inc_id> -s [ new | rsp | act | awc | rst | rwc | res | cls ]"
	log i "[h]  [-d] done		... move incident to $done_path folder"
	log i "[h]  [-t] team		... move incident to $team_path folder"
	log i "[h]  [-b][bto] backtops	... move incident to $backtoops_path folder"
	log i "[h]  [-u][rti] return 	... move incident back from $backtoops_path"
	log i "[h]  [-r] rename		... rename incident"
	log i "[h]  [-M] remove		... delete incident | [M]ove incident to trash"
	log i "[h]  [-n] new		... create new incident"
	log i "[h]  [-l] links		... check soft links"
	log i "[h]  If no argument, wizard is started, asking for an ID. Then handling of this partial incident or a new on is started. Have an incident number/ID ready."
	}
function f_get_listing_help() {
	log i "[h]  [l]s			... in default mode will list all apropriate INC directories.
					[W]orkaround, [S]olution,[U]pdate dates from ./INC../ticket.{ntx,txt,md}"
	log i "[li]    			... list only incidents"
	log i "[lj]    			... list only development/assessment JIRA tasks"
	log i "[lh]    			... list only H2S JiRA tasks"
	log i "[h]  ls -f		... full main_path"
	log i "[h]  ls -v		... filter \$3 out of the result"
	log i "[h]  ls -I		... filter \$3 case sensitive"
	log i "[h]  ls -n		... ls -l incidents by name [crosscheck with ARS|Nikita]"	
	log i "[h]  ls -24		... ls -rl 24x7 and Emergency incidents from $year"	
	}
function f_set_status() {
	# Set correct case status
	#
	# return: void
	[[ $# -gt 2 ]] && id=$2
	f_get_inc_filter
	f_get_status $@

	# replace
	# '^# @Status	*$'
	# with
	# '# @Status	${INC_NEW_STATUS}'
	[[ $INC_NEW_STATUS == "" ]] && f_s_eoc e "f_set_status(): INC_NEW_STATUS not set"
	
	ticket_file_with_path=$(find $main_path/$grepped -name "ticket.*" -maxdepth 1)
	[[ ${ticket_file_with_path} == "" ]] && log e "f_set_status(): ticket_file_with_path = Null"
	DATE=$(date +%Y\\\/%m\\\/%d)
	log t "cat ${ticket_file_with_path} | sed -e \"s/^# @Update.*$/# @Update\t${DATE}/g;s/^# @Status.*$/# @Status\t${INC_NEW_STATUS}/g\" > ${ticket_file_with_path}.tmp"
	cat ${ticket_file_with_path} | sed -e "s/^# @Update.*$/# @Update\t${DATE}/g;s/^# @Status.*$/# @Status\t${INC_NEW_STATUS}/g" > ${ticket_file_with_path}.tmp
	
	log i "${grepped}/ticket.md.tmp was created with new STATUS: ${INC_NEW_STATUS}"
	f_get_user_consent "Is the .tmp file OK?" "rm ${ticket_file_with_path}.tmp"
	log t "mv ${ticket_file_with_path}.tmp ${ticket_file_with_path}"
	mv ${ticket_file_with_path}.tmp ${ticket_file_with_path}
	}
## Functions
function f_readinp() { 
	## Read user's input
	case_type="INC"
	team="CUS" #read -p "|	Team (SMSC/CUST): " team
	read -p "| 	Type ([Ii]NC, [Hh]2S, [Dd]EV) [default = INC]: " case_type
	read -p "|	Customer [${cust}]: " _cust
	read -p "|	Short description of the incident [${desc}]: " _desc
	read -p "|	Priority of the incident [${prio}]: " _prio
	read -p "|	Status of the incident [${stat}]: " _stat
	read -p "|	Contact: " contact
	read -p "|	Release: " release
	read -p "|	Systems: " systems
	read -p "|	SF-ID [${sfid}]: " _sfid

	[ "$_cust" != "" ] &&  cust=$_cust
	[ "$_desc" != "" ] &&  desc=$_desc
	[ "$_prio" != "" ] &&  prio=$_prio
	[ "$_stat" != "" ] &&  stat=$_stat
	[ "$_sfid" != "" ] &&  sfid=$_sfid

	# Set proper case_type from input
	f_get_case_type
	} 
function f_create_downloads_link() {
	_id=$1
	log t "id: ${_id}"

	physical_directory=$(ls ${main_path} | grep ${_id})
	if [[ $physical_directory == *"${delim}H2S${delim}"* ]];then
		downloads_path="${user_downloads}/h2s"
	elif [[ $physical_directory == *$"${delim}DEV${delim}"* ]];then
		downloads_path="${user_downloads}/dev"
	else
		downloads_path="${user_downloads}/inc"
	fi
	log t "id: ${_id}"
	log t "main_path: ${main_path}"
	log t "downloads main_path: ${downloads_path}"
	if [[ -d $downloads_path/$_id ]];then
    log w "There is a directory in place of the new link location - reversing"
    log t "ln -sn $downloads_path/$_id $main_path/$physical_directory/"
    ln -sn $downloads_path/$_id $main_path/$physical_directory/
	elif [[ -L $downloads_path/$_id ]];then
		log w "There is a link in place, let's update it"
		log t "ln -sfn ${main_path}/${physical_directory} ${downloads_path}/${_id}"
		ln -sfn ${main_path}/${physical_directory} ${downloads_path}/${_id}
	else
		log i "Creating link to ${downloads_path}/${_id} -> $main_path/$physical_directory/"
		log t "ln -sn ${main_path}/${physical_directory} ${downloads_path}/${_id}"
		ln -sn ${main_path}/${physical_directory} ${downloads_path}/${_id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link."
			log e "Link to ${downloads_path}/${_id} -> $main_path/$physical_directory/ was not created."
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
	log t "downloads main_path: ${downloads_path}"
	if [[ -L $downloads_path/$id ]];then
		physical_directory=$(ls ${done_path} | grep ${id})
		log i "Updating link to ${downloads_path}/${id} -> ${done_path}/${physical_directory}"
		log t "ln -sfn ${done_path}/${physical_directory} ${downloads_path}/${id}"
		ln -sfn ${done_path}/${physical_directory} ${downloads_path}/${id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link"
			log e "Link to ${downloads_path}/${id} was not updated"
		fi
	elif [[ -d $downloads_path/$id ]];then
    log w "There is a directory in place of the new link location - reversing"
    log t "ln -sfn $downloads_path/$id $done_path/$physical_directory/"
    ln -sfn $downloads_path/$id $done_path/$physical_directory/
	fi
	}
function f_remove_downloads_link() {
	_id=$1

	log t "id: ${_id}"
	if [[ $_id == *"H2S"* ]];then
		downloads_path="${user_downloads}/h2s"
		_id=${_id:4}
	elif [[ $_id == *"CUS-"* ]];then
		downloads_path="${user_downloads}/dev"
	else
		downloads_path="${user_downloads}/inc"
	fi

	log t "id: ${_id}"
	log t "main_path: ${main_path}"
	log t "downloads main_path: ${downloads_path}"
	if [ -L ${downloads_path}/${_id} ];then
		log i "Removing link to ${downloads_path}/${_id}."
		rm ${downloads_path}/${_id}
		if [ $? != 0 ];then
			log e "Unknown error: Possibly broken link."
			log e "Link to ${downloads_path}/${_id} was not deleted."
		fi
	else
		log w "Link to ${downloads_path}/${_id} does not exist."
	fi
	# Silently remove possible broken remnants in other paths
	if [ -L ${user_downloads}/h2s/${_id} ];then
		rm ${user_downloads}/h2s/${_id} > /dev/null 2>&1 
	fi		
	if [ -L ${user_downloads}/dev/${_id} ];then
		rm ${user_downloads}/dev/${_id} > /dev/null 2>&1 
	fi		
	if [ -L ${user_downloads}/inc/${_id} ];then
		rm ${user_downloads}/inc/${_id} > /dev/null 2>&1 
	fi		
	}	
function f_create_new_inc () { 
	# New incident
	# Let's create a new incident
	log i "Creating new incident"
	
	OIFS=$IFS
	if [[ $id =~ ^[0-9]{6}$ ]];then
		heat_res=$(~/bin/ops -i4b $id)
		if [[ $heat_res != "404" ]];then
			#
			# ssh://git@bb.mavenir.com:7999/~bortelm/bortelm_tools.git @devops-tools $(ops -i4b ${id})
			# - returns "404" in case no incident owned by Customization Support team matched ${id}
			# - or returns e.g. "438753|4|Active|KPN NL mVas|bortelm|Customization support|re-routing codes in SRI|C2E02EABF61947978310BD4CA5A5E353"

			IFS="|" read -a arr_heat <<< "$heat_res"
			IFS=$OIFS

			prio=${arr_heat[1]}
			stat=${arr_heat[2]}
			cust=${arr_heat[3]}
			desc=${arr_heat[6]}
			rec_id=${arr_heat[7]}

			echo "HEAT URI: "
			echo "http://mavenir.saasit.com//Login.aspx?Scope=ObjectWorkspace&CommandId=Search&ObjectType=Incident%23&CommandData=RecId,%3D,0,${rec_id},string,AND|#"
		else
			# 404 encountered - no incident matching ${id} owned by Customization Support team found:
			log e "Case: ${id} does not exist in HEAT."
			f_get_user_consent "Do you want to override?"
		fi
	elif [[ $id =~ ^CUS-[0-9]{4}$ ]];then
		jira_res=$(~/bin/h2s -i4b $id)
		if [[ $jira_res != "404" ]];then
			#
			# ssh://git@bb.mavenir.com:7999/~bortelm/bortelm_tools.git @devops-tools $(ops -i4b ${id})
			# - returns "404" in case no incident owned by Customization Support team matched ${id}
			# - or returns e.g. "438753|4|Active|KPN NL mVas|bortelm|Customization support|re-routing codes in SRI|C2E02EABF61947978310BD4CA5A5E353"

			IFS="|" read -a arr_jira <<< "$jira_res"
			IFS=$OIFS

			prio=${arr_jira[1]}
			stat=${arr_jira[2]}
			cust=${arr_jira[3]}
			sfid=${arr_jira[4]}
			desc=${arr_jira[5]}
			rec_id=${arr_jira[0]}
			# echo "$rec_id $prio $stat $cust $desc"

			JIRA_URI="https://at.mavenir.com/jira/browse/${rec_id}"
			echo "JIRA URI: "
			echo "${JIRA_URI}"
		else
			# 404 encountered - no incident matching ${id} owned by Customization Support team found:
			log e "Case: ${id} does not exist in JIRA."
			f_get_user_consent "Do you want to override?"
		fi
	fi
	f_get_user_consent

	f_readinp

	newinc=${id}${delim}${case_type}${delim}${team}${delim}${cust}${delim}${desc// /_}
	log i "Waiting for user confirmation of new incident: $newinc"
	read -p "|	Is it OK? [Y/n] " yn
	case $yn in
		[Nn]* )
			log i "User abort! Quitting.."
			return
			;;
		* )
			# echo "case f_create_new_inc"
			$(mkdir $main_path/$newinc)
			log t "mkdir ${main_path}/${newinc}"
			
			DATE=$(date +%Y\\\/%m\\\/%d) # fucking sed - escaped for sed parsing onwards
			UPDATE=${DATE}
			STATUS=${stat^^}
			PRI=${prio^^}
			ID=${id}
			SFID=${sfid}
			TOPIC=${desc}
			CUSTOMER=${cust}
			PRODUCT=
			SYSTEMS=${systems}
			RELEASE=${release}
			CONTACT=${contact}
			LINK_TO=${JIRA_URI}

			# echo "$main_path/$newinc/ticket" v "$DATE" "$UPDATE" "$PRI" "$ID" "$SFID" "$TOPIC" "$CUSTOMER" "$PRODUCT" "$SYSTEMS" "$RELEASE" "$CONTACT" "$STATUS"
			# read -p "Press any key to continue"
			$HOME/bin/newincf "$main_path/$newinc/ticket" mvim "$DATE" "$UPDATE" "$PRI" "$ID" "$SFID" "$TOPIC" "$CUSTOMER" "$PRODUCT" "$SYSTEMS" "$RELEASE" "$CONTACT" "$STATUS" "$LINK_TO"

			# f_check_links
			if [ $? == 0 ]; then
				log i "Done: incident successfully created"
			else
				log e "Check previous err messages for details"
			fi

      		# Create link to ~/Downloads
			f_create_downloads_link ${ID}
			
			# Create TODOTXT+ task
			f_todotxt ${ID}
			;;
	esac
	} 
function f_parse_inc_name() {
	# Get main variables from inc main_path name
	# e.g. id; description
	# $1 = filename
	# return array
	filename=$1
	case_arr=( ${filename//$delim/ } )
	# newinc=${id}${delim}${case_type}${delim}${team}${delim}${cust}${delim}${desc// /_}
	id=${case_arr[0]}
	case_type=${case_arr[1]}
	team=${case_arr[2]}
	cust=${case_arr[3]}
	desc=${case_arr[4]}
  	echo ${case_arr[*]}
	}
function f_rename() { 
	## Rename Incident folder
	id_ch=0; type_ch=0; team_ch=0; cust_ch=0; sfid_ch=0; desc_ch=0; prio_ch=0;
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

		filename=$(ls $main_path | grep $id)
		arr=( ${filename//$delim/ } )
		log i "[i]d .............. ${arr[0]}"
		log i "[t]type ........... ${arr[1]}"
		log i "[team] ............ ${arr[2]}"
    	log i "[c]ustomer name ... ${arr[3]}"
		log i "[d]escription ..... ${arr[4]}"
		# log i "[s]f-id ........... ${arr[4]}"
	#	log i "prio	... ${arr[5]}"
	
		f_get_rename

		if [ $id_ch -eq 1 -o $type_ch -eq 1 -o $team_ch -eq 1 -o $cust_ch -eq 1 -o $sfid_ch -eq 1 -o $desc_ch -eq 1 -o $prio_ch -eq 1 ]; then
			if [ $id_ch -ne 1 ]; then
				id=${arr[0]}
			fi
			if [ $type_ch -ne 1 ]; then
				case_type=${arr[1]}
			fi
			if [ $team_ch -ne 1 ]; then
				team=${arr[2]}
			fi
			if [ $cust_ch -ne 1 ]; then
				cust=${arr[3]}
			fi
			if [ $desc_ch -ne 1 ]; then
				desc=${arr[4]}
			fi
			if [ $sfid_ch -ne 1 ]; then
				sfid=${arr[5]}
			fi
			
			log t "old data: ${arr[*]}"
			# newfilename="${id}${delim}${team}${delim}${cust}${delim}${sfid}${delim}${desc}"
			newfilename="${id}${delim}${case_type}${delim}${team}${delim}${cust}${delim}${desc}"
			log t "new data: ${id} ${case_type} ${team} ${cust} ${desc} ${sfid}"

	    log i "New name: ${newfilename}"
			log i "Renaming in progress.."
			read -p "|  Is it OK? [Y/n] " yn
			case $yn in
				[Nn]* )
					log i "Nothing to do, quitting.."
					return
					;;  
				* ) 
					log t "mv $main_path/$filename $main_path/$newfilename"
					$(mv $main_path/$filename $main_path/$newfilename)
					# Create new link in ~/Downloads
					f_create_downloads_link $id
					log i "Successfully renamed"
					log t "$main_path/$newfilename"
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
		log t "Opening $main_path/$grepped/ticket.*"
		if [[ $(ls "$main_path/$grepped/" | grep "ticket" | wc -l) -ge 1 ]];then
			${VIM} $main_path/$grepped/ticket.*
		else
			log e "There is no ticket.{ntx,txt,md} in ${main_path}/${grepped}"
		fi
	fi
	}
function f_remove () { 
	#	log "[e] Function not implemented yet! Quiting.."
	#	return
	log w "Remove action in progress"
	f_get_inc_filter
	if [ $nlines -eq 1 ]; then
		f_get_id $grepped
		log w "Removing inc $grepped"
		log w "Waiting for user confirmation."
		read -p "|  Do you really want to delete this incident? [y/N/[t]rash] " yn
		case $yn in 
			[Yy]* )
				log w "User confirmed, deleting $grepped"
				log t "$(pwd)"
				log t "rm -rf ./$grepped"
				rm -rf $grepped
				log w "Inc removed with success"
				f_remove_downloads_link $id
				;;
			[Tt]* )
				log w "Moving inc to trash"
				if [ -d $main_path/trash ];then
					mv $grepped $main_path/trash
				else
					log w "Trash folder does not exists, creating.. $main_path/trash"
					mkdir $main_path/trash
					mv $grepped $main_path/trash
				fi
				f_remove_downloads_link $id
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
		f_get_id $grepped
		log i "Sending inc $grepped"
		log i "Waiting for user confirmation."
		read -p "|  Do you really want to move this incident to $backtoops_path folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log "mv $grepped $backtoops_path"
				mv $grepped $backtoops_path
				log i "Inc moved to $backtoops_path folder with success"
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
				log i "User confirmed, moving $grepped to $done_path"
				log t "mv ${main_path}/$grepped $done_path"
				mv ${main_path}/$grepped $done_path
				if [[ $? -eq 0 ]];then
					log i "Inc moved to $done_path folder with success"
	        log i "Update inc link in ${user_downloads}/inc"
	        log t "grepped: ${grepped}"
	        inc_arr=$(f_parse_inc_name $grepped)
	        log t "id: ${inc_arr[0]}"
	        f_update_downloads_link_to_done ${inc_arr[0]}
				else
					log e "Moving failed. Please try manually."
					log e "mv ${main_path}/${grepped} ${done_path}"
				fi	
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
		read -p "|  Do you really want to move this incident to $main_path folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log t "mv $backtoops_path/$grepped $main_path"
				mv $backtoops_path/$grepped $main_path
				log i "Inc moved to $main_path folder with success"
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
		read -p "|  Do you really want to move this incident to $team_path folder? [y/N] " yn
		case $yn in 
			[Yy]* )
				log i "User confirmed, moving $grepped"
				log t "mv $grepped $team_path"
				mv $grepped $team_path 
				log i "Inc moved to $team_path folder with success"
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

function f_args() { 
	log t "f_args(): \$1=$1"
	case $1 in
		"--test" ) #check soft link to ~/Downloads
			log t "f_args() - --test - \$2: ${2}"
			if [[ -n $2 ]];then
				id=$2
			fi
			f_get_inc_filter
			f_get_id $grepped
			return
			;;
		"--todotxt" ) #check soft link to ~/Downloads
			if [ ! -z "$2" ];then
				id=$2
			fi
			f_todotxt $id
			return
			;;
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
		"-s" | "--set-status" ) #incident reassigned within team function
			if [[ $# -lt 2 ]];then
				log e "inc [-s|--status] called with too few arguments"
				f_s_eoc
			else
				f_set_status $@
				return
			fi
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
			echo $main_path
			f_s_boc
			f_ls $@
			return
			;;
		"li" | "lj" | "ld" | "lh" )
			/usr/bin/clear
			echo $main_path
			f_s_boc
			f_ls $@
			return
			;;
		"ls" | "lstate" ) #listing function
			/usr/bin/clear
			echo $main_path
			f_s_boc
			f_ls $@
			return
			;;
		"wc" | "lines" ) #lines count function
			f_wc $@
			return
			;;
		"--help" | "-h" | "-?" )
			f_get_help
			return
			;;
		"-lh"|"-hl" ) #listing help for ls function
			f_get_listing_help
			return
			;;
		"-v" | "--version" | "version" | "copyright")
			log i "Version: ${VERSION}"
			log i "(c) ${COPYRIGHT}"
			return
			;;
		$(awk '{a=0}/[0-9]{4,}/{a=1}a' <<<$1) | $(awk '{a=0}/C[A-Z][A-Z]-[0-9]{3,}/{a=1}a' <<<$1))
		# $1 = case reference (e.g. 380123) or JIRA reference (e.g. CUS-3050)
			log d "id passed awk test as $1"
			id=$1
			f_id_as_first_argument $@
			return
			;;
		"." )
			fl_ticket=$(ls . | grep ticket)
			log i "Opening $fl_ticket"
			${VIM} ./$fl_ticket
			;;
		* )
			log e "Wrong argument \"$1\", quitting.. to see help use --help or -h"
			return
			;;
	esac
	} 

function f_ls() { 
	log t "f_ls(): $*"
	if [ $# -gt $EXP_ARGS ]; then
		case $2 in 
			"--raw" )
				log i "Listing raw with \"grep $3\""
				log t "find $def_path/* -name \"*$3*\""
				find $def_path/* -name "*$3*"
				return
				;;
			"-f" )
				if [ "$#" -lt 3 ];then
					log i "full main_path"
					log t "$(ls -dhlt -1 $main_path/** --color=auto | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})")"
				else
					log i "full main_path with grep -i $3"
					log t "$(ls -dhlt -1 $main_path/** --color=auto | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | grep -i $3)"
				fi
				;;
			"-v" )
				log i "grep -vi $3"
				log t "$(ls -hlt $main_path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | grep -vi $3)"
				;;
			"-I" )
				log i "grep case sensitive $3"
				#log -c "$(ls -hlt $main_path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(INC[0-9]{8})" | egrep "$3")"
				f_ls_prototype $@
				echo
				;;
			"-n" )
				log i "crosscheck with ARS|Nikita"
				log t "$(ls -hl $main_path --color=auto --group-directories-first | grep -v ^l | grep ^d | egrep "(H2S_CUS-[0-9]{4})")"
				;;
			"-b" | "-bto" )
				log i "list back2ops issues"
				main_path=$backtoops_path
				f_ls_prototype $@
				main_path=$def_path/main
				;;
			"-d" | "--done" )
				log i "list DONE issues"
				main_path=$done_path
				f_ls_prototype $@
				main_path=$def_path/main
				;;
			"-h" )
				f_args -lh
				return
				;;
			"-pr" )
				PRgrep="___PR[0-9]{6}|___JIRA-[0-9]{1,5}"
				if [ "$#" -lt 3 ];then
					log i "Listing PRs"
					log t "$(ls -hlt --color=auto --group-directories-first $main_path | grep ^d | egrep "(INC[0-9]{8})" | egrep $(PRgrep))"
				else 
					log i "Listing pr with \"grep $3\""
					log t "$(ls -hlt --color=auto --group-directories-first $main_path | grep ^d | egrep "(INC[0-9]{8})" | egrep $(PRgrep) | grep -i $3)"
				fi
				return
				;;
			"-24" )
				if [ "$#" -lt 3 ]; then
					log i "Listing 24x7 incidents | Emergencies"
					log t "$(ls -Rhlt --color=auto --group-directories-first $_24x7_path | grep ^d | egrep "(INC[0-9]{8})")"
				else 
					log i "Listing 24x7 incidents | Emergencies with \"grep $3\""
					log t "$(ls -Rhlt --color=auto --group-directories-first $_24x7_path | grep ^d | egrep "(INC[0-9]{8})" | grep -i $3)"
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
			"--todotxt")
				log i "Listing in todotxt format"
				# case $1 in
				# 	"li" )
				# 		f_ls_prototype li --todotxt $3
				# 		;;
				# 	"ld" )
				# 		f_ls_prototype ld --todotxt $3
				# 		;;
				# 	"lh" )
				# 		f_ls_prototype lh --todotxt $3
				# 		;;
				# esac
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
		# echo "###"
		# f_wc null
	
	fi  
	} 
function f_ls_prototype() { 
	title_suffix=""
	inc_file=/tmp/inc.manage-inc
	jira_file=/tmp/jira.manage-inc
	h2s_file=/tmp/h2s.manage-inc
	log t "f_ls_prototype() - \$1=$1; \$2=$2; \$3=$3; "

	if [ "$2" == "-bto" -o "$2" == "-b" -o "$2" == "-d" -o "$2" == "--done" ]; then
		grep=$3
		if [[ $2 == "-d" ]] || [[ $2 == "--done" ]];then
			main_path=$done_path
			title_suffix="[DONE]"
		fi
	elif [[ $2 == "-s" ]];then
		grep=""
	elif [[ $2 == "--todotxt" ]];then
		todotxt="todotxt"
		if [[ $# > 2 ]];then
			grep=$3
		fi
	else
		todotxt=""
		grep=$2
	fi
	li_sort="sort -t | -k8,8 -k7,7 -k6,6 -k1,1 -k3,3"
	lj_sort="sort -t | -k7,7 -k1,1 -k3,3"
	lh_sort="sort -t | -k8,8 -k1,1 -k3,3"
	if [[ $grep != "" ]];then
		str_search="- search: ${grep}"
	fi
	case $1 in
	"ls")
		# Incidents
		f_get_support_cases $todotxt
	 	# JIRA
	 	f_get_development_cases $todotxt
	 	# H2S
	 	f_get_h2s_cases $todotxt
		echo "| Customization Support ${str_search}"
		cat $inc_file | $li_sort
    log i "Number of active #$(wc -l $inc_file)"

		echo ""
		echo "| JIRA issues / Development ${str_search}"
		cat $jira_file | $lj_sort
    log i "Number of active #$(wc -l $jira_file)"

		echo ""
		echo "| H2S's  ${str_search}"
		cat $h2s_file | $lh_sort
    log i "Number of active #$(wc -l $h2s_file)"
		;;
	"li")
		f_get_support_cases $todotxt
		[[ $2 == "-s" ]] && li_sort="sort -t | $3"
		log t "$li_sort"
					# \n$(cat $inc_file | sort --debug -k7.8nr -k7.5nr -k7.2nr -k4 -k 1,1)"
		log i "Customization Support ${title_suffix}  ${str_search}"
		cat $inc_file | $li_sort
	    log i "Number of active #$(wc -l $inc_file)"
		;;
	"lj" | "ld")
	 	f_get_development_cases $todotxt
		log i "Customization JIRA  ${str_search}"
		cat $jira_file | $lj_sort
    	log i "Number of active #$(wc -l $jira_file)"
		;;
	"lh")
	 	f_get_h2s_cases $todotxt
	 	case_count=$(wc -l $h2s_file | cut -d " " -f 1)
	 	log t "case_count: ${case_count}"
	 	log t "h2s_file: ${h2s_file}"
	 	log t "lh_sort: ${lh_sort}"
	 	if [[ ${case_count} -gt ${max_lines} ]];then
			log i "Customization H2S ${str_search}"
			cat $h2s_file | $lh_sort | more
		else
			log i "Customization H2S ${str_search}"
			cat $h2s_file | $lh_sort
		fi
    log i "Number of active #${case_count}"
		;;
	* )
		# Incidents
		f_get_support_cases $todotxt
	 	# JIRA
	 	f_get_development_cases $todotxt
	 	# H2S
	 	f_get_h2s_cases $todotxt
		log i "Customization Support  ${str_search}"
		cat $inc_file | $li_sort
		log i "JIRA issues / Development  ${str_search}"
		cat $jira_file | $lj_sort
		log i "H2S's  ${str_search}"
		cat $h2s_file | $lh_sort
		f_wc $@
		;;
	esac
	return
	} 
function f_wc() { 
	log t "f_wc(): $*"
	if [ $# -gt $EXP_ARGS ]; then
		case $2 in
			"-v")
				log i "Linecount with \"grep -vi $3\""
				log i "	...	 $(ls $main_path | egrep $INC_MATCH | grep -vi $3 | wc -l)	...	"
				;;
			"-I")
				log i "Linecount of $3"
				log i "	...	 $(ls $main_path | egrep $INC_MATCH | egrep "$3" | wc -l)	...	"
				echo
				;;
			"-d")
				log i "Linecount with \"grep $3\""
				log t "\$(ls $main_path | egrep $INC_MATCH | grep $3 | wc -l)"
				log i "	...	 $(ls $main_path | egrep $INC_MATCH | grep $3 | wc -l)	...	"
				;;
			*)
				log i "Linecount with \"grep $2\""
				log i "	...	 $(ls $main_path | egrep $INC_MATCH | grep $2 | wc -l)	...	"
				;;
		esac
	else
		# f_wc_prototype
		f_wc_prototype

	fi
	} 
function f_wc_prototype() { 

		log i "Number of CUST incidents in my queue.."
		log i "	...	$(ls $main_path | egrep "(^[0-9]{6})" | egrep "$3" | wc -l)	...	"
	
		log i "Number of JIRA issues / Development in queue.."
		log i "	...	$(ls $main_path | egrep "(CUS-[0-9]{3})" | egrep "$3" | grep -v "H2S" | wc -l)	...	"

		log i "Number of H2S in my queue.."
		log i "	...	$(ls $main_path | egrep "(H2S)" | egrep "$3" | wc -l)	...	"
	
		log i "Number of SMSC incidents in my queue.."
		log i "	...	$(ls $main_path | egrep "(INC[0-9]{7}"$delim"SMSC)|(CS[0-9]{7}"$delim"SMSC)" | egrep "$3" | wc -l)	...	"
	} 

function f_check_links() { 
	EMPTY_OUTPUT=true
	for dirname in $(ls $main_path);do
		if [[ $dirname == *"H2S"* ]];then
			if [[ ! -d $h2s_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				ln -sfn $main_path/$dirname $h2s_path/$dirname
				if [[ $? == 0 ]];then
					log i "link for $dirname successfully created"
				else
					log e "link for $dirname was not created"
				fi
			fi
		elif [[ $dirname == *"INC"* ]];then
			if [[ ! -d $inc_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				ln -sfn $main_path/$dirname $inc_path/$dirname
				if [[ $? == 0 ]];then
					log i "link for $dirname successfully created"
				else
					log e "link for $dirname was not created"
				fi
			fi
		elif [[ $dirname == *"DEV"* ]];then
			if [[ ! -d $jira_path/$dirname ]];then
			  EMPTY_OUTPUT=false
				ln -sfn $main_path/$dirname $jira_path/$dirname
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
function f_id_as_first_argument() {
	case_done=0; case_back2ops=0;
	# log "[d] NOARGS"
	f_get_inc_filter
	if [ $nlines -eq 0 ]; then
		f_get_inc_filter -d
		if [ $nlines -eq 0 ]; then
			f_get_inc_filter -b
			if [ $nlines -ne 0 ]; then
				case_back2ops=1
			fi
		else
			case_done=1
		fi
	fi
	# ls "$main_path" | grep "$id" > /dev/null 2>&1

	if [ $nlines -eq 0 ]; then
		# No incident matching criteria found - create new one
		f_get_user_consent "Case does not exist, do You want to create it?"
		f_create_new_inc
	elif [ $nlines -eq 1 ]; then
		# Incident already exists
		if [ $case_done -eq 1 ];then
			main_path=$done_path
			log w "Case is in DONE: \n${main_path}/${grepped}"
		elif [ $case_back2ops -eq 1 ];then
			main_path=$backtoops_path
			log w "Case is in BACK TO OPS: \n${main_path}/${grepped}"
		else
			log w "Case already exists: \n${main_path}/${grepped}"
		fi
		if [[ $# -gt 1 ]];then
			# Switch input arguments 1 and 2 (leave the rest intact):
			all_input_args=("$@")
			log d "f_id_as_first_argument(): \${all_input_args[*]}=${all_input_args[*]}"
			_1=$2
			_2=$1
			_args=("$_1" "$_2" "${all_input_args[@]:2}")
			log d "f_id_as_first_argument(): \${_args[*]}=${_args[*]}"
			
			# and restart f_args
			f_args "${_args[@]}"
		else
			read -p "|	Do you want to [O]pen ${id} or [r]ename it or [n]either? [O/r/n] " orn
			case $orn in
				[Nn]* ) 
					log i "User abort"
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
		fi

	elif [ -z $grepped ]; then
		# User input empty - finish with error
		log e "No ID inserted"
	else
		# User input matches multiple hits - finish with error
		log e "[e] Multiple matches, quitting.."
	fi #new/[i]rename/[e]multiple hit
	main_path=$def_path
	}
function f_todotxt() {
	# Handle todotxt task creation
	[[ -z $1 ]] || id=$1 # if $1 supplied, fill id with the value
	f_get_inc_filter
	if [[ $nlines == 0 ]];then
		log e "f_todotxt(): case with id ${id} was not found. Exit"
		return
	fi

	log t "f_todotxt(): grepped=${grepped}"
	case_arr=( $( f_parse_inc_name $grepped ) )
	log t "f_todotxt(): case_arr: ${case_arr[*]}"
	# newinc=${id}${delim}${case_type}${delim}${team}${delim}${cust}${delim}${desc// /_}
	__case_type=${case_arr[1]}; __team=${case_arr[2]}; __cust=${case_arr[3]}; __desc=${case_arr[4]}
	log t "f_todotxt(): id: ${id}, __case_type:  ${__case_type}, __team: ${__team}, __cust: ${__cust}, __desc: ${__desc}"
	if [[ -f $TODOTXT_FILE ]];then
		if [[ $(grep -re "${id}.*due:${TODOTXT_DUE_DATE}" $TODOTXT_FILE | wc -l) > 0 ]];then
			log e "f_todotxt(): ${TODOTXT_FILE} already contain task with case ID #${id} and due:${TODOTXT_DUE_DATE}"
		else
			log i "${TODOTXT_FILE} file was updated with case ID: #${id} and DUE: ${TODOTXT_DUE_DATE}"
			log t "f_todotxt(): '@${__case_type,,} +${id} ${__cust} ${__desc} due:${TODOTXT_DUE_DATE} rec:1d' >> $TODOTXT_FILE"
			echo "@${__case_type,,} +${id} ${__cust} ${__desc} due:${TODOTXT_DUE_DATE} rec:1d" >> $TODOTXT_FILE
		fi
	else
		log e "f_todotxt(): todotxt file (${TODOTXT_FILE}) does not exist"
	fi
	} # eo: f_todotxt()

### Main {{
f_s_init
if [[ $1 == "--bashcompletion" ]];then
	if [[ $2 == "inc" ]] || [[ $2 == "ops" ]];then
		if [[ $2 == "inc" ]];then
			echo "--todotxt"
		fi
		if [[ $2 == "ops" ]];then
			echo "-si"
		fi
		path_length=$(( ${#main_path} + 1 ))
		for d in $(find $main_path -type d -maxdepth 1 | grep -v "${delim}DEV${delim}"); do
			echo ${d:$path_length} | awk -F$delim '{print $1}'
		done
		unset d
	elif [[ $2 == "dev" ]];then
		echo "--todotxt"
		path_length=$(( ${#main_path} + 1 ))
		for d in $(find $main_path -type d -name "*DEV*" -maxdepth 1); do
			echo ${d:$path_length} | awk -F$delim '{print $1}'
		done
		unset d
	fi
	exit 0
fi
f_s_boc
if [ $EXP_ARGS -le $# ]; then
	f_args $@
else
	f_id_as_first_argument
fi #EXP_ARGS
# log i "$(ps -o rss=,vsz= $$ | awk '{printf "RSS %.0fMB; VSZ %.0fGB\n", $1 / 1024, $2 / (1024 * 1024)}')"
timer_end=$(date +"%s%N")
log i "$(ps -o rss= $$ | awk '{printf "MEMORY: %.0fkB\n", $1}') | TIME EXPENSE: $(( $(( $timer_end - $timer_start )) / 1000000 ))ms"
f_s_eoc
#eo:Main }}

###
#EOF
# manage incidents
CLI tool to help manage support incidents, development and Handover to Support _H2S_ tasks (investigation notes, details, etc.)

## Purpose
Keep track (locally) of all the investigation effort put into solving support, dev and h2s cases

## Usage
inc --help

## Install
+ Clone repository to ~/bin/manage-inc:
```sh
(( -d ~/bin/manage-inc )) || mkdir -p ~/bin/manage-inc
pushd ~/bin && git clone https://github.com/lanthean/manage-inc.git
popd
```
+ Compile and create link using Makefile
```sh
$ pushd ~/bin/manage-inc
$ make
```
### Alternatively (manual steps):
+ Create link to ~/bin (which should be in $PATH):
```sh
(( -f ~/bin/inc )) || ln -s ~/bin/manage-inc/inc ~/bin/
(( -f ~/bin/ticket )) || ln -s ~/bin/manage-inc/ticket ~/bin/
(( -f ~/bin/newincf )) || ln -s ~/bin/manage-inc/newincf ~/bin/
```
+ Compile inc.sh (install dependencies first)
```sh
# MAC: brew install shc
# Ubunut: apt install shc
# RHEL/Centos: yum install shc

shc -f inc.sh -o inc
```

## Change log
```
11/11/2021  -- Version 2.0.0
            -- Major update
            -- Script (inc) is now compiled
            -> + Makefile - to help with the compilation
            -- f_ls_prototype now capable of listing DONE incidents/cases
05/05/2021  -- Version 1.5.7
            -- f_ls_prototype - bugfix - if [ -f ..* ]; > if [[ -f "..*" ]];
            -- change the directory design of the tool:
            -> add folder (manage-inc) with renamed main script manage-inc > inc
            -> + add separate README.md (this file) for the solution
            -- + other changes (f_id_as_first_argument, f_open)
03/03/2021  -- Version 1.5.6
            -- f_parse_inc_name - get main variables from inc path name (e.g. id, desc)
            -- f_update_downloads_link_to_done - update link to downloads if moving incident to done
            -- f_done - include new function for link update
15/09/2020  --  Version 1.5.5
            -- f_done - default option for confirmation is now Yes (<enter> and all's done)
08/04/2020  --  Version 1.5.4.2
            -- change DATE format in new incident from %d%m%Y to %Y%m%d (user friendlier for updates in vim)
            -- update egrep of f_ls_prototype to correctly interpret the new date format
30/03/2020  --  Version 1.5.4.1
            -- help missing "done function" decription
14/01/2020  --  Version 1.5.3
            -- log function error; decimal/hex values issue - FIX
07/10/2019  --  Version 1.5.1
            -- listing only H2S or dev/assessment JIRA tasks, similar to $(inc li); $(inc lh|lj)
10/09/2019  --  Version 1.5.0
            -- bugfix - "default" command not found - now corrected
            -- logging function fixed - logging to file is enabled now
            -- + crontab installed
05/09/2019  --  Version 1.4.7
            -- logging - use generic bash functions
12/06/2019  --  Version 1.4.6
            -- f_remove_downloads_link/f_create_downloads_link added to f_rename
19/02/2019  --  Version 1.4.5
            -- f_remove_downloads_link added
11/02/2019  --  Version 1.4.4
            -- Update of printf table output. No need for --?h column => more space for longer PRI and DESC.
25/01/2019  --  Version 1.4.3
            -- Create link to ~/Downloads folder when new incident is created
25/05/2018  --  Version 1.4.2
            -- list by state 'back2ops'ed cases
            -- crosscheck via IDs - sort by ID and nothing else > bugfix
22/05/2018  --  Version 1.4.1
            -- f_check_links re-enabled
03/05/2018  --  Version 1.4.0
            -- f_ls_prototype reworked > using /tmp/*.manage-inc temporary files and sorting it based on rendered data
26/04/2018  --  Version 1.3.8
            -- newinc now incorporates creation of ticket.ntx with filling of the template
05/12/2016  --  Version 1.3.7
            -- function f_done() implemented - move DONE issues to /inc/done instead of /inc/back2ops
24/10/2016  --  Version 1.3.6
            -- function f_check_links() implemented - check if correct soft link exists for each incident (H2S, Case and JIRA issues)
18/07/2016  --  Version 1.3.5
            -- ID of incidents changed form (xura.service-now.com) - CS instead of INC
08/06/2016  -- Version 1.3.4
            -- Priority of incident moved to ticket.ntx from directory name
10/05/2016  -- Version 1.3.3
            -- Long overdue removal of SMSC Global Support residue
22/02/2016  -- Version 1.3.2
            -- implement new syntax structure of /inc/incidents/<folde_name> ./ID__TEAM__CUSTOMER__SFID__DECRIPTION__PRIORITY/
02/02/2016  -- Version 1.3.1
            -- implementing another extension (development/JIRA issues)
            -- f_ls_prototype - [EDIT] - added section "| JIRA issues / Development " ( grepping `CUS-[0-9]{3}` )
            -- f_wc_prototype - [EDIT] - added section "| JIRA issues / Development " ( grepping `CUS-[0-9]{3}` )
04/01/2016  -- Customizations Support team incidents+H2S implementation
            -- f_ls_prototype updated
            -- f_wc_prototype [NEW]
04/01/2016  -- Version 1.3.0
            -- tidy f_main() a bit
            -- f_create_new_inc [NEW]
            -- f_create_new_inc - move implementation of creating a new incident into a function
12/08/2015  -- delimiter change from "___" to "__" -> shorten filename
            -- f_ls_prototype -> incorporate STATUS from ticket.ntx file
            -- f_ls -> use only f_ls_prototype and f_wc
20/01/2015  -- f_ls_prototype 
            -> propagate to help
07/01/2015  -- f_ls_prototype 
            -> gather information about incident SLA and write it to the ls output
07/01/2015  -- f_ls_prototype 
            -> gather information about incident SLA and write it to the ls output
18/12/2014  -- enable ID as $2 to be used [rename,backtoops,return,team]
            -- update of help - list of actual extensions
            -- LOG_FILE disabled -> created as binary file -> problem with reading
02/09/2014  -- 24x7|Emergency incidents listing
09/06/2014  -- PR listing - bug repair; list all PRs and PRs with grep in $3
16/05/2014  -- call rename function from f_args
            if "-r | rename" parameter present
            -- log function syntax change -> "|" moved to declaration
05/05/2014  -- implementation of customer field
04/07/2013  -- Version 1.0.0
            -- initial version
            -- script to help handle paperwork and notes from incident management
```

## Contact me
e lanthean@protonmail.com  
g https://github.com/lanthean  
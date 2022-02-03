```
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
# @Created  27/01/2022
#
# @Package  manage-inc
###
```
# manage incidents

CLI tool to help manage support incidents, development and Handover to Support _H2S_ tasks (investigation notes, details, etc.).  
With HEAT API integration (so far support incidents are integrated - aid while creating new local support case).  

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
pushd ~/bin/manage-inc
make
```

### Alternatively (manual steps)

+ Create link to ~/bin (which should be in $PATH):
```sh
(( -f ~/bin/inc )) || ln -s ~/bin/manage-inc/inc ~/bin/
```

+ Compile inc.sh (install dependencies first)
```sh
# MAC: brew install shc
# Ubunut: apt install shc
# RHEL/Centos: yum install shc

shc -f inc.sh -o inc
```

### bash_completion.d
```sh
(( -f /etc/bash_completion.d/inc )) || ln -sf ${PWD}/bash_completion.d/inc /etc/bash_completion.d/
(( -f /etc/bash_completion.d/ops )) || ln -sf ${PWD}/bash_completion.d/ops /etc/bash_completion.d/
# macos
(( -f /opt/homebrew/etc/bash_completion.d/inc )) || ln -sf ${PWD}/bash_completion.d/inc /opt/homebrew/etc/bash_completion.d/
(( -f /opt/homebrew/etc/bash_completion.d/ops )) || ln -sf ${PWD}/bash_completion.d/ops /opt/homebrew/etc/bash_completion.d/
```

#### zsh
~/.zshrc
```sh
completion_plugins=(
  inc
  ops
)
if [[ -d /opt/homebrew/etc/bash_completion.d/ ]];then
  for f in ${completion_plugins[@]};do
    [[ -r /opt/homebrew/etc/bash_completion.d/$f ]] && source /opt/homebrew/etc/bash_completion.d/$f
  done
fi
```

## Contact me
e [lanthean@protonmail.com](mailto:lanthean@protonmail.com)  
g <https://github.com/lanthean>

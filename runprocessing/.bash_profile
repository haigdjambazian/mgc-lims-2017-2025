# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

umask 0002

## MUGQIC genomes and modules

HOST=`hostname`;

DNSDOMAIN=`dnsdomainname`;

export MUGQIC_INSTALL_HOME=/cvmfs/soft.mugqic/CentOS6

export JOB_MAIL=bravo.genome@mcgill.ca

if [[ $HOST == abacus* || $DNSDOMAIN == ferrier.genome.mcgill.ca ]]; then

  export MUGQIC_INSTALL_HOME_DEV=/lb/project/mugqic/analyste_dev
  export MUGQIC_INSTALL_HOME_PRIVATE=/lb/project/mugqic/analyste_private

fi

module use $MUGQIC_INSTALL_HOME/modulefiles $MUGQIC_INSTALL_HOME_DEV/modulefiles $MUGQIC_INSTALL_HOME_PRIVATE/modulefiles

#!/bin/bash

timeInitial=`date +%H%M%S`
installTime=$timeInitial

DEPS=(gcc tar make wget)

# FUNCTIONS
# showHelp
# Prints options to the screen
showHelp ()
{
  cat << _USAGE_
Usage: install.sh [options]
    --no-redis                      Skip the installation of the redis server.
    --offline                       Check that all necessary files are installed in /opt/rhoconnect if no prefix is specified.
    -p, --prefix PREFIX             Specify PREFIX as the installation directory.  Default is /opt/rhoconnect.
    -r, --ruby-version VERSION      Specify version of ruby to install.  Default is Ruby Enterprise.
    -s, --silent                    Perform installation with minimal output.
    --skip-ruby                     Use system ruby instead of ruby installed through this installer.
    -w, --web-server SERVER         Specify that you are using web server SERVER.  Default is Nginx.
    -h, --help                      Display this screen.
_USAGE_
  exit
}

# checkDeps
# Checks that all common dependencies are present, exits if not
checkDeps ()
{
  missingDeps=""
  for ((i=0; i<${#DEPS[@]}; i++))
  do
    dep=`which ${DEPS[$i]} 2> /dev/null`
    if [[ $dep == "" ]]; then
      missingDeps="${missingDeps}${DEPS[$i]}\n"
    fi
  done

  if [[ $missingDeps != "" ]]; then
    echo "Dependencies Missing: " | tee -a $log
    echo "${missingDeps}" | tee -a $log
    echo "These must be installed before setup can continue..." | tee -a $log
    exit 1
  fi
}

# determinePkgMgr
# Determines if the system is currently using rpm or
# debian based pckage management
determinePkgMgr ()
{
  if [[ `which apt-get 2> /dev/null` != "" ]]; then
    pkgMgr="apt-get --force-yes -y"
    dist='debian'
  elif [[ `which yum 2> /dev/null` != "" ]]; then
    pkgMgr="yum -y"
    dist='yum'
  else
    echo "No supported package manager." | tee -a $log
    echo "Please install apt-get or yum to continue..." | tee -a $log
    exit 1
  fi
}

# parseOpts
# Parses options passed to the install script
parseOpts ()
{
  for i in "$*"; do
    i=$(echo $i | tr '[:upper:]' '[:lower:]')
    opts="${opts}${i} "
    # looking for getVal flag to grab next value.
    case $getVal in
    "p" )
      prefix=$i
      ;;
    "w" )
      webServer=$i
      ;;
    "r" )
      rubyVersion=$i
      ;;
    * )
      ;;
    esac

    # Check options passed in and assign flags where applicable
    case $i in
    --web-server | -w )
      getVal="w"
      ;;
    --prefix | -p )
      getVal="p"
      ;;
    --ruby-version )
      getVal="r"
      ;;
    --offline )
      ;;
    --silent | -s )
      ;;
    --skip-redis )
      redis=false
      ;;
    --skip-ruby )
      ruby=false
      ;;
    --help | -h )
      showHelp
      ;;
    * )
      #if [ "${i}" ]; then
      #  echo "${i} is not a valid option" | tee -a $log
      #  exit
      #fi
      ;;
    esac
  done
}

cleanPrefix ()
{
  # make sure there are no double /'s in the prefix path
  prefix=${prefix/\/\/+/"/"}

  # make sure path is absolute for ruby EE installation
  if [[ $prefix == *\.* ]]; then
    prefix=${prefix/\./`pwd`}
  fi

  # make sure prefix exists, create if not
  if ! [ -d $prefix ]; then
    mkdir -p $prefix
  fi
}

setPrefixDependantPaths ()
{
  # if rubyBinDir not specified
  if [$rubyBinDir == ""]; then
    rubyBinDir="${prefix}/ruby/bin"
  fi

  # If logs directory does not exist, create it
  if ! [[ -d "${prefix}/logs/" ]]; then
    mkdir "${prefix}/logs/"
  fi

  # Make path to log file absolute and create directory if not already existent
  log="${prefix}/logs/${log}"
  touch $log > /dev/null
}

setDefaults ()
{
  # if $prefix not specified set to /opt/rhoconnect
  if [$prefix == ""]; then
    prefix="/opt/rhoconnect"
  fi

  # if $webServer not specified set to nginx
  if [$webServer == ""]; then
    webServer="nginx"
  fi
}

setRubyVars ()
{
  # RUBY_VERSION="ruby-2.2.1"
  rubyVersion=${RUBY_VERSION}
  rubyDir=${RUBY_VERSION}
  rubyTar="${rubyDir}.tar.gz"
  # http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.1.tar.gz
  rubyURL="http://cache.ruby-lang.org/pub/ruby/2.2/${rubyTar}"
}

installRuby ()
{
  if [[ ! -d "${prefix}${rubyDir}" ]]; then
    echo "Downloading ${rubyURL} ..." | tee -a $log
    echo "wget -P ${prefix} ${rubyURL}" >> $log
    wget -P ${prefix} ${rubyURL} -o /dev/null
    if (($?)) ; then
      echo "Failed to download ruby tarball: ${rubyURL}\n" | tee -a $log
      echo "Installation terminated. For troubleshooting see file $log ..." | tee -a $log
      exit 1
    fi
    echo "tar -xzf ${prefix}/${rubyTar} -C ${prefix}" >> $log
    tar -xzf ${prefix}/${rubyTar} -C ${prefix} > /dev/null 2>&1
  fi

  echo "Installing ruby. This may take some time..." | tee -a $log
  echo "pushd ${prefix}/${rubyDir}" | tee -a $log
  pushd ${prefix}/${rubyDir}
  echo "./configure --prefix=${prefix} --enable-shared --disable-install-doc" | tee -a $log
  ./configure --prefix=${prefix} --enable-shared --disable-install-doc >> $log 2>&1
  echo "make && make install" | tee -a $log
  make >> $log 2>&1
  make install >> $log 2>&1

  if (( $? )) ; then
    echo "Some dependencies not installed..." | tee -a $log
    echo "Please install them and then re-run the installation script." | tee -a $log
    echo "For troubleshooting see file $log ..." | tee -a $log
    exit 1
  fi

  popd
  echo -e "$rubyDir is successfully installed.\n" | tee -a $log
}

# SCRIPT

# define log file name
DATEFILE=`date +%Y%m%d%H%M%S`
log=rhoconnect_$(date +$DATEFILE).log

# make sure only run as root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" | tee -a $log
  exit 1
fi

# Check if web server is running on port 80
if [[ `echo "close" | telnet localhost 80 2>&1 | grep "Connected"` ]]; then
  echo "Web server on port 80 is running." | tee -a $log
  echo "Please stop it and then re-run the installation script." | tee -a $log
  exit 1
fi

# Get starting directory
PWD=`pwd`
if [[ $PWD = "/opt/rhoconnect/installer" ]]; then
  INSTALL_DIR=$PWD
else
  INSTALL_DIR="./installer"
fi

# Make sure basic system dependencies are installed
checkDeps

# Determine which package management the system uses (Debian short-circuted)
determinePkgMgr

# define option variables
opts=""
prefix=""
getVal=""
webServer=""
rubyVersion=""
rubyBinDir=""

# Define ruby and nodejs versions to be installed ...
RUBY_PATCH="p85"
RUBY_VERSION="ruby-2.2.1"

NODE_VERSION=v0.10.33
NODE_URL=http://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz
ARCH=$([[ `uname -m` == x86_64 ]] && echo "x64" || echo "x86")
NODE_BIN_URL=http://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.gz

# parse command-line options
parseOpts "$*"

# Set default Values
setDefaults

# Reformat ruby version to fit this scripts format
# Tolower rubyVersion
rubyVersion=$(echo $rubyVersion | tr '[:upper:]' '[:lower:]')
# Remove all white space
rubyVersion=${rubyVersion//[[:space:]]}
# Remove periods and hyphens such as those present in version numbers
rubyVersion=${rubyVersion//[-.]/}

# Set ruby insatallation variables
setRubyVars

# Clean up the formatting of prefix
cleanPrefix

# Once the prefix path is cleaned up...
setPrefixDependantPaths

if [[ -e ${prefix}/bin/ruby && `${prefix}/bin/ruby -v | awk '{ print $2}'` =~ ${RUBY_PATCH} ]]; then
  echo "${RUBY_VERSION} already installed" | tee -a $log
else
  installRuby
fi

# Install redis, sqllite3, nginx, rhoconnect
opts=" -d $dist -l $log"
${prefix}/bin/ruby ${INSTALL_DIR}/unix-like/rhoinstaller.rb ${opts}
if (( $? )) ; then
  echo "Installation failed. For troubleshooting see file $log ..." | tee -a $log
  exit 1
fi


##################################################################################
# Install nodejs
echo
echo "Downloading ${NODE_URL} file ..." | tee -a $log
wget ${NODE_URL} -O node-${NODE_VERSION}.tar.gz -o /dev/null
tar -xzf node-${NODE_VERSION}.tar.gz > /dev/null 2>&1

echo "Building nodejs $NODE_VERSION ..."  | tee -a $log
cd node-${NODE_VERSION}/
# Cent OS/RHEL 5 requires python 2.6
export PYTHON=`which python26 2> /dev/null`
$PYTHON ./configure --prefix=$prefix  >> $log 2>&1
make >> $log 2>&1
make install >> $log 2>&1
if [[ $? != 0 ]]; then
  echo "Installation of nodejs $NODE_VERSION  is failed. For troubleshooting see file $log ..." | tee -a $log
  exit
fi
cd ../
rm node-${NODE_VERSION}.tar.gz
rm -rf node-${NODE_VERSION}/

echo "nodejs $NODE_VERSION is successfully installed"  | tee -a $log
echo

# TODO:
# if [ -e /etc/redhat-release ] ; then
#   grep '5\.[0-9]\{1,2\}' /etc/redhat-release > /dev/null
#   CentOS5=$?
# else
#   CentOS5=1
# fi
# if [ $CentOS5 -eq 0 ] ; then
#   echo "CentOS 5.x is found ..."
#   echo "Downloading ${NODE_URL} source file ..." | tee -a $log
#   wget ${NODE_URL} -O node-${NODE_VERSION}.tar.gz -o /dev/null
#   tar -xzf node-${NODE_VERSION}.tar.gz > /dev/null 2>&1
#   echo "Building nodejs $NODE_VERSION ..."  | tee -a $log
#   cd node-${NODE_VERSION}/
#   # Cent OS/RHEL 5 requires python 2.6
#   export PYTHON=`which python26 2> /dev/null`
#   $PYTHON ./configure --prefix=$prefix  >> $log 2>&1
#   make >> $log 2>&1
#   make install >> $log 2>&1
#   if [[ $? != 0 ]]; then
#     echo "Installation of nodejs $NODE_VERSION  is failed. For troubleshooting see file $log ..." | tee -a $log
#     exit
#   fi
#   cd ../
#   rm node-${NODE_VERSION}.tar.gz
#   rm -rf node-${NODE_VERSION}/
# else
#   echo "Downloading ${NODE_BIN_URL} linux binary file ..." | tee -a $log
#   wget ${NODE_BIN_URL} -O node-${NODE_VERSION}-linux-${ARCH}.tar.gz -o /dev/null
#   path=`pwd`
#   pushd ${prefix}
#   tar xzf ${path}/node-${NODE_VERSION}-linux-${ARCH}.tar.gz --strip=1 > /dev/null 2>&1
#   popd
# fi
# echo "nodejs $NODE_VERSION is successfully installed"  | tee -a $log
#

##################################################################################

# Create configuration scripts for redis, nginx, thin.
${prefix}/bin/ruby ${INSTALL_DIR}/unix-like/create_texts.rb ${opts}

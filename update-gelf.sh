#!/bin/bash

#Author: Edward De Faria <edward.de-faria@ovh.net>
if [ -z "$LOGSTASH_HOME" ] ; then
  export LOGSTASH_HOME=/opt/logstash
fi
export GEM_HOME=vendor/bundle/jruby/1.9
export GEM_PATH=$GEN_HOME
export USE_JRUBY=1

GIT_PULL=1

gem_list () {
  pushd $LOGSTASH_HOME
  if [ -d "vendor/jar" ] ; then
    local vendor_path=$(find vendor/jar -iname jruby-complete*.jar)
    java -jar $vendor_path -S gem list -i $GEM_HOM
  elif [ -d "vendor/jruby" ] ; then
    ./vendor/jruby/bin/jruby -S gem list
  else
    echo "Error: jruby dependancy missing!"
  fi
  popd
}

gem_update () {
  local home=$1
  local gem_name=$2
  local git_clone_params=$3
  local version=$4
  if [ ! -d "$home" ] ; then
    cd $(dirname $home)
    echo "exec in $PWD: git clone $git_clone_params $(basename $home)"
    git clone $git_clone_params $(basename $home) || { echo "git clone failed" ; exit 1 ; }
    cd $home
  else
    cd $home
    [ "$GIT_PULL" == "1" ] && { echo "exec in $PWD: git pull origin master" ; git pull origin master  || { echo "git pull failed" ; exit 1 ; } ; }
  fi
  if [ -z "$version" ] ; then
    if [ -f "$home/VERSION" ] ; then
      local version=$(cat $home/VERSION)
    else 
      local $(grep 's\.version' $gem_name.gemspec |tr -d ' ' |sed -e 's/s\.version/version/' -e "s/'//g" -e 's/"//g')
    fi
  else
    [ -f $home/VERSION ] && echo $version > $home/VERSION
    sed -i "s/\(s\.version .*= \).*/\1'$version'/g" $gem_name.gemspec || { echo "version modification failed on filed $PWD/$gem_name.gemspec" ; exit 1 ; }
  fi
  if which gem 2>1 >/dev/null ; then
    local gem_cmd="gem"
  elif [ -x "$LOGSTASH_HOME/vendor/jruby/bin/gem" ] ; then
    local gem_cmd="$LOGSTASH_HOME/vendor/jruby/bin/gem"
  else
    echo "command gem not found! Please install gem package!"
    exit 1
  fi
  echo "exec in $PWD: $gem_cmd build $gem_name.gemspec"
  $gem_cmd build $gem_name.gemspec
  cd $LOGSTASH_HOME
  local action=install
  if [ -d "vendor/jar" ] ; then
    local vendor_path=$(find vendor/jar -iname jruby-complete*.jar)
    echo "exec in $PWD: java -jar $vendor_path -S gem $action -i $GEM_HOME $home/$gem_name-$version.gem"
    java -jar $vendor_path -S gem $action -i $GEM_HOME $home/$gem_name-$version.gem || { echo "gem install failed" ; exit 1 ; }
  elif [ -d "vendor/jruby" ] ; then
    echo "exec in $PWD: ./vendor/jruby/bin/jruby -S gem $action $home/$gem_name-$version.gem"
    ./vendor/jruby/bin/jruby -S gem $action $home/$gem_name-$version.gem || { echo "gem install failed" ; exit 1 ; }
  else
    echo "Error: jruby dependancy missing!"
    exit 1
  fi 
}

# Install gelf-rb patched
gem_update /opt/gelf-rb gelf "-b feature/tcp-tls --single-branch https://github.com/edefaria/gelf-rb.git" 1.3.2

# Install logstash plugin output gelf patched
gem_update /opt/logstash-output-gelf logstash-output-gelf "-b feature/tcp-tls --single-branch https://github.com/edefaria/logstash-output-gelf.git"

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
  pushd $LOGSTASH_HOME > /dev/null
  if [ -d "vendor/jar" ] ; then
    local vendor_path=$(find vendor/jar -iname jruby-complete*.jar)
    java -jar $vendor_path -S gem list -i $GEM_HOM
  elif [ -d "vendor/jruby" ] ; then
    ./vendor/jruby/bin/jruby -S gem list
  else
    echo "Error: jruby dependancy missing!"
  fi
  popd > /dev/null
}

rake_update () {
  pushd $LOGSTASH_HOME
  if [ -f "Rakefile" ] ; then
    echo "exec in $PWD: rake vendor:gems"
    rake vendor:gems
  else
    echo "no source for rake update found."
  fi
  popd
}

git_check () {
  local home="$1"
  local gem_name="$2"
  local git_clone_params="$3"
  if [ ! -d "$home" ] ; then
    cd $(dirname $home)
    echo "exec in $PWD: git clone $git_clone_params $(basename $home)"
    git clone $git_clone_params "$(basename $home)" || { echo "git clone failed" ; exit 1 ; }
    cd $home
  else
    cd $home
    [ "$GIT_PULL" == "1" ] && { echo "exec in $PWD: git pull origin master" ; git pull origin master  || { echo "git pull failed" ; exit 1 ; } ; }
  fi
}

gem_version () {
  local home=$1
  local gem_name=$2
  local version=$3
  if [ -z "$version" ] ; then
    if [ -f "$home/VERSION" ] ; then
      local version=$(cat $home/VERSION)
    else
      local $(grep 's\.version' $gem_name.gemspec |tr -d ' ' |sed -e 's/s\.version/version/' -e "s/'//g" -e 's/"//g')
    fi
  else
    [ -f "$home/VERSION" ] && echo $version > $home/VERSION
    sed -i "s/\(s\.version .*= \).*/\1'$version'/g" $gem_name.gemspec >/dev/null 2>/dev/null || { echo "version modification failed on filed $PWD/$gem_name.gemspec" ; exit 1 ; }
  fi
  echo $version
}

gem_build () {
  local home="$1"
  local gem_name="$2"
  local version="$3"
  cd $home
  if which gem 2>1 >/dev/null ; then
    local gem_cmd="gem"
  elif [ -x "/usr/bin/gem" ] ; then
    local gem_cmd="/usr/bin/gem"
  elif [ -x "$LOGSTASH_HOME/vendor/jruby/bin/gem" ] ; then
    local gem_cmd="$LOGSTASH_HOME/vendor/jruby/bin/gem"
    echo "please install gem command"
    exit 1
  else
    echo "command gem not found! Please install gem package!"
    exit 1
  fi
  echo "exec in $PWD: $gem_cmd build $gem_name.gemspec"
  $gem_cmd build $gem_name.gemspec
}

plugin_install () {
  local home="$1"
  local gem_name="$2"
  local git_clone_params="$3"
  local action="$4"
  git_check "$home" "$gem_name" "$git_clone_params"
  version=$(gem_version "$home" "$gem_name" "$version")
  gem_build "$home" "$gem_name" "$version"
  cd $LOGSTASH_HOME
  [ -z $action ] && local action=install
  if [ -x "bin/plugin" ] ; then
    echo "exec in $PWD: ( bin/plugin $action $home/$gem_name-$version.gem )"
    bin/plugin $action $home/$gem_name-$version.gem
  else
    echo "Error: plugin exec missing!"
    exit 1
  fi
}

plugin_update () {
  local home="$1"
  local gem_name="$2"
  local git_clone_params="$3"
  local version="$4"
  version=$(gem_version "$home" "$gem_name" "$version")
  plugin_install "$home" "$gem_name" "$git_clone_params" "update"
}

gem_update () {
  local home="$1"
  local gem_name="$2"
  local git_clone_params="$3"
  local version="$4"
  git_check "$home" "$gem_name" "$git_clone_params"
  version=$(gem_version "$home" "$gem_name" "$version")
  gem_build "$home" "$gem_name" "$version"
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

# Update Logstash dependencies
rake_update

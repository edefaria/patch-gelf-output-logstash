#!/bin/bash

#Author: Edward De Faria <edward.de-faria@ovh.net>
if [ -z "$LOGSTASH_HOME" ] ; then
  export LOGSTASH_HOME=/opt/logstash
fi
export GEM_HOME=vendor/bundle/jruby/1.9
export GEM_PATH=$GEN_HOME
export USE_JRUBY=1

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
  pushd $LOGSTASH_HOME > /dev/null
  if [ -f "Rakefile" ] ; then
    echo "exec in $PWD: rake vendor:gems"
    rake vendor:gems
  else
    echo "logstash package installation found, skipping rake"
  fi
  popd > /dev/null
}

plugin_uninstall () {
  local gem_name="$1"
  local action="$2"
  cd $LOGSTASH_HOME
  [ -z "$action" ] && local action=uninstall
  if [ -x "bin/plugin" ] ; then
    echo "exec in $PWD: ( bin/plugin $action $gem_name )"
    bin/plugin $action $gem_name
  else
    echo "Error: plugin exec missing!"
    exit 1
  fi
}

gem_uninstall () {
  local home="$1"
  local gem_name="$2"
  cd $LOGSTASH_HOME
  local action=uninstall
  if [ -d "vendor/jar" ] ; then
    local vendor_path=$(find vendor/jar -iname jruby-complete*.jar)
    echo "exec in $PWD: java -jar $vendor_path -S gem $action -i $GEM_HOME $gem_name"
    java -jar $vendor_path -S gem $action -i $GEM_HOME $gem_name || { echo "gem install failed" ; exit 1 ; }
  elif [ -d "vendor/jruby" ] ; then
    echo "exec in $PWD: ./vendor/jruby/bin/jruby -S gem $action $gem_name"
    ./vendor/jruby/bin/jruby -S gem $action $gem_name || { echo "gem install failed" ; exit 1 ; }
  else
    echo "Error: jruby dependancy missing!"
    exit 1
  fi
}

# Uninstall some logstash plugin
for plugin in logstash-input-exec logstash-output-exec logstash-input-file logstash-output-file logstash-input-pipe logstash-output-pipe logstash-input-unix logstash-filter-ruby
do
  plugin_uninstall $plugin
done

# patch logstash 1.5.0
Bash script to patch logsrash 1.5.0 to add tcp/tls output gelf support.

To use it:

    $ cd /opt/logstash
    $ git clone https://github.com/edefaria/patch-logstash.git patch
    $ bash patch/update-gelf.sh

If your logstash installation differs from "/opt/logstash", please set ENV variable LOGSTASH_HOME or modify this variable in the begin of the sript

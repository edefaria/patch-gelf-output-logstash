# patch logstash 1.5.X
Bash script to patch logsrash 1.5.X to add tcp/tls output gelf support.

To use it:

    $ cd /opt/logstash
    $ git clone https://github.com/edefaria/patch-logstash.git patch
    $ bash patch/update-gelf.sh

If your logstash installation differs from "/opt/logstash", please set ENV variable LOGSTASH_HOME or modify this variable in the begin of the script.

Example:
logstash output configuration with gelf (TCP/TLS)

    output {
      gelf {
         host => "localhost"
         port => "12202"
         protocol => "tcp"
         tls => "true"
       }
    }

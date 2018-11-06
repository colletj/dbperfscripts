#! /bin/bash 
#
# Usage: 
# bench_suite.sh 


usage="./bench_suite.sh OPTIONS 

with OPTIONS
    -h show this help text
    -p db password
    -u db user
"

while getopts 'hp:u:' opt; do
  case "$opt" in
    h) echo "$usage"
       exit
       ;;
    p) dbtestpwd=$OPTARG
       ;;
    u) dbtestusr=$OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

mysqlshow -u"$dbtestusr" -p"$dbtestpwd" | grep -Eo "sbtest" > /dev/null;
if [ $? -eq 1 ]; 
then
  echo "Database sbtest not found. Creation in progress..."
  mysqladmin -u"$dbtestusr" -p"$dbtestpwd" create sbtest -f 2&>1 /dev/null ; echo $?
else
  echo "Database sbtest found."
  #echo "Reset sbtable1..."
  #mysqladmin -u"$dbtestusr" -p"$dbtestpwd" drop sbtest -f 2&>1 /dev/null ; echo $?
  #mysql -u"$dbtestusr" -p"$dbtestpwd" -D'sbtest' -e "drop table sbtest1"
fi

# prepare RW benchmark 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --threads=4 --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd"  --table-size=1000000 prepare 

# run it
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --threads=4 --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size=1000000 run 

# clean up
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --threads=4 --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size=1000000 cleanup 

exit

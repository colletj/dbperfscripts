#! /bin/bash 
#
# Usage: 
# bench_suite.sh 


usage="./bench_suite.sh OPTIONS 

with OPTIONS
    -h show this help text
    -p db password
    -u db user
    -t benchmark table size
    -T number of parallel thread
"

#Default values:
threadnum=8;
tablesize=5000;

while getopts 'hp:u:t:T:' opt; do
  case "$opt" in
    h) echo "$usage"
       exit
       ;;
    p) dbtestpwd=$OPTARG
       ;;
    u) dbtestusr=$OPTARG
       ;;
    t) tablesize=$OPTARG
       ;;
    T) threadnum=$OPTARG
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

if [[ -z $dbtestpwd || -z $dbtestusr ]]; then echo "No db credentials provided. Exiting..."; exit; fi

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

echo "RW benchmark"
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd"  --table-size="$tablesize" prepare 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --time=40 --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" run 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_read_write.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" cleanup 

echo "Select random points benchmark"
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/select_random_points.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd"  --table-size="$tablesize" prepare 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/select_random_points.lua  --time=40 --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" run 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/select_random_points.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" cleanup 

echo "Select random points benchmark"
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_write_only.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd"  --table-size="$tablesize" prepare 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_write_only.lua  --time=40 --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" run 
/usr/bin/time -f "performed in: %e secs\nCPU: %P" sysbench /usr/share/sysbench/oltp_write_only.lua --threads="$threadnum" --mysql-host=127.0.0.1 --db-driver=mysql --mysql-user="$dbtestusr" --mysql-password="$dbtestpwd" --table-size="$tablesize" cleanup 



exit

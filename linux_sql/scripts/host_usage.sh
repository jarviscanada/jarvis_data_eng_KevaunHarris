psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

vmstat_mb=$(vmstat --unit M)
vmstat_disk=$(vmstat --unit M -d)
vmstat_cpu=$(vmstat -t)
hostname=$(hostname -f)

memory_free=$(echo "$vmstat_mb" | awk '{print $4}'| tail -n1 | xargs)
cpu_idle=$(echo "$vmstat_cpu" | tail -1 | awk -v col="15" '{print $col}')
cpu_kernel=$(echo "$vmstat_cpu" | tail -1 | awk -v col="14" '{print $col}')
disk_io=$(echo "$vmstat_disk" | tail -1 | awk -v col="10" '{print $col}')
disk_available=$(df -BM / | tail -1 | awk -v col="4" '{print substr($col,1, length($col)-1)}')
timestamp=$(date +"%Y-%m-%d %T")

host_id="
(SELECT 
	id 
FROM host_info 
WHERE 
	hostname='$hostname')"

insert_stmt="
INSERT INTO 
	host_usage(timestamp,host_id,memory_free,cpu_idle,cpu_kernel,disk_io,disk_available) 
VALUES
	('$timestamp', $host_id, '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available');" 

export PGPASSWORD=$psql_password 
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?

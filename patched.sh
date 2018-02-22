#!/bin/sh

for wm in 4 8 16 32 64 128 256 512 1024; do

	for sel in 0.01 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0; do

		echo "
set enable_nestloop = off;
set enable_mergejoin = off;
set max_parallel_workers_per_gather = 0;
set work_mem = '${wm}MB';
set enable_hashjoin_bloom = on;
set force_hashjoin_bloom = on;

explain analyze select count(*) from fact join dim on (dim.a = fact.a and dim.b < $sel);" > q.sql 2>&1

		psql test < q.sql > q.log 2>&1

		b=`cat q.log | grep Batches | awk '{print $4 ";" $7}'`
		c=`cat q.log | grep Bloom | awk '{print $4 ";" $6 ";" $8 ";" $10 ";" $13}'`

		t="$wm;$b;$c;$sel"

		for r in `seq 1 5`; do

			if [ -f "stop" ]; then
				exit
			fi

			s=`psql test -t -A -c "SELECT EXTRACT(epoch FROM now())"`

			psql test -t -A > /dev/null 2>&1 <<EOF
set enable_nestloop = off;
set enable_mergejoin = off;
set max_parallel_workers_per_gather = 0;
set work_mem = '${wm}MB';
set enable_hashjoin_bloom = on;
set force_hashjoin_bloom = on;

\o /dev/null

select count(*) from fact join dim on (dim.a = fact.a and dim.b < $sel);
EOF

			e=`psql test -t -A -c "SELECT (1000*(EXTRACT(epoch FROM now()) - $s))::bigint"`

			echo "$t;$e"

		done

	done

done

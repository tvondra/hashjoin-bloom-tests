\set m 1000000
\set n 20000000

create table dim (a int, b float, c text);
create table fact (a int, b float, c text);

set work_mem='1GB';

insert into dim select i, random(), md5(i::text) from generate_series(1,:m) s(i);

insert into fact select mod(i,:m)+1, random(), md5(i::text) from generate_series(1,:n) s(i);

vacuum freeze;
analyze;
checkpoint;

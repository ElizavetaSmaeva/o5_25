----количество поездок в час (загруженность)----
--такси
select 
    extract(hour from start_time) as hour_of_day,
    count(*) as taxi_count
from 
    test.taxi
group by 
    extract(hour from start_time)
order by 
    hour_of_day;

--велосипеды
select 
    extract(hour from time_start) as hour_of_day,
    count(*) as bike_count
from 
    test.bike
group by 
    extract(hour from time_start)
order by 
    hour_of_day;


--общее (с процентным соотношением)
with taxi_hours as (
    select 
        extract(hour from start_time) as hour_of_day,
        count(*) as taxi_count
    from 
        test.taxi
    group by 
        extract(hour from start_time)
),
bike_hours as (
    select 
        extract(hour from time_start) as hour_of_day,
        count(*) as bike_count
    from 
        test.bike
    group by 
        extract(hour from time_start)
),
combined_hours as (
    select 
        coalesce(t.hour_of_day, b.hour_of_day) as hour_of_day,
        coalesce(t.taxi_count, 0) as taxi_count,
        coalesce(b.bike_count, 0) as bike_count
    from 
        taxi_hours t
    full outer join 
        bike_hours b on t.hour_of_day = b.hour_of_day
),
total_counts as (
    select
        sum(taxi_count) as total_taxi,
        sum(bike_count) as total_bike
    from
        combined_hours
)
select 
    ch.hour_of_day,
    ch.taxi_count,
    ch.bike_count,
    round((ch.taxi_count * 100.0) / nullif(tc.total_taxi, 0), 2) as taxi_percentage,
    round((ch.bike_count * 100.0) / nullif(tc.total_bike, 0), 2) as bike_percentage
from 
    combined_hours ch
cross join
    total_counts tc
order by 
    ch.hour_of_day;

----сравнение активности по дням недели (день-количество)----
with dailyrides as (
    select
        case extract(dow from start_time)
            when 0 then 'sunday'
            when 1 then 'monday'
            when 2 then 'tuesday'
            when 3 then 'wednesday'
            when 4 then 'thursday'
            when 5 then 'friday'
            when 6 then 'saturday'
        end as day_name,
        count(*) as total_rides
    from
        test.taxi
    group by
        extract(dow from start_time),
        day_name
)
select
    day_name,
    total_rides,
    round((total_rides * 100.0 / (select sum(total_rides) from dailyrides)), 2) as percentage_of_total
from
    dailyrides
order by
    case day_name
        when 'sunday' then 0
        when 'monday' then 1
        when 'tuesday' then 2
        when 'wednesday' then 3
        when 'thursday' then 4
        when 'friday' then 5
        when 'saturday' then 6
    end;

----станции с наибольшим оборотом велосипедов (станция-прибывшие-отбывшие)----
with station_stats as (
    select 
        start_station_name as station,
        count(*) as departures,
        (select count(*) from test.bike where end_station_name = b.start_station_name) as arrivals
    from test.bike b
    group by start_station_name
)
select 
    station,
    departures,
    arrivals
from station_stats
limit 20;

----станции с наименьшим оборотом велосипедов (станиця-прибывшие-отбывшие)----
with station_stats as (
    select 
        start_station_name as station,
        count(*) as departures,
        (select count(*) from test.bike where end_station_name = b.start_station_name) as arrivals
    from test.bike b
    group by start_station_name
)
select 
    station,
    departures,
    arrivals
from station_stats
order by abs(departures + arrivals)
limit 20;

----топ-10 велосипедных маршрутов----
select 
    start_station_name,
    end_station_name,
    count(*) as trip_count,
    avg(duration) as avg_duration
from test.bike
group by start_station_name, end_station_name
order by trip_count desc
limit 10;

----топ-10 непопулярных велосипедных маршрутов----
select 
    start_station_name,
    end_station_name,
    count(*) as trip_count,
    avg(duration) as avg_duration
from test.bike
group by start_station_name, end_station_name
order by trip_count 
limit 10;

-----средняя цена поездки в зависимости от времени----
select
    extract(hour from start_time) as hour_of_day,
    avg(total_amount) as average_price,
from
    test.taxi
group by
    hour_of_day
order by
    hour_of_day;

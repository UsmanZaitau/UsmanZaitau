explain
with teachers_cost as
(
select id_teacher, 
case when language_group = 'rus' then 900 else 1500 end as class_cost
from skyeng_db.teachers
)
-- , class_data as
-- (
-- select distinct user_id, class_start_datetime, class_end_datetime, id_teacher, 
-- id_class, class_status, class_type
-- from skyeng_db.classes
-- )

select date_trunc('month', class_start_datetime) as class_month,
sum(class_cost) as total_classes_cost, count(id_class) as classes_count,
sum(class_cost)::float / count(id_class) as avg_cost
from skyeng_db.classes class_data
left join teachers_cost
on teachers_cost.id_teacher = class_data.id_teacher
where class_status in ('success', 'failed_by_teacher') -- урок списан с баланса
-- and class_start_datetime >= '2016-01-01'::timestamp
-- and class_start_datetime < '2017-01-01'::timestamp
and extract (year from class_start_datetime) = 2016 -- в 2016 году
and class_type != 'trial' -- не вводный урок
group by 1
order by 1

--  Проверка необходимости distinct
select count (id_teacher), count (distinct id_teacher)
from skyeng_db.teachers

-- Sort (cost=6622.16..6622.66 rows=200 width=32) стоимость первоначального запроса
-- GroupAggregate (cost=2260.44..2267.02 rows=188 width=32) после оптимизации
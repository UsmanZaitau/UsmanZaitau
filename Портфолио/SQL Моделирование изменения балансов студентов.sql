with first_payments as ( --Шаг 1 
select
    user_id
   ,date_trunc ('day' , min (transaction_datetime)) as first_payment_date
from skyeng_db.payments
where status_name = 'success'
group by user_id
order by first_payment_date
),

all_dates as ( --Шаг 2
select 
    distinct date_trunc ('day' , class_start_datetime) as dt
from skyeng_db.classes
where class_start_datetime < '2017-01-01'
),

all_dates_by_user as ( --Шаг 3
select 
    user_id
   ,dt
from first_payments
join all_dates
on dt >= first_payment_date
),

payments_by_dates as ( --Шаг 4 
select
    user_id
   ,date_trunc ('day' , transaction_datetime) as payment_date
   ,sum (classes) as transaction_balance_change
from skyeng_db.payments
where status_name = 'success'
group by user_id, payment_date
),

payments_by_dates_cumsum as ( --Шаг 5 
select
    a.user_id
   ,dt
   ,coalesce (transaction_balance_change, 0) as transaction_balance_change
   ,sum (transaction_balance_change) over (partition by a.user_id order by dt) as transaction_balance_change_cs
from all_dates_by_user a
left join payments_by_dates p 
on a.user_id = p.user_id
and dt = payment_date
),

classes_by_dates as ( --Шаг 6
select
    user_id
   ,date_trunc ('day' , class_start_datetime) as class_date
   ,count (id_class)*-1 as classes
from skyeng_db.classes
where class_type <> 'trial' 
and class_status in ('success' , 'failed_by_student')
group by user_id, class_date
),

classes_by_dates_dates_cumsum as ( --Шаг 7 
select
    a.user_id
   ,dt
   ,coalesce (classes, 0) as classes
   ,sum (classes) over (partition by a.user_id order by dt) as classes_cs
from all_dates_by_user a
left join classes_by_dates c 
on a.user_id = c.user_id
and dt = class_date
),

balances as ( --Шаг 8
select
    pc.user_id
   ,pc.dt
   ,transaction_balance_change
   ,transaction_balance_change_cs
   ,classes
   ,classes_cs
   ,classes_cs - transaction_balance_change_cs as balance
from payments_by_dates_cumsum pc
join classes_by_dates_dates_cumsum cc
using (user_id, dt)
)

select *
from balances
order by user_id ,dt
limit 1000

-- select dt
--     ,sum (transaction_balance_change) as transaction_balance_change
--     ,sum (transaction_balance_change_cs) as transaction_balance_change_cs
--     ,sum (classes) as classes
--     ,sum (classes_cs) as classes_cs
--     ,sum (balance) as balance
-- from balances
-- group by dt
-- order by dt
    
    
    
-- select *
-- from classes_by_dates_dates_cumsum

-- select *
-- from payments_by_dates_cumsum




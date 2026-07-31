with monthly as (

    select * from {{ ref('seller_monthly_activity') }}

),

-- 1. cohorte de cada seller = mes de su primera venta
seller_cohort as (

    select
        seller_id,
        min(order_month) as cohort_month
    from monthly
    group by seller_id

),

-- 2. cada mes activo del seller + su cohorte + tenure
activity_with_cohort as (

    select
        m.seller_id,
        c.cohort_month,
        m.order_month,
        date_diff(m.order_month, c.cohort_month, month) + 1 as tenure,
        m.revenue
    from monthly m
    inner join seller_cohort c
        on m.seller_id = c.seller_id

),

-- 3. retención: cuántos sellers activos por cohorte y tenure
cohort_retention as (

    select
        cohort_month,
        order_month,
        tenure,
        count(distinct seller_id) as n_active_sellers,
        round(sum(revenue), 2)              as cohort_revenue
    from activity_with_cohort
    group by cohort_month, order_month, tenure

)

select * from cohort_retention
order by order_month, cohort_month, tenure
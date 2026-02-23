final as (
    select *
    from (
        select
            p.conversation_id,
            p.contact_id,
            p.latest_tag_time,
            p.tags_applied,

            ct.vulcan_id,
            ct.phone,
            ct.email,
            ct.surplus,
            ct.vulcan_surplus,
            ct.total_unsecured_debt_vsapi,
            ct.total_debt,

            -- count how many contact fields are populated
            (
                (case when ct.email is not null then 1 else 0 end) +
                (case when ct.surplus is not null then 1 else 0 end) +
                (case when ct.vulcan_surplus is not null then 1 else 0 end) +
                (case when ct.total_unsecured_debt_vsapi is not null then 1 else 0 end) +
                (case when ct.total_debt is not null then 1 else 0 end)
            ) as completeness_score,

            row_number() over (
                partition by p.conversation_id
                order by 
                    -- highest completeness first
                    (
                        (case when ct.email is not null then 1 else 0 end) +
                        (case when ct.surplus is not null then 1 else 0 end) +
                        (case when ct.vulcan_surplus is not null then 1 else 0 end) +
                        (case when ct.total_unsecured_debt_vsapi is not null then 1 else 0 end) +
                        (case when ct.total_debt is not null then 1 else 0 end)
                    ) desc
            ) as rn

        from pivoted p
        left join contacts ct
          on p.contact_id = ct.contact_id
    )
    where rn = 1
)
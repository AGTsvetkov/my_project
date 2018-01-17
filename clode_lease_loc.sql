---------------
--pm_payment_terms_all
---------------

declare
  i_table_row     xx_opm.pm_payment_terms_all%rowtype;
  i_table_row_s     xx_opm.pm_payment_schedules_all%ROWTYPE;

  l_termination_date date;
  l_execution_date   date;
  l_amount number;
  
  l_result    number := null;
  l_result_s    number := null;
  l_retmsg    varchar2(255);
  l_retmsg_s    varchar2(255);
  
  pay_description varchar2(500);
  pay_amount number;
  pay_cost_center number;
  pay_min_need_by_date date;
  pay_max_need_by_date date;

  
begin
  
--2016, 2026, 2141, 2368, 1989

--R326779, R324086, R326964

 For q1 in (select *--unique 
                   --lease_id, apps.stragg_distinct(lease_location_id) lease_location_id, name, lease_num, loc_lease_count, loc_count--, requisition_header_id
                   from
           (select l.lease_id, ll.lease_location_id, l.name, l.lease_num,
             count(unique ll.lease_location_id) over (partition by l.lease_id, l.vendor_doc_id) loc_lease_count,
             count(unique loc.parent_location_id) over (partition by l.lease_id, l.vendor_doc_id) loc_count,
             --count(unique loc.location_code) over (partition by l.lease_id, l.vendor_doc_id) loc_code_count,
             --count(r.requisition_header_id) over (partition by r.vendor_site_id) req_count,
        r.*
        from
        pm_leases_v l,
        pm_lease_locations_v ll,
        pm_locations_v loc,
        (select 
        h.segment1, 
        max(h.requisition_header_id) requisition_header_id,
        max(h.description) description,
        max(h.interface_source_code) interface_source_code,
        count(l.requisition_line_id) count_line,
        count(unique l.item_id) count_item_id,
        apps.stragg_distinct(l.item_id) list_items_id,
        max(l.vendor_id) vendor_id,
        max(l.vendor_site_id) vendor_site_id,
        min(l.need_by_date) need_by_date_begin,
        max(l.need_by_date) need_by_date_end,
        max(l.currency_code) currency_code,
        sum(l.unit_price) amount,
        min(l.need_by_date) min_need_by_date
        from
        cgl.g1ru_edoc_employees_mv e,
        apps.po_requisition_headers_all h,
        apps.po_requisition_lines_all l,
        (select ffv.flex_value_id, ffvt.description
             from
              apps.fnd_flex_values_tl ffvt
             ,apps.fnd_flex_values ffv
             ,apps.fnd_flex_value_sets ffvs
             where
                ffv.flex_value_id = ffvt.flex_value_id
              and ffvs.flex_value_set_id = ffv.flex_value_set_id
              and ffvs.flex_value_set_name = 'PO_CATEGORY_CAPEX'
              and ffvt.language = userenv('LANG')
              and ffv.enabled_flag = 'Y'
              and ffvt.description like '%#ADMIN') b
        where
        b.flex_value_id = h.attribute8
        and h.attribute6 = 'Затраты1'
        and (e.quit_date >= sysdate or e.quit_date is null)
        and h.preparer_id = e.ofa_person_id
        and l.requisition_header_id = h.requisition_header_id
        and nvl(h.interface_source_code, -1) != 'OPM'
        and not exists (select 1 from pm_payment_schedules_v p where p.requisition_header_id = h.requisition_header_id)
        and apps.G1RU_PO_ACTION_HISTORY_PKG.get_current_person_id(i_OBJECT_ID=>h.requisition_header_id
                                                                 ,i_OBJECT_TYPE_CODE=>'REQUISITION'
                                                                 ,i_OBJECT_SUB_TYPE_CODE =>'PURCHASE') != 7966
        group by h.segment1) r
        where 
        l.vendor_id(+) = r.vendor_id
        and l.vendor_doc_id(+) = r.vendor_site_id
        and ll.lease_id(+) = nvl(l.lease_id, -1)
        and r.min_need_by_date >= to_date('01.01.2018', 'dd.mm.yy')
        and loc.location_id(+) = ll.LOCATION_ID
        --and loc.location_code is not null
        --and l.lease_id in (2016, 2026, 2141, 2368, 1989) --2214
        )
        where 
        loc_lease_count > loc_count
        group by lease_id, name, lease_num, loc_lease_count, loc_count--, requisition_header_id
        --loc_lease_count = 1
        --and requisition_header_id not in (326779, 324086, 326964)
        )
   
  loop
    
  --payments
begin

    select * 
     into i_table_row_p
     from xx_opm.pm_payment_terms_v
    where payment_term_id = :P410_PAYMENT_TERM_ID;

      i_table_row_p.active_end_date := sysdate;
      
      l_result := pm_payments_pkg.upsert_payment_term(i_table_row => i_table_row, o_retmsg => l_retmsg);
      
      commit;

end;


if rec.loc_lease_count > rec.loc_count then
  
 select 

elsif rec.loc_lease_count < rec.loc_count then
 null;
end if;

--lease_location  
begin

    for loc in (select count(loc.location_id) count_loc_id, max(ll.lease_location_id) lease_location_id
                 from xx_opm.pm_lease_locations_v ll,
                      xx_opm.pm_locations_v loc
                where lease_location_id in (380,449)
                and loc.location_id = ll.location_id
                and to_char(loc.location_id)!= to_char(loc.location_code))
                
                loop
                  
                  if loc.count_loc_id => 1 then
                      
                     for loc_c in (select ll.lease_location_id
                                   from xx_opm.pm_lease_locations_v ll,
                                        xx_opm.pm_locations_v loc
                                  where lease_location_id in (380,449)
                                  and loc.location_id = ll.location_id
                                  and to_char(loc.location_id) = to_char(loc.location_code)
                                  )
                                  loop
                                    
                                  dbms_output.put_line('lease_location_id ' || loc_c.lease_location_id);
                                    
                                      for Pay in (select p.payment_term_id
                                                   from xx_opm.pm_payment_terms_v p
                                                  where p.lease_location_id = loc_c.lease_location_id) loop
                                                  
                                                  dbms_output.put_line('payment_term_id ' || Pay.payment_term_id);
                                      
                                          select * 
                                           into i_table_row_p
                                           from xx_opm.pm_payment_terms_v p
                                          where p.payment_term_id = Pay.payment_term_id;

                                            i_table_row_p.lease_location_id := loc.lease_location_id;
                                            l_result_p := pm_payments_pkg.upsert_payment_term(i_table_row => i_table_row_p, o_retmsg => l_retmsg);
                                        
                                        end loop;
                                        
                                        select * 
                                         into i_table_row_ll
                                         from xx_opm.pm_lease_locations_v 
                                        where lease_location_id = loc_c.lease_location_id;

                                        i_table_row_ll.active_end_date := sysdate;
                                        l_result_l := xx_opm.pm_leases_pkg.upsert_lease_locations(i_table_row => i_table_row_ll, o_retmsg => l_retmsg);
                                        
                                        dbms_output.put_line('lease_location_id ' || ll.lease_location_id);
                                        
                                  end loop;
                                  
                   end if;               
                  
                end loop;

end;
  
  
  
end;


--- select s.*, s.rowid from pm_payment_schedules_all s where payment_term_id = 2006
--where active_start_date = to_date

-- select s.*, s.rowid from  pm_payment_terms_all s

-- 428512

--select * from xx_opm.pm_system_items_v 
-- SELECT SYSDATE,ADD_MONTHS((LAST_DAY(SYSDATE)+1),-1) FROM DUAL;

--��� ������� � ������� � ����� de_reboot.ipynb ��� Jupyter Notebook

----------------------------
---����� ������� � ������---
----------------------------

--������ �������� �� ������/�� ������ �� ������� f3
--������ - ���� ����� � f3(��������� ������� ����� ������/�� ���������� �� �������) ��� ���� ? � �����, ����� �� ������� �����
select count(distinct f3) from student00.realty_sale_data where not regexp_like(f3, '^[^0-9]+$') or regexp_like(f3, '\?{1}$')
--�� ������ - ��� ���� � ? � �����
select count(distinct f3) from student00.realty_sale_data where regexp_like(f3, '^[^0-9]+$') and not regexp_like(f3, '\?{1}$')
--� ����� ���� �� �� ����������, ��� � ����� �� ���� �������
select count(distinct f3) from student00.realty_sale_data

create table avg_ratio as
--������� ������ ���������� �� ������ �� ������� �� 1,2,3-��������� ���������
with sale_ratio as
(select f2 address, f4 room, 
round(avg(to_number(replace(f7, ' ', ''))/to_number(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ','))), 4) avg_metr_cost_sale
from student00.realty_sale_data
where f4 = any('1', '2', '3') --������ �������, ������, ������
and not regexp_like(f2, '^[^0-9]+$') --������� ������ �� ������� � �������, �� ��������� (��� ��� ��� ���������� ����� 2 ���������)
and (not regexp_like(f3, '^[^0-9]+$') or regexp_like(f3, '\?{1}$')) -- ��������� �� ������
group by f2, f4),
rent_ratio as
(select f2 address, f4 room, 
round(avg(to_number(replace(f7, ' ', ''))/ to_number(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ',')) * 12), 4) avg_metr_annual_rent
from student00.realty_rent_data r
where (regexp_substr(f5, '^\d+\.?\d?') is not null and (
        to_number(replace(regexp_substr(f5, '\d+\.?\d?$'), '.', ',')) < to_number(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ',')) or
        regexp_substr(f5, '\d+\.?\d?$') is null)) --��� ���� ���. ������� � ������� ����� ������ ��� ������ �����
and f4 = any('1', '2', '3') --������ �������, ������, ������
and not regexp_like(f2, '^[^0-9]+$') --������� ������ �� ������� � �������, �� ��������� (��� ��� ��� ���������� ����� 2 ���������)
and (not regexp_like(f3, '^[^0-9]+$') or regexp_like(f3, '\?{1}$')) -- ��������� �� ������
and f2 not in ('��������� ��., 2')  -- ������ �������� ������
group by f2, f4)
select address, room, round(avg_metr_annual_rent / avg_metr_cost_sale, 5) rent_rate
from sale_ratio s
inner join rent_ratio using(address, room)
order by 3 desc, 1, 2


select room "���������� ������", round(avg(rent_rate), 4) * 100 || '%' "������� ���������� �� ����� �������� � ������ �� ���"
from avg_ratio
group by room
order by 1
--������� ���������� �� ����� �������� � ������ �� ��� �� ���������� ������
���������� ������	������� ���������� �� ����� �������� � ������ �� ���
1	                5,13%
2	                4,59%
3	                4,84%


create table rent_sale_info as
--������� ����������� �� �������
with sale_rent as
(select distinct
to_number(replace(regexp_substr(s.f5, '^\d+\.?\d?'), '.', ',')) buy_area,
to_number(replace(regexp_substr(r.f5, '^\d+\.?\d?'), '.', ',')) rent_area, 
s.f2 address, s.f4 room_count, 
cast(replace(s.f7, ' ') as number) sale_price, cast(replace(r.f7, ' ') as number)*12 annual_rent
from student00.realty_sale_data s
inner join student00.realty_rent_data r
on s.f2 = r.f2 and s.f4 = r.f4 --���������� �� ������ � ���-�� ������
where not regexp_like(s.f2, '^[^0-9]+$') --������� ������ �� ������� � �������, �� ��������� (��� ��� ��� ���������� ����� 2 ���������)
and s.f4 in ('1', '2', '3') --1,2,3-��������� ��������
and regexp_like(s.f4, '\d') and r.f4 <> '���' --�� ������� ���� � �� ����� �������
and (not regexp_like(r.f3, '^[^0-9]+$') or regexp_like(r.f3, '\?{1}$')) -- ��������� �� ������
and (not regexp_like(s.f3, '^[^0-9]+$') or regexp_like(s.f3, '\?{1}$')) -- ��������� �� ������
and (regexp_substr(r.f5, '^\d+\.?\d?') is not null and (
        to_number(replace(regexp_substr(r.f5, '\d+\.?\d?$'), '.', ',')) < to_number(replace(regexp_substr(r.f5, '^\d+\.?\d?'), '.', ',')) or
        regexp_substr(r.f5, '\d+\.?\d?$') is null))), --��� ���� ���. ������� � ������� ����� ������ ��� ������ �����
sale_rent_grouped as 
(select address, room_count,
case 
when (buy_area between 20.0 and 39.0 and rent_area between 20.0 and 39.0) then 1
when (buy_area between 40.0 and 59.0 and rent_area between 40.0 and 59.0) then 2
when (buy_area between 60.0 and 79.0 and rent_area between 60.0 and 79.0) then 3
when (buy_area between 80.0 and 99.0 and rent_area between 80.0 and 99.0) then 4
when (abs(buy_area-rent_area) <= 4.0) then trunc(buy_area/20)
else 5 end area_group,
buy_area, sale_price, rent_area, annual_rent, round(sale_price * 1.0 / annual_rent, 2) years,
round(annual_rent * 1.0 / sale_price, 5)*100 rent_rate
from sale_rent),
group_comparison as 
(select area_group, avg(sale_price) avg_sale_price,
round(avg(years)) avg_year_payback,
round(avg(rent_rate), 2) avg_rent_rate,
decode(round(avg(years) / lag(avg(years)) over(order by area_group) * 100.00 - 100, 2) , null, '-',
round(avg(years) / lag(avg(years)) over(order by area_group) * 100.00 - 100, 2)) year_change,
decode(round(avg(rent_rate) / lag(avg(rent_rate)) over(order by area_group) * 100.00 - 100, 2) , null, '-',
round(avg(rent_rate) / lag(avg(rent_rate)) over(order by area_group) * 100.00 - 100, 2)) rent_rate_change
from sale_rent_grouped
where area_group < 5 --��������� ������ �� ���������� � ������, ������������� �� �������
group by area_group)
select area_group, round(avg_sale_price, 2) avg_sale_price, avg_year_payback, avg_rent_rate,
to_number(decode(year_change, '-', 0 , year_change)) year_change,
to_number(decode(rent_rate_change, '-', 0 , rent_rate_change)) rent_rate_change
from group_comparison

/*� ������ ������ �������� �������� �� ������� � ����������� �� ������� � ���������� ������ (������ �� 20 ������).
�.�. ���������� ������ �� 2 ������ ������ �� ���������� ������ � ������, ����� ��� �������� �� ������ �� �������.
� ������� ����� ������� ��������� ������� �������� �� ������, ������� ���� ����������� � �����, ������� ����������� ������� ������ � ��������� �������� �� ������,
��������� ����� ����������� � ���������, ��������� ������ ������.
������ � ���, ��� �������� � ���������� ����������� ������ ����� ������ ����������� �� �������.*/

select 
area_group * 20 || ' - ' || to_char(area_group * 20 + 20) || ' ��.�.' "������", --������ ������� ������ �� �������
to_char(avg_sale_price, '999G999G999D99', 'NLS_NUMERIC_CHARACTERS=''. ''') || ' ���.' "C������ ��������� �������",
avg_year_payback "C������ ���� �����������, ���",
avg_rent_rate || '%' "C������ ������ ������",
year_change || '%' "�������� �����������",
rent_rate_change || '%' "�������� ������ ������"
from rent_sale_info

--���������� �� ������� �������
������	       C������ ��������� �������	C������ ���� �����������, ���	C������ ������ ������	�������� �����������	�������� ������ ������
20 - 40 ��.�.  7 370 310.34 ���.	        20	                            5,15%	                0%	                    0%
40 - 60 ��.�.  11 608 425.00 ���.	        21	                            5,2%	                4,61%	                1,05%
60 - 80 ��.�.  13 704 166.67 ���.	        22	                            4,78%	                3,68%	                -8,19%
80 - 100 ��.�. 26 266 666.67 ���.	        28	                            3,77%	                29,52%	                -21,13%


/*
�� ������ ������� � ������� �� ����� ������� � ������ ����������� ������ � ������ ������� �������.
��������, ���� ������ ������ � ������� �����. �� ������ ������� ��������� ������� ����������� ����� ������� � ������� �����,
���� ������������ ��� ������� � ������� ����� ������ ������� ���� ��������
*/
select round(avg(cast(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ',') as decimal(12, 6))/
cast(replace(regexp_substr(f5, '\d+\.?\d?$'), '.', ',') as decimal(12, 6))), 2) av
from student00.realty_rent_data
where regexp_substr(f5, '\d+\.?\d?$') is not null and regexp_substr(f5, '\d+\.?\d?$') is not null
and to_number(replace(regexp_substr(f5, '\d+\.?\d?$'), '.', ',')) < to_number(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ','))
--������� ��������� ������� �������� � ������� ����� 5.57

select round(avg(cast(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ',') as decimal(12, 6))/
cast(replace(regexp_substr(f5, '\d+\.?\d?$'), '.', ',') as decimal(12, 6))), 2) av
from student00.realty_sale_data
where regexp_substr(f5, '\d+\.?\d?$') is not null and regexp_substr(f5, '\d+\.?\d?$') is not null
and to_number(replace(regexp_substr(f5, '\d+\.?\d?$'), '.', ',')) < to_number(replace(regexp_substr(f5, '^\d+\.?\d?'), '.', ','))
--������� ��������� ������� �������� � ������� ����� 6.05
--������� ����������� �� ���� �������� 5,81
/*� ����� ������� ��������� ����� �� ���������� �������� ��� ���������,
�� ��������� ������ ������ �������� � ����� ������� ���������� � 2-3 ���� ������ ��������.
������� � ��������� �������� ����������� �� �����������*/


/*�� ������ ������ ��� ������ �������� ������� ������ � ������� ������ ������ ����������
�� ����������� ��������, ����� ��������������� ������ ����� ��������������� ���� �����.
� �������� ���� ��������� �������, ��� � ������������� ������� ������ ALT_RENT, ��� � � ����������� RENT*/

with sale_rent as
(select distinct
to_number(replace(regexp_substr(s.f5, '^\d+\.?\d?'), '.', ',')) buy_area,
to_number(replace(regexp_substr(r.f5, '^\d+\.?\d?'), '.', ',')) rent_area, 
s.f2 address, s.f4 room_count, 
cast(replace(s.f7, ' ') as number) sale_price, cast(replace(r.f7, ' ') as number) rent
from student00.realty_sale_data s
inner join student00.realty_rent_data r
on s.f2 = r.f2 and s.f4 = r.f4 --���������� �� ������ � ���-�� ������
where not regexp_like(s.f2, '^[^0-9]+$') --������� ������ �� ������� � �������, �� ��������� (��� ��� ��� ���������� ����� 2 ���������)
and s.f4 in ('1', '2', '3') --1,2,3-��������� ��������
and regexp_like(s.f4, '\d') and r.f4 <> '���' --�� ������� ���� � �� ����� �������
and (not regexp_like(r.f3, '^[^0-9]+$') or regexp_like(r.f3, '\?{1}$')) -- ��������� �� ������
and (not regexp_like(s.f3, '^[^0-9]+$') or regexp_like(s.f3, '\?{1}$')) -- ��������� �� ������
and (regexp_substr(r.f5, '^\d+\.?\d?') is not null and (
        to_number(replace(regexp_substr(r.f5, '\d+\.?\d?$'), '.', ',')) < to_number(replace(regexp_substr(r.f5, '^\d+\.?\d?'), '.', ',')) or
        regexp_substr(r.f5, '\d+\.?\d?$') is null))), --��� ���� ���. ������� � ������� ����� ������ ��� ������ �����
sale_rent_grouped as
(select case 
when (buy_area between 20.0 and 39.9 and rent_area between 20.0 and 39.9) then 1
when (buy_area between 40.0 and 59.9 and rent_area between 40.0 and 59.9) then 2
when (buy_area between 60.0 and 79.9 and rent_area between 60.0 and 79.9) then 3
when (buy_area between 80.0 and 99.9 and rent_area between 80.0 and 99.9) then 4
when (buy_area between 100.0 and 120.9 and rent_area between 100.0 and 120.9) then 5
when (buy_area between 120.0 and 140.0 and rent_area between 120.0 and 140.0) then 6
when (abs(buy_area-rent_area) <= 4.0) then trunc(buy_area/20)
else 7 end area_group,
address, room_count room,
buy_area, rent_area, sale_price, rent
from sale_rent)
select area_group, address, room, buy_area, rent_area, sale_price, rent,
round((buy_area/rent_area) * rent) alt_rent
from sale_rent_grouped
where area_group < 7

/*
�����
��� ����� ��������� ������� ������� ���������� �� ������� �������� � �� ���������� ����� � ������ ��������� ����� 4.8% �������.
� ����������� ����� ������� �������� � ������� ���� ������� ��������
������ ���� ����������� � ����������� ������ ���������� ������� �� ����� �� � ������.
� ������ ������ �� ������ ��������, ������� �� ������ ��������, ���� ������ ������, ������, ������� �������� � ���� ��� �� �����.
��� ��� ���� �� ������� ������ �������, ��� ������ ������, � ����������� �������� ����� ������� ����������������
����� 10% �� �������� ������ ����� �� ������ ��������, �����������, ��� � ������ ���� �����������
������ ��������� � �������/������� ����� ��� ����� ����������, �.�. ���� ����������� ����� ����, � ���������� ������ ����� ����.
� �� �� ������������ ������� �������� � ����� �� ����� � ������, ��� �������������� ����������. 
*/

---------------------------------------
---������ ������ ���������� ��������---
---------------------------------------

--��������� ������� MCFTR c ������ �������� �� SQL
with temp as 
(select extract(year from to_date(f1)) year, to_date(f1) main_date,
lead(to_date(f1), 1, to_date('01.01.2022', 'dd.mm.yyyy')) over (order by to_date(f1)) next_date, 
to_number(replace(f2, ' ', '')) rate,
lag(to_number(replace(f2, ' ', '')), 1, 
                 to_number(replace((select distinct first_value(f2) over (order by to_date(f1) desc) 
                 from mcftr where extract(year from to_date(f1)) = 2009), ' ', ''))) over (order by to_date(f1)) prev_rate
from student00.mcftr
where extract(year from to_date(f1)) between 2010 and 2021),
mcftr_info as 
(select trunc(min(main_date) keep (dense_rank first order by main_date), 'yyyy') first_date,
trunc(min(next_date) keep (dense_rank last order by next_date), 'yyyy') last_date,
min(prev_rate) keep (dense_rank first order by main_date) first_rate,
min(rate) keep (dense_rank last order by main_date) last_rate
from temp
group by year
order by 1)
select to_char(first_date, 'dd.mm.yyyy') "������", to_char(last_date, 'dd.mm.yyyy') "�����",
round((last_rate * student00.st_get_inf_period('RUB', last_date, to_date('01.03.2022', 'dd.mm.yyyy')))/
(first_rate * student00.st_get_inf_period('RUB', first_date, to_date('01.03.2022', 'dd.mm.yyyy'))), 7) "���������� ����� � ������ ��������"
from mcftr_info
order by 1 desc


--Pipeline ������� � ������������ �������� ������� ���������� ������� (���. � 2009 ���� �� 2021)
--� ���������� ����������� ������� � ���������� ���������� �� ������ ���� ��������
create or replace type mcftr_row as object(begin_date date, end_date date, mcftr_rate decimal(10, 7));
create or replace type mcftr_table is table of mcftr_row;
create or replace function mcftr_change(in_begin_year int, in_end_year int) -- ������� ��������� ��� � �������� ��� (������������)
return mcftr_table pipelined
as
   final_row mcftr_row;
   f_rate decimal(10, 2);
   l_rate decimal(10, 2);
   growth_rate decimal(10, 7);
   f_date date;
   l_date date;
   cur_mcftr sys_refcursor;
begin
    open cur_mcftr for
    select distinct
        trunc(first_value(main_date) over (partition by year order by main_date), 'yyyy') first_date,
        trunc(first_value(next_date) over (partition by year order by main_date desc), 'yyyy') last_date,
        first_value(prev_rate) over (partition by year order by main_date) first_rate,
        first_value(rate) over (partition by year order by main_date desc) last_rate
    from
        (select extract(year from to_date(f1)) year, to_date(f1) main_date,
        lead(to_date(f1), 1, to_date('01.01.' || to_char(in_end_year + 1), 'dd.mm.yyyy')) over (order by to_date(f1)) next_date, 
        to_number(replace(f2, ' ', '')) rate,
        coalesce(lag(to_number(replace(f2, ' ', '')), 1, 
                 to_number(replace((select distinct first_value(f2) over (order by to_date(f1) desc) 
                 from mcftr where extract(year from to_date(f1)) = in_begin_year - 1), ' ', ''))) over (order by to_date(f1)), to_number(replace(f2, ' ', ''))) prev_rate
        from mcftr
        where extract(year from to_date(f1)) between in_begin_year and in_end_year)   
    order by 
        1;
    loop
        fetch cur_mcftr into
            f_date,
            l_date,
            f_rate,
            l_rate;
        exit when cur_mcftr%notfound;
        growth_rate := round((l_rate * st_get_inf_period('RUB', l_date, to_date('01.03.2022', 'dd.mm.yyyy')))/
        (f_rate * st_get_inf_period('RUB', f_date, to_date('01.03.2022', 'dd.mm.yyyy'))), 7);
        final_row := mcftr_row(f_date, l_date, growth_rate);
        pipe row(final_row);
        end loop;
end mcftr_change;

--��� ������� � ��������� ���������� �� ���� ������
create or replace function mcftr_change_one_period(in_begin_year int, in_end_year int) -- ������� ��������� ��� � �������� ��� (������������)
return mcftr_table pipelined
as
   final_row mcftr_row;
   f_rate decimal(10, 2);
   l_rate decimal(10, 2);
   growth_rate decimal(10, 7);
   f_date date;
   l_date date;
   cur_mcftr sys_refcursor;
begin
    open cur_mcftr for
    select
        trunc(min(main_date), 'yyyy') first_date,
        trunc(max(next_date), 'yyyy') last_date,
        min(prev_rate) keep (dense_rank first order by main_date) first_rate,
        min(rate) keep (dense_rank last order by main_date) last_rate
    from
        (select to_date(f1) main_date,
        lead(to_date(f1), 1, to_date('01.01.' || to_char(in_end_year + 1), 'dd.mm.yyyy')) over (order by to_date(f1)) next_date, 
        to_number(replace(f2, ' ', '')) rate,
        coalesce(lag(to_number(replace(f2, ' ', '')), 1, 
                 to_number(replace((select distinct first_value(f2) over (order by to_date(f1) desc) 
                 from mcftr where extract(year from to_date(f1)) = in_begin_year - 1), ' ', ''))) over (order by to_date(f1)), to_number(replace(f2, ' ', ''))) prev_rate
        from mcftr
        where extract(year from to_date(f1)) between in_begin_year and in_end_year)   
    order by 
        1;
        fetch cur_mcftr into f_date, l_date, f_rate, l_rate;
        growth_rate := round((l_rate * st_get_inf_period('RUB', l_date, to_date('01.03.2022', 'dd.mm.yyyy')))/
        (f_rate * st_get_inf_period('RUB', f_date, to_date('01.03.2022', 'dd.mm.yyyy'))), 7);
        final_row := mcftr_row(f_date, l_date, growth_rate);
        pipe row(final_row);
end mcftr_change_one_period;

--���������� �� ������� MCFTR �� 2010-2021 ��.
select to_char(begin_date, 'dd.mm.yyyy') "������", to_char(end_date, 'dd.mm.yyyy') "�����", mcftr_rate "���������� ����� � ������ ��������"
from table(mcftr_change(2010,2021)) order by 1 desc

������	    �����	    ���������� ����� � ������ ��������
01.01.2021	01.01.2022	1,1236157
01.01.2020	01.01.2021	1,0944874
01.01.2019	01.01.2020	1,3435797
01.01.2018	01.01.2019	1,1420979
01.01.2017	01.01.2018	0,9735759
01.01.2016	01.01.2017	1,2600726
01.01.2015	01.01.2016	1,1715301
01.01.2014	01.01.2015	0,8814088
01.01.2013	01.01.2014	0,9987301
01.01.2012	01.01.2013	1,0205821
01.01.2011	01.01.2012	0,8062599
01.01.2010	01.01.2011	1,1517608

--������������� ���������� �� ������� MCFTR �� ��������� 12 ��� (2010-2021 ��.)
select avg(mcftr_rate) "������������� ���������� �� ������� MCFTR" from (select * from table(mcftr_change(2010,2021)))

������������� ���������� �� ������� MCFTR
1,08064175

--���������� �� ������� MCFTR � ������ �������� �� ��������� 12 ��� (2010-2021 ��.)
select to_char(begin_date, 'dd.mm.yyyy') "������", to_char(end_date, 'dd.mm.yyyy') "�����", mcftr_rate "���������� ����� � ������ ��������"
from table(mcftr_change_one_period(2010,2021))
������	    �����	    ���������� ����� � ������ ��������
01.01.2010	01.01.2022	2,2626895

--�������� ��� ������� ������� mcftr
select /*csv*/ to_char(date_m, 'dd.mm.yyyy') date_m, mcftr_rate 
from
(select to_date(f1) date_m, translate(f2, ', ', '.') mcftr_rate 
from student00.mcftr 
where to_date(f1) < to_date('01.03.2022', 'dd.mm.yyyy')
order by 1)

--�������� ��� ������� ������� mcftr � ������ ��������
select /*csv*/ to_char(to_date(f1), 'dd.mm.yyyy') date_i, 
replace(to_char(round(st_get_inf_period('RUB', to_date(f1), to_date('01.03.2022', 'dd.mm.yyyy')) * 
to_number(replace(f2, ' ', '')), 2)), ',', '.') mcftr_rate
from student00.mcftr
where to_date(f1) < to_date('01.03.2022', 'dd.mm.yyyy')
order by to_date(f1)

--�����
/*� ������ ������� ������� ��������� ������� MCFTR � ������ �������� �� ������ ���.
���� �� ������ ��������� ��� �������, �� �� ����������� �������� ���������� ���� �������,
��� � ����� ������� ������������� ���������� � 8% �� ��������� 12 ���, ��� ���� ������, ����������� �� ����� �������� � ������.
���� ������� �������� �� � ������ � ������ 2010 ����, �� � ����� 2021 ����, ��� ��������
����������� � 2,62 ���� � ������ ��������. ����� ������� ����� � ���, ��� ������ ���������� ����� ��������������
�� ��������� � �������� �������� � ������ �� � ������.*/

-----------------------------
---������ ���������� �����---
-----------------------------

--�������� ��� �� ����� C�������� �� 2005 - 2022 ��.
select stock_name, to_char(dt, 'dd.mm.yyyy') stock_date, to_char(stock_price, '999.999999') price
from student00.stock_invest_results
where stock_name like '����%' and extract(year from dt) between 2005 and 2021
order by stock_name, dt

--�������� ���������� �� ������ C�������� � ������ �������� �� 2005 - 2022 ��.
select stock_name, to_char(dt, 'dd.mm.yyyy') stock_date, to_char(amt_minus_infl, '999.999999') amt
from student00.stock_invest_results
where stock_name like '����%' and extract(year from dt) between 2005 and 2021
order by stock_name, dt

select * from student00.stock_invest_results

--��������
--��������� ����   13.91
--�������� ����   293.49
--���� ���� 21 ���
--��������� ���������� 73,5
--���� ����� ����� �� ���� ���������������� ���������� 1.48
--���� ������ � ������ ���������������� ���������� � �������� 7.7
--������������� ���� ���������� 1.12

--����������� ������� ���������� �� ���� ������
-- ���� amt_minus_infl �� 01.01 � 31.12
with shares as
(select min(dt) f_date, max(dt) + 1 l_date, extract(year from dt) year, stock_name, 
min(amt_minus_infl) keep (dense_rank last order by dt)/ 
min(amt_minus_infl) keep (dense_rank first order by dt) rate
from student00.stock_invest_results
where extract(year from dt) between 2005 and 2019
group by stock_name, extract(year from dt)
having count(stock_name) = case when extract(year from dt) in (2004,2008,2012,2016,2020) then 366 else 365 end
order by stock_name)
select '01.01.' || to_char(year) "������", '01.01.' || to_char(year + 1) "�����",
count(stock_name) "������������ �����", round(avg(rate), 7) "�����.����� � ������ ��������"
from shares
group by year
order by year

--������������� ���������� �� ���� ������, ������������� � ������� ����� ���� �� 2005 - 2020 ��.
������	    �����	    ������������ �����	�����.����� � ������ ��������
01.01.2005	01.01.2006	20	                1,8239821
01.01.2006	01.01.2007	29	                1,5260068
01.01.2007	01.01.2008	41	                1,1484048
01.01.2008	01.01.2009	50	                0,2332869
01.01.2009	01.01.2010	66	                2,9166982
01.01.2010	01.01.2011	71	                1,3903071
01.01.2011	01.01.2012	78	                0,7217543
01.01.2012	01.01.2013	88	                1,0017400
01.01.2013	01.01.2014	91	                0,8880297
01.01.2014	01.01.2015	97	                0,8504533
01.01.2015	01.01.2016	100	                1,3243141
01.01.2016	01.01.2017	105	                1,5729446
01.01.2017	01.01.2018	108	                1,0775337
01.01.2018	01.01.2019	112	                0,9834712
01.01.2019	01.01.2020	113	                1,2818016

--���-����� ���������� ����� �� 12 ��� � 2010 - 2021 ��.
create or replace view average_stock_rate as
with shares as
(select extract(year from dt) year, stock_name, 
min(amt_minus_infl) keep (dense_rank last order by dt)/ 
min(amt_minus_infl) keep (dense_rank first order by dt) rate,
min(num_stocks) keep (dense_rank last order by dt)/ 
min(num_stocks) keep (dense_rank first order by dt) amount
from stock_invest_results
where extract(year from dt) between 2010 and 2021
group by stock_name, extract(year from dt)
having count(stock_name) = case when extract(year from dt) in (2004,2008,2012,2016,2020) then 366 else 365 end
order by stock_name, extract(year from dt))
select dense_rank() over(order by round(avg(rate), 7) desc) "�", stock_name "������������",
round(avg(rate), 7) "������������� ����������",
round(avg(amount), 7) "������������� ���� ���-�� �����"
from shares
group by stock_name
having count(distinct year) = 12

--������ 30 �������
select * from average_stock_rate
fetch first 30 rows only


--���-30 ����� � ����� ������� ������������� ����������� �� 2010 - 2021 ��.(� ������ �������� � ���������������� ���������� ����������)
�	������������	������������� ����������	������������� ���� ���-�� �����
1	���������      	1,484202                	1,1784198           
2	���� ��        	1,4172652               	1,083812            
3	������. ��     	1,3911945               	1,1889236           
4	��������-�     	1,3374595               	1,0713838           
5	�����          	1,2983448               	1,0696100             
6	���� ��        	1,2475979               	1,0626074           
7	����������     	1,2466445               	1,0150555           
8	�����-��       	1,2306836               	1,0833205           
9	�.�����        	1,2280686               	1,0687097           
10	��� ��         	1,2206663               	1,0175701           
11	����-4��       	1,2093147               	1,1222769           
12	������ 3��     	1,2073715               	1,0743624           
13	����-5��       	1,2031420                	1,0845538           
14	�������-��     	1,1975555               	1,0399082           
15	���� ��        	1,1969198               	1,0248015           
16	������� ��     	1,1965948               	1,0800684           
17	���������      	1,1900540                	1,0741073           
18	������� ��     	1,1891854               	1,0187879           
19	���� ��        	1,1737741               	1,0562718           
20	���� ��        	1,1681476               	1,0541703           
21	��������-�     	1,1609637               	1,0387332           
22	���            	1,1524356               	1,0501024           
23	������� ��     	1,1466059               	1,0265344           
24	���� ��        	1,1422200                 	1,0692068           
25	������ ��      	1,1362510                	1,0360961           
26	��������-�     	1,1343703               	1,0987589           
27	������. ��     	1,1338442               	1,0543303           
28	��������       	1,1272510                	1,0316399           
29	����������     	1,1248392               	1,0544836           
30	������         	1,1208763               	1,0515784    

--������� ����� � ������������� ����������� ���� 1.045
with temp as
(select stock_name, extract(year from dt) year, 
min(amt_minus_infl) keep (dense_rank last order by dt)/ 
min(amt_minus_infl) keep (dense_rank first order by dt) rate
from student00.stock_invest_results
where extract(year from dt) between 2006 and 2020
group by stock_name, extract(year from dt)
having count(stock_name) = case when extract(year from dt) in (2004,2008,2012,2016,2020) then 366 else 365 end
order by stock_name, extract(year from dt))
select dense_rank() over (order by sum(case when rate >= 1.045 then 1 else 0 end) desc,
                                   sum(case when rate >= 1.045 then 1 else 0 end)/count(rate) desc) rating,
stock_name,
round(sum(case when year = 2006 then rate end), 5) "2006",
round(sum(case when year = 2007 then rate end), 5) "2007",
round(sum(case when year = 2008 then rate end), 5) "2008",
round(sum(case when year = 2009 then rate end), 5) "2009",
round(sum(case when year = 2010 then rate end), 5) "2010",
round(sum(case when year = 2011 then rate end), 5) "2011",
round(sum(case when year = 2012 then rate end), 5) "2012",
round(sum(case when year = 2013 then rate end), 5) "2013",
round(sum(case when year = 2014 then rate end), 5) "2014",
round(sum(case when year = 2015 then rate end), 5) "2015",
round(sum(case when year = 2016 then rate end), 5) "2016",
round(sum(case when year = 2017 then rate end), 5) "2017",
round(sum(case when year = 2018 then rate end), 5) "2018",
round(sum(case when year = 2019 then rate end), 5) "2019",
round(sum(case when year = 2020 then rate end), 5) "2020",
sum(case when rate >= 1.045 then 1 else 0 end) "���-�� ���, ����� ������ ������ 1.045",
count(rate) "���-�� ���, ����� ��������� �����",
round(sum(case when rate >= 1.045 then 1 else 0 end)/count(rate), 3) "���� ��� � ���������� �������"
from temp
group by stock_name

/*������ ���������:
��� ��� ������ ����� ����������� ������ ���������� ���, �� �������� �������������� ����� ���������� �������� ���������� ���, ����� ������ ������ 1.045.
��������������, ��� ��� ���� ���������� ��� �� ������� 1.045, ��� ����������� ���������� ���������.
�.�. 11 �� 15 ���� 0.73 � 2 ������ �� 2 ���� ���� 100%, �� 2 ���� �� ���������������� �������, ������� 11 �� 15 � �������� ����� ����.
����� ��� ���������� ���������� �� ���� ��� �� ������� ���� 1.045 �� ������ ����� ���, ����� ��� ����� �����������*/

--���-10 ����� � ������������� ����������� ���� 1.045
RATING	STOCK_NAME	2006	2007	2008	2009	2010	2011	2012	2013	2014	2015	2016	2017	2018	2019	2020	���-�� ���, ����� ������ ������ 1.045	���-�� ���, ����� ��������� �����	���� ��� � ���������� �������
1	    ������ 3��	1,13798	1,06091	0,21819	3,73914	1,12158	0,99942	1,20887	1,15542	1,04526	1,39346	1,18316	1,73469	1,46888	1,604	0,63113	12	                                    15	                                0,8
2	    ���������	-       1,46367	0,27724	1,95115	1,60916	0,66263	1,10391	1,00426	1,4936	1,12771	1,11736	1,11663	1,2826	1,605	1,23582	11	                                    14	                                0,786
3	    ���-��	    1,11932	1,53254	0,2726	2,00129	1,13653	0,69748	1,32956	1,33202	0,49924	1,2132	1,28977	1,13724	0,89525	1,42793	1,10605	11	                                    15	                                0,733
3	    ��������-�	1,08501	0,48112	0,36413	2,43865	1,04999	1,05018	1,26066	1,2917	1,10093	1,61069	0,80941	0,8717	1,39204	1,11292	1,08396	11	                                    15	                                0,733
4	    �����		-       1,50334	0,22517	2,63522	1,23769	1,2288	1,0444	0,78817	1,59333	1,96415	0,973	1,14771	1,25135	1,05616	1,25881	10	                                    14	                                0,714
5	    ��������	2,25789	0,99259	0,20017	3,38659	1,14625	0,72385	1,11933	1,04509	0,50389	1,64289	1,64578	1,31433	0,83505	1,40397	1,09586	10	                                    15	                                0,667
5	    ����-4��	1,34801	1,18585	0,24817	1,67986	1,25044	1,54321	1,03622	0,92006	0,93218	1,09286	1,76083	1,82461	1,35252	1,29262	0,92675	10	                                    15	                                0,667
5	    ����-5��	1,08851	1,17866	0,20956	1,94794	0,93708	1,37665	1,14701	0,85411	0,78238	1,02247	1,96074	1,87735	1,31934	1,22134	1,10087	10	                                    15	                                0,667
6	    ���		    -       1,28229	0,16434	4,02641	1,22286	0,35737	0,80871	0,66695	1,3729	1,58309	1,72699	1,32289	1,08973	1,01548	1,37202	9	                                    14	                                0,643
7	    �����-��	0,99998	1,70158	0,15107	2,74856	1,90449	0,67749	0,98004	0,83006	1,59939	1,15687	1,59014	1,03537	1,16551	1,07163	1,4774	9	                                    15	                                0,6
7	    ��������	2,7531	1,06127	0,07788	1,53386	1,27766	0,36255	2,05121	0,47838	0,49493	1,23901	1,37621	0,87909	0,59713	1,24103	1,05275	9	                                    15	                                0,6
7	    ��������-�	1,95881	1,2279	0,18368	2,73485	1,58542	0,62682	0,79739	0,66301	0,90897	0,93731	3,63626	1,96729	1,23869	1,38068	1,30678	9	                                    15	                                0,6
7	    ������ 3��	1,18337	1,12053	0,33897	2,39077	1,01972	1,0293	1,34008	0,92969	1,01778	1,26924	1,31507	1,21052	1,55154	1,14849	0,65699	9	                                    15	                                0,6
7	    ��������-�	2,20342	0,82904	0,11584	7,1869	1,00685	0,75378	1,09695	1,16274	0,43988	1,81199	1,64086	1,48589	0,89289	1,42239	1,09206	9	                                    15	                                0,6
7	    ����������	1,07234	1,22487	0,36979	2,5257	0,73536	1,11745	0,94138	1,0597	0,92178	0,99871	1,32331	1,21095	1,45873	1,24183	0,76641	9	                                    15	                                0,6
8	    ������� ��	-		-		-       -       -       -       1,23532	1,32048	1,93364	2,14102	1,31629	1,93891	1,27325	1,07195	0,77368	8	                                    9	                                0,889
9	    ���������	-		-       -       -       2,65155	2,88673	1,50756	1,06116	0,65434	1,59113	1,1205	0,82518	0,73854	1,17433	2,58267	8	                                    11	                                0,727
10	    ������� ��	-		-	    -       5,0436	1,88987	1,11006	0,69825	0,77912	0,45522	1,82137	1,3424	0,97872	1,16126	1,3983	1,67028	8	                                    12	                                0,667
10	    ���� ��		-		-       -       2,07838	2,6793	1,17637	1,53785	0,86506	0,76675	1,30814	1,44525	0,87519	1,38758	2,7075	0,97278	8	                                    12	                                0,667


--Pipeline �������, ������� ������������ ������ ����������� ������ ���� ������� ������ (�� 2010 - 2022 ��)
--������� ��������� in_days_max ������������ ������� �� ���� ������� ����������, in_days_min int ����������� ������� �� ���� ������� ����������
/*����� � �������� �� ������ ���� ������ � 45 - 10 ���� �� ������� ������ � ����� �����.
10 ���� ���� �� �������, ��� �������� ���� ����� �� ����������� ��� �������/������� ��������������� ����� � ����� ������� ����������, 45 ���� ��������*/
create or replace type div_days is object(stock_name varchar2(100), avg_rate decimal(15,12), max_rate decimal(15,12), days_before int, days_after int);
create or replace type div_days_table is table of div_days;
create or replace function average_div_days(in_days_max int, in_days_min int) return div_days_table pipelined as
    div div_days;
    cur_amt decimal(15,12) := 0.0;
    max_amt decimal(15,12) := 0.0;
    top_amt decimal(15,12) := 0.0;
    b_days int := 0;
    a_days int := 0;
    b_days_total int := 0;
    a_days_total int := 0;
    amt_total decimal(15,12) := 0.0;
    b_days_avg int := 0;
    a_days_avg int := 0;
    amt_avg decimal(15,12) := 0.0;
    div_per_stock_counter int := 0;
    type date_amt_kv is table of decimal(20, 18) index by varchar2(100);
    date_amt_dict date_amt_kv;
    type date_amt_rec is record(r_date date, r_amt decimal(20, 18));
    date_amt_str date_amt_rec;
    date_range sys_refcursor;
begin
    for company in (select distinct stock_name from stock_invest_results where div_amt is not null order by 1) loop -- 1 ���� �� ������ �����
        for stock in (select dt, stock_name, div_amt from stock_invest_results
                        where stock_name=company.stock_name and div_amt is not null and extract(year from dt) between 2010 and 2021
                            order by stock_name, dt) loop -- 2 ���� �� ������ ���� ������� ������ � ������ ����� �� 1 �����
            open date_range for -- �������� ��������� ���������� � �������� �� ������� � ��������� ��������� ������ ���� �������� ������
                select dt, amt_minus_infl
                from stock_invest_results
                where stock_name = company.stock_name and dt between stock.dt - in_days_max and stock.dt + in_days_max order by dt;
            loop
                fetch date_range into date_amt_str;
                exit when date_range%notfound;
                date_amt_dict(to_char(date_amt_str.r_date, 'dd.mm.yyyy')) := date_amt_str.r_amt; -- �������� ������� ������� ����(����)- amt_minus_infl(��������)
            end loop;
            for z in (select dt, stock_name, div_amt, amt_minus_infl
                        from stock_invest_results
                            where stock_name = company.stock_name and dt between stock.dt - in_days_max and stock.dt - in_days_min
                                order by dt) loop -- 3 ���� ������� � ���� ������� ������ - ������������ ������� � ���� �� ���� ������� ������
                for add_dt in in_days_min..in_days_max loop -- 4 ���� ������ ���� �� ������� ������ �� 3 ����� ��������� � ������ ����� ����� ������� ������ 
                    cur_amt := date_amt_dict(to_char(stock.dt + add_dt, 'dd.mm.yyyy'))/z.amt_minus_infl;
                    if cur_amt > max_amt then --��� ������������ ���������� � ��������������� ���-�� ���� �� � ����� ���� ������� ������ �� ������ ���� ������� ������ �� 2 ����� �� ������ ����� �� 1 �����
                        max_amt := cur_amt;
                        b_days := stock.dt - z.dt;
                        a_days := add_dt;
                    end if;
                end loop;
            end loop;
        if max_amt > top_amt then
            top_amt := round(max_amt, 7); --������������ ���������� �� ��������� �����
        end if;
        b_days_total := b_days_total + b_days;
        a_days_total := a_days_total + a_days;
        amt_total := amt_total + max_amt;
        div_per_stock_counter := div_per_stock_counter + 1;
        max_amt := 0.0;
        end loop;
    b_days_avg := ceil(b_days_total / div_per_stock_counter); --�� ������ ���� ������� ������ �� ������ ����� ���������� ���������� ��� �� � ����� � ����. ����������
    a_days_avg := ceil(a_days_total / div_per_stock_counter); --� ������ ������� �������� �� ������ ����� 
    amt_avg := round(amt_total / div_per_stock_counter, 7);
    div := div_days(company.stock_name, amt_avg, top_amt, b_days_avg, a_days_avg);
    pipe row (div);
    b_days_total := 0;
    a_days_total := 0;
    b_days_avg := 0;
    a_days_avg := 0;
    div_per_stock_counter := 0;
    top_amt := 0.0;
    amt_avg := 0.0;
    amt_total := 0.0;
    end loop;
end;
--������� �������� ����� 70 ������

--�� �� �����, ��� � ������� ����, �� � ������� ���������� �� ������ ������� ����������
--������ �� ������ ���������
set serveroutput on size unlimited
declare
    cur_amt decimal(20,18) := 0.0;
    max_amt decimal(20,18) := 0.0;
    b_days int := 0;
    a_days int := 0;
    b_days_total int := 0;
    a_days_total int := 0;
    b_days_avg int := 0;
    a_days_avg int := 0;
    div_per_stock_counter int := 0;
    type date_amt_kv is table of decimal(20, 18) index by varchar2(100);
    date_amt_dict date_amt_kv;
    type date_amt_rec is record(r_date date, r_amt decimal(20, 18));
    date_amt_str date_amt_rec;
    date_range sys_refcursor;
begin
    dbms_output.enable(1000000);
    for company in (select distinct stock_name from student00.stock_invest_results where stock_name like '��������%' and div_amt is not null order by 1) loop
        dbms_output.put_line('������� ���������� ��� ' || company.stock_name);
        for stock in (select dt, stock_name, div_amt from student00.stock_invest_results
                        where stock_name=company.stock_name and div_amt is not null and extract(year from dt) < 2022
                            order by stock_name, dt) loop
            dbms_output.put_line('������� �������� ��� ���� ������� ���������� ' || stock.div_amt || ' �� ' || stock.dt || ' �� ����� ' || company.stock_name);
            open date_range for 
                select dt, amt_minus_infl
                from student00.stock_invest_results
                where stock_name = company.stock_name and dt between stock.dt - 45 and stock.dt + 45 order by dt;
            loop
                fetch date_range into date_amt_str;
                exit when date_range%notfound;
                date_amt_dict(to_char(date_amt_str.r_date, 'dd.mm.yyyy')) := date_amt_str.r_amt;
            end loop;
            for z in (select dt, stock_name, div_amt, amt_minus_infl
                        from student00.stock_invest_results
                            where stock_name = company.stock_name and dt between stock.dt - 45 and stock.dt - 10
                                order by dt) loop
                for add_dt in 10..45 loop
                    cur_amt := date_amt_dict(to_char(stock.dt + add_dt, 'dd.mm.yyyy'))/z.amt_minus_infl;
                    if cur_amt > max_amt then
                        max_amt := cur_amt;
                        b_days := stock.dt - z.dt;
                        a_days := add_dt;
                    end if;
                end loop;
            end loop;
        dbms_output.put_line('������������ ���������� ' || max_amt || ' ���������� ��� ������� �� ' || b_days || ' ���� �� � ' || a_days || ' ���� ����� ������� ����������');
        max_amt := 0;
        --dbms_output.put_line('����� ������� ��� ������� ���������� �� ' || to_char(extract(year from stock.dt)) || chr(10));
        b_days_total := b_days_total + b_days;
        a_days_total := a_days_total + a_days;
        div_per_stock_counter := div_per_stock_counter + 1;
        end loop;
    b_days_avg := ceil(b_days_total / div_per_stock_counter);
    a_days_avg := ceil(a_days_total / div_per_stock_counter);
    dbms_output.put_line('�� ����� ' || company.stock_name || ' ������������ ���������� ��� ������� �� ' ||  b_days_avg || ' ���� �� � ' || a_days_avg || ' ���� ����� ������� ����������' || chr(10));    
    b_days_total := 0;
    a_days_total := 0;
    b_days_avg := 0;
    a_days_avg := 0;
    div_per_stock_counter := 0;
    end loop;
end;


--������� �������� ����������, ���� �� � ���� ����� ������� ����������, ������ ������������ ������� ������ �� ������ �����
select stock_name "������������", to_char(avg_rate, '0.999999') "������� ����������", to_char(max_rate,'0.999999') "������������ ����������",
days_before "���� �� ������� ����������", days_after "���� ����� ������� ����������"
from table(average_div_days(45,10))
order by stock_name;

--������� �������� ���������� �� ���� ������ = 1,16
select avg(avg_rate) "������� �������� ���������� �� ���� ������"
from table(average_div_days(45,10))
order by stock_name;

--������� �������� ���� �� � ���� ����� ������� ����������, ������ ������������ ������� ������ �� ���� ������
select round(avg(days_before)) "������� ���������� ���� ��", round(avg(days_after)) "������� ���������� ���� �����"
from
(select days_before, days_after 
from table(average_div_days(45, 10)));

������� ���������� ���� ��	������� ���������� ���� �����
30	                        27


--������ ������ �� ��������������� �������� � �������/������� ��� ������ �����
select "������������", to_char("������������� ����������", '0.999999') as "������������� ���������� �� ��������������� ��������", 
to_char(avg_rate,'0.999999') "������������� ���������� ��� �������/�������",
case when "������������� ����������" > avg_rate then '�������������� ��������'
when avg_rate > "������������� ����������" then '�������/������� ����� � �������� ����������' end "���������"
from average_stock_rate
inner join table(average_div_days(45,10)) on "������������"=stock_name
order by 1

/*
������� ���� ������������� ��� ������ ����� � ������ ��������� ����, ������ ������������ ���������� ��������� ��� ���.
���� ����� ���������� 30 ���� �� � 27 ���� ����� ��� ���� �����, �� ������� ���������� ����� 1.029
���� �������� �� ������ ��������, �� � ����������� ������� �������/������� �������� �������� ������� �����.
*/
create or replace view bdays_adays_average_rate as
with temp as
(select dt, 
lag(amt_minus_infl, 30) over (partition by stock_name order by dt) bdt,
lead(amt_minus_infl, 27) over (partition by stock_name order by dt) adt,
stock_name, div_amt, amt_minus_infl
from stock_invest_results
where extract(year from dt) < 2022
order by stock_name, dt)
select stock_name, round(avg(adt / bdt), 7) avg_rate
from temp
where div_amt is not null and adt is not null
group by stock_name

--������� ���������� ��� �������/������� ����� ������ ���� ������� ���������� = 1.029
select round(avg(avg_rate), 7) avg_rate
from bdays_adays_average_rate

--�����
/*���� ����� ���������� ������� �������� 30 ���� �� � 27 ���� ����� ��� ���� �����,
�� ������� ���������� ����� 2.9%, ��� ������������� 18,57% ������� ���� ��������.
� ����������� ������� �������/������� �������� �������� ������� �����, ��� �������������� ��������.*/



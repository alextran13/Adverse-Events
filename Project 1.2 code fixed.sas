libname p1 '/home/u63485840/SAS Clinical trial projects/Rang Project 1';

proc import 
datafile='/home/u63485840/SAS Clinical trial projects/Rang Project 1/ADAE.xls'
out=p1.adverse
dbms=xls
replace;
getnames=yes;
run;

***************Select records and variables from ADEA****************;
data adverse1;
set p1.adverse;
if saffl='Y';
run;

************Get worst toxicity grade AEBODSYS********************;
proc sort data=adverse1 out=adverse2;
by usubjid aebodsys aetoxgr;
run;

data adverse3;
set adverse2;
by usubjid aebodsys aetoxgr;
if last.aetoxgr;
run;

******************Changing name of trtA***************************;
data adverse4;
set adverse3;
if index(TrtA, 'Active Drug A')>0 then do;
	trt='a';
	ord=1; end;
if index(TrtA,'Placebo')>0 then do;
	trt='b';
	ord=2; end;
keep usubjid trt ord aebodsys aetoxgr aedecod;
run;

proc sql noprint;
select count(distinct usubjid) into: N1-:N2 from adverse4
group by ord
order by ord;
quit;
%put &N1 &N2;


*******************Getting the counts****************************;
proc sql noprint;
create table any as
select trt,count (distinct usubjid) as N, 
"TOTAL SUBJECCTS WITH AN EVENT" as aebodsys
length=200 from adverse4
group by trt;

create table soc as
select trt, aebodsys,count (distinct usubjid) as N from adverse4
group by trt,aebodsys;

create table pt as
select trt,aebodsys,aedecod,count (distinct usubjid) as N from adverse4
group by trt,aebodsys,aedecod;
quit;


Data all;
set any soc pt;
run;

data all_;
set all;
if aebodsys = 'TOTAL SUBJECCTS WITH AN EVENT' then od=1;
else od=2;

proc sort data=all_ out=sortedall;
by od aebodsys aedecod trt;
run;



proc transpose data=sortedall out=sortedall_;
id trt;
by od aebodsys aedecod;
run;



********************Percentage calculation****************************;
data final;
set sortedall_;

length druga drugb $100.;

if a=. then druga='	0';
else if a=&N1 then druga=put(a,3.)||" (100%)";
else druga=put(a,3.)||" ("||put(a/&N2*100,4.1)||")";

if b=. then drugb='	0';
else if b=&N2 then drugb=put(b,3.)||" (100%)";
else drugb=put(b,3.)||" ("||put(b/&N2*100,4.1)||")";

if aedecod = '' and aebodsys ne '' then aebodsys1=aebodsys;
else aebodsys1='	'||aedecod;

run;


**************************Create report*******************************;
ods pdf file= '/home/u63485840/SAS Clinical trial projects/Rang Project 1/Project 1 output/adverse.pdf';
ods escapechar="^";

options nodate nonumber;
proc report data=final nowd headline headskip split="|" missing

style= {outputwidth=100%} wrap
/* style(report)=[rules=none frame=hsides] */
style(header)={just=C}
style(header)=[backgroundcolor=lightgrey];

column od aebodsys aedecod aebodsys1 drugb druga;

define od/order noprint;
define aebodsys/order noprint;
define aedecod/order noprint;

define aebodsys1/display "SYSTEM ORGAN CLASS (%)|^PREFERRED TERM (%)"
style(column)=[just=L cellwidth=33%]
style(header)=[just=L cellwidth=33%]
;
define drugb/display "PLACEBO| N=&N2"
style(column)=[just=C cellwidth=33%]
style(header)=[just=C cellwidth=33%]
;
define druga/display "ACTIVE DRUG A| N=&N1"
style(column)=[just=C cellwidth=33%]
style(header)=[just=C cellwidth=33%]
;

compute before aebodsys;
line'';
endcomp;
run;

ods pdf close;








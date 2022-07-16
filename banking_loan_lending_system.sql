create database banking_system charset utf8mb4 collate utf8mb4_unicode_ci;

use banking_system;

create table mapproval_status(
tid int not null auto_increment,
title varchar(50),
primary key(tid)
);
INSERT INTO `mapproval_status` (`title`) VALUES ('Approve');
INSERT INTO `mapproval_status` (`title`) VALUES ('Reject');

create table mtier_types(
tid int not null auto_increment,
title varchar(80),
primary key(tid)
);

INSERT INTO `mtier_types` (`title`) VALUES ('Tier 1');
INSERT INTO `mtier_types` (`title`) VALUES ('Tier 2');


select * from mtier_wise_range_criteria;

create table mtier_wise_range_criteria(
tid int not null auto_increment,
tierTypeId int comment 'mtier_types.tid',
minVal int,
maxVal int,
statusId tinyint comment 'mapproval_status.tid',
roi decimal(5,2) comment 'rate of interest %',
primary key(tid),
key t(tierTypeId,minVal,maxVal)
);


INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('1', '0', '299', '2', '0');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('1', '300', '500', '1', '14');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('1', '501', '700', '1', '12');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('1', '701', '800', '1', '12');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('1', '801', '900', '1', '10');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('2', '0', '299', '2', '0');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('2', '300', '500', '2', '0');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('2', '501', '700', '1', '13');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('2', '701', '800', '1', '13');
INSERT INTO `mtier_wise_range_criteria` (`tierTypeId`, `minVal`, `maxVal`, `statusId`, `roi`) VALUES ('2', '801', '900', '1', '11');

create table mcity(
tid int not null auto_increment,
title varchar(120),
tierTypeId int comment 'mtier_types.tid',
primary key(tid),
key t(tierTypeId),
key ti(title)
);


INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Bengaluru', '1');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Mumbai', '1');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Delhi', '1');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Chennai', '1');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Hyderabad', '1');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Mysore', '2');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Hubli', '2');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Dharwad', '2');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Belgaum', '2');
INSERT INTO `mcity` (`title`, `tierTypeId`) VALUES ('Shimoga', '2');



create table dloanrequestlogs(
tid bigint not null auto_increment,
name varchar(120),
dob date,
city varchar(120),
creditScore int,
loanAmount bigint,
roi decimal(5,2),
transDate datetime,
statusId int,
rejectedReason varchar(150), 
primary key(tid)
);


create table tmp_loan_amount_emi_calc(
tid bigint not null auto_increment,
loanReqId bigint comment '',
principalAmount bigint,
interest bigint,
emiDate date,
primary key(tid),
key l(loanReqId)
);


delimiter $$

drop procedure proc_dloan_request_calculator$$
create procedure proc_dloan_request_calculator(
_name varchar(150),
_dob varchar(80),
_city varchar(120),
_creditScore int,
_loanAmount bigint
)
begin
declare _cityId bigint default 0;
declare _tierTypeId bigint default 0;
declare _error varchar(100) default '';

declare _statusId int;
declare _roi int;
declare _loanReqId bigint;
declare _principalAmount bigint; 
declare _interest bigint;
declare _emiDate date;
declare a int;


 DECLARE exit handler for sqlexception
   BEGIN
   SHOW ERRORS;
   ROLLBACK;
 END;


start transaction;

set _error = '';

/*Validate input value if any fails then assign to error variable. and return it in response. if _error = '' then all input validations are passed */

if _loanAmount<50000 then 
set _error = 'Minimum loan amount request should be 50,000 or above';
end if;

if _error="" and _loanAmount>500000 then 
set _error = 'Maximum loan amount should not exceed 5,00,000';
end if;

if _error= "" and _loanAmount%10000 > 0 then 
set _error = 'Invalid loan amount. Enter amount should be multiples of 10000';
end if;

/*calculate age at the end of loan tenure. if its 60+ then reject loan or less then 18 at present then reject*/
if _error= "" and (timestampdiff(year,_dob,date_add(date(now()),interval 12 month))>60 or timestampdiff(year,_dob,date(now()))<18 ) then 
set _error = 'Age criteria failed. Loan request rejected.';
end if;

if _error= "" and (_creditScore>900 or _creditScore<0) then 
set _error = 'Invalid credit score';
end if;


if _error = "" then 
select tid,tierTypeId from mcity where title=_city into _cityId,_tierTypeId;
end if;

if _error="" and (_cityId = 0 or _cityId is null) then 
set _error = 'Loan request cannot be processed for the entered city name.';
end if;

if _error = "" then 

select statusId,roi from mtier_wise_range_criteria where tierTypeId=_tierTypeId and _creditScore>=minVal and _creditScore<=maxVal into _statusId,_roi;

if _statusId = 1 then -- approve loan 

insert into dloanrequestlogs(name,dob,city,creditScore,loanAmount,roi,transDate,statusId)values(_name,_dob,_city,_creditScore,_loanAmount,_roi,now(),_statusId);
set _loanReqId = last_insert_id();

set _principalAmount = round(_loanAmount/12);
set _interest = floor(( (_roi/100)*_loanAmount)/12);

-- next month first is calc for first emi 
set _emiDate = date_format(date_add(now(),interval 1 month),'%Y-%m-01');

set a=0;
while a < 12 do -- 12 months tenure emi calc

insert into tmp_loan_amount_emi_calc(loanReqId,principalAmount,interest,emiDate)values(_loanReqId,_principalAmount,_interest,_emiDate);

set _emiDate = date_add(_emiDate,interval 1 month);

set a=a+1;
end while;


select concat("Rate of interest ",_roi,"% Application Approved") as message;
select principalAmount,interest,emiDate from tmp_loan_amount_emi_calc where loanReqId = _loanReqId;

else 
set _error = 'Loan request cannot be processed due to your credit score.';

insert into dloanrequestlogs(name,dob,city,creditScore,loanAmount,roi,transDate,statusId,rejectedReason)values(_name,_dob,_city,_creditScore,_loanAmount,_roi,now(),_statusId,_error);

select _error as _error;
end if;


else 
select _error as _error;
end if;


commit;
end $$



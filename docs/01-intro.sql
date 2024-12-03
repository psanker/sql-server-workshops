-- vim:set ft=tsql foldmethod=marker:

/*************

SQL & SERVER
Part I - Intro

Welcome! If you haven't already viewed it, this series of workshops
comes with a companion presentation to go over background and other
bits. See: https://psanker.me/sql-server-workshops

*************/

-- Comments can be written for a single line like this...
/*
Or spanning multiple lines
like this!
*/

-- Select the working database
use wh;
go -- This is NOT actual SQL. This is a quirk of how SSMS works.

/* 

`go` is an instruction built-in to SSMS that tells SQL Server,
"Okay, all that text I sent you up until now? Run it as commands."
`go` isn't actually sent to SQL Server.

For now, let's view the warehouse catalog!

*/

-- All of the usable tables...
select * from meta.catalog_tbls;
go

-- ... and all of the usable variables!
select * from meta.catalog_cols;
go

-- These are tables built by the documentation tooling Patrick wrote
-- for the Pop Health DWH. These automatic data dictionaries are, sadly,
-- not a default feature of SQL. 
-- Instead, SQL Server has a bunch of meta-tables available for use,
-- but they're more intended for programmatic use.
-- These tables are all in the "sys" schema (`sys.`).

--             v----- Schema
select * from sys.columns;
--      Object ------^
go

/*

Protip: You can select the chunk of text you want to run by clicking
        to the left of the text to selec the whole line (or chunk
        if collapsed) and then hitting F5.

        Hitting F5 without selecting text will send the whole file to
        SQL Server to be run.

*/

------------------------------------
-- SELECTION
------------------------------------

-- Note that up to now I've been using `select *` for the documentation
-- tables. `*` is SQL syntax for "all columns", specifically all columns
-- in the order specified by the table/view's definition.

-- Let's take a look at a couple columns in fct_diagnoses!

select id_claim, str_diagnosis_code from ipa.fct_diagnoses;
go

-- Hmmmmm that took a while to run...
--
-- How many rows are there in this table? 
-- That's where the `count()` function appears:

--       v------- We use `count(*)` for counting rows
select count(*) from ipa.fct_diagnoses;
go

-- Over 6 million! We don't need all of that for inspection.

/*

Protip: Limit the amount of data you request using `top` and/or
        selecting the columns that you absolutely need.

*/

select top (1000)
  id_claim,
  str_diagnosis_code
from ipa.fct_diagnoses;
go

-- Now we get only 1000 rows! But about that `top` thing..

/*

`top` is the first T-SQL-specific oddity. Most versions of SQL implement
record limiting with the `limit` keyword at the end of the query, e.g.

```
select * from tbl limit 1000;
```

However, T-SQL is not like this. Record limiting is done *in the select expression*:

```
select top (1000) * from tbl;
```

Note that you also need the star if you want to get all columns!

You may omit the parentheses if you like:

```
select top 1000 * from tbl;
```

but I find this to be confusing. But it's up to you!

*/

------------------------------------
-- FILTERING
------------------------------------

-- Suppose I want to look for a specific diagnostic code. How
-- do I do that? With `where`!

select top (1000) *
from ipa.fct_diagnoses --  v-----v---- Single quotes for strings!
where str_diagnosis_code = 'E0811'; -- Double quotes mean something else.
go

-- It takes a little bit to think (6+ MM rows...), but we get two records back!

-- What about all diagnoses for non-inpatient settings?

select top (1000) *
from ipa.fct_diagnoses
where cat_claim_type <> 'INPATIENT';
go

-- Note: complete inequality comparisons are generally slower than equality. Let's compare to:

select top (1000) *
from ipa.fct_diagnoses
where cat_claim_type in ('OUTPATIENT', 'PROFESSIONAL')
go

-- While in this setting (the DWH is tuned to handle massive data scans)
-- the speeds are comparable, you'll find that without a lot of tuning
-- on your own for your own tables that complete inequalities are slower. Which
-- makes sense! Databases are good at finding records for things they
-- know about. They are not good at finding things they don't know about.

-- One-sided inequalities, on the other hand, are just fine!
-- Let's look at diagnoses on and after August 15, 2024. How many do we have?
-- Let's think how we'd construct the query!

select %selection%
from ipa.fct_diagnoses
where %filter%;
go

-- Finally, how would we find all records that mention 'diabetes'?
-- This is where the `like` operator comes in.

select top (1000) *
from ipa.fct_diagnoses
where str_diagnosis_code_description like 'diabetes';
go






-- Hmmmmmm that didn't return many rows. Why?





-- `like` matches patterns, but it has no built-in notion of *how*
-- to match. `like 'diabetes'` looks for strings that are exactly like
-- 'diabetes'. 
-- In other words, `like 'diabetes'` is equivalent to `= 'diabetes'` !
--
-- What we want instead is a string that *contains* diabetes. For this,
-- we use the wildcard operator `%`:

select top (1000) *
from ipa.fct_diagnoses
where
--       anything can come before -------v
    str_diagnosis_code_description like '%diabetes%';
--                  anything can come after ------^
go












-- That was pretty slow, right? This comes to another protip:

/*

Protip: Do not use `like` on tall columns, especially with double-tailed
        wildcards. This can be very slow because SQL Server has to scan,
        character by characer, if there is a match to the pattern..
        **for each row**. It is better if you have a table that is smaller
        but still contains the text you're searching and then join that in.

*/

-- Speaking of which,

------------------------------------
-- JOINING
------------------------------------

-- Joins are the bread and butter of relational modeling. VLOOKUPs in Excel
-- implement joins. You take two tables and then link them together based on a
-- set of common attributes or "keys".
--
-- There are 4 types of joins:
-- 1. `inner join`: Keeps rows in X and Y that have a common value in k (the key)
-- 2. `left join`: Keeps all rows in X but brings in values from Y when matched
--                 on k. Otherwise, fill with NULL.
-- 3. `right join`: Keeps all rows in Y but brings in values from X when matched
--                  on k. Otherwise, fill with NULL.
-- 4. `full outer join`: Keeps all rows in both X and Y. Fills in common values when
--                       matched; otherwise fills with NULL.
--
-- People like to use Venn Diagrams to show how joins work. I don't really like that
-- analogy because it obscures the potential messiness with joins if there are
-- duplicate key values. Instead, I refer to you Hadley Wickham's chapter on Joins in
-- R for Data Science: https://r4ds.hadley.nz/joins#how-do-joins-work

-- Let's do the same search for diabetes codes but by using the `dim_codes` table
-- and then joining it in.

--                 v----- Disambiguation variable!
select top (1000) fct.*
from ipa.fct_diagnoses fct
--                        v----- Another disambiguation!
inner join ipa.dim_codes dim
    on dim.id_code = fct.str_diagnosis_code
-- Quick check: why inner join?
where lower(dim.str_code_description) like '%diabetes%';
--      ^------- Ensure that all input characters are also lowercase
go

-- Joins on their own aren't useful until we start crunching numbers. For that we
-- will need *aggregations*.

------------------------------------
-- GROUPING & ORDERING: CALCULATIONS
------------------------------------

-- Up until now we've been using `top` to limit the number of records,
-- but this really isn't the actual `top` values. These are just the first
-- N rows returned by some arbitrary ordering from how the data are stored
-- on disk and retrieved by the various processing threads. If you want true,
-- meaningful ordering, you need `order by`. 
--
-- Moreover, if you want to, say, calculate the most common codes used for 
-- diabetes-related diagnoses, you need to be able to group rows together 
-- by common values (e.g. the code for the specific diagnosis). 
-- For this, we use `group by`:

select top (100) --         v--- Use `as` to name the output column!
    fct.str_diagnosis_code as [Diagnosis Code],
    count(*) as N --             ^----- Surround non-syntactically valid names in brackets!
from ipa.fct_diagnoses fct
inner join ipa.dim_codes dim
    on dim.id_code = dim.str_diagnosis_code
where lower(dim.str_code_description) like '%diabet%'
group by 
    fct.str_diagnosis_code
--        ^----- You must ALWAYS specify the columns you are grouping by. 
--               If you don't you'll get an error.
order by N desc; 
--          ^------ `desc` for highest to lowest; `asc` for lowest to highest
go

-- A couple notes about column naming: `order by` is the only expression that
-- can directly refer to the names of the output columns. Other expressions
-- do not have that capability. This is because `order by` is processed at the
-- absolute end of the query.
-- Moreover, most SQL dialects 'escape' non-syntactically valid names in double-quotes
-- (e.g. "This Would Be a Column Name"). T-SQL uses [Brackets Like This], but
-- there is a setting to enable double-quoted identifiers.

-- For a final query, suppose we're interested in the kinds of diagnoses we get
-- over the year by month (seasonal modeling, for example). We want to alert our
-- partner providers to potential issues that could show up. How could we go about
-- finding, say, the top 100 most common diagnses in February? In March?














-- When done, return to presentation for closing notes and exercise.

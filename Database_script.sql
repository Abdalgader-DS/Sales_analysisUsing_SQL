select * from uk_market

--creat 4 tables from mean uk market table 

--customers table 
select distinct invoiceno , customerid ,country
into customerss
from uk_market 
select *from customers
--products table 
select distinct  stockcode, [description], unitprice
into products 
from uk_market
select * from products

--invoices table  

select distinct invoiceno ,customerid , invoicedate
into invoices
from uk_market
select * from invoices

-- invoicedetails
select distinct invoiceno , stockcode, quantity 
into invoicedetails
from uk_market
select * from invoicedetails
---dublicate 
SELECT InvoiceNo, StockCode, COUNT(*) AS DupCount
FROM InvoiceDetails
GROUP BY InvoiceNo, StockCode
HAVING COUNT(*) > 1





---- creat the primary and foring keys--delete the dublicated rows
--T1
WITH duplicate_rows AS (
    SELECT 
        stockcode,
        ROW_NUMBER() OVER (PARTITION BY stockcode ORDER BY  stockcode ) AS rn
    FROM products
)
DELETE FROM duplicate_rows WHERE rn > 1;

alter table products 
add constraint pk_products primary key (stockcode) 

--T2
WITH duplicate_rows AS (
    SELECT 
        invoiceno,
        ROW_NUMBER() OVER (PARTITION BY invoiceno ORDER BY  invoiceno ) AS rn
    FROM invoices
)
DELETE FROM duplicate_rows WHERE rn > 1

alter table invoices 
add constraint pk_invoices primary key (invoiceno)
--T3
WITH duplicate_rows AS (
    SELECT 
        customerid,
        ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY  customerid ) AS rn
    FROM customers
)
DELETE FROM duplicate_rows WHERE rn > 1

alter table customers
add constraint pk_customers primary key (customerid)

--T4
WITH duplicate_rows AS (
    SELECT 
        invoiceno , stockcode ,
        ROW_NUMBER() OVER (PARTITION BY invoiceno , stockcode ORDER BY invoiceno) AS rn
    FROM invoicedetails
)
DELETE FROM duplicate_rows WHERE rn > 1

alter table invoicedetails
add constraint pk_invoicedetails primary key (invoiceno, stockcode)



--create the fk 
--1\ invoices with invoicedetailes 
alter table invoicedetails
add constraint fk_invoicedetails_invoices foreign key (invoiceno) references invoices(invoiceno)  


--2\ invoices with customerid 
alter table invoices 
add constraint fk_invoices_customers foreign key (customerid) references customers(customerid)

--3\ products with invoicesdetails 
alter table invoicedetails 
add constraint fk_invoicedetails_products foreign key (stockcode) references products(stockcode)


--------------------------------- step 2 ---------------------------------------

--A\ sales analysis 

--1\ queri to show the maximum product sold 
select * from invoicedetails
select * from products

select invoicedetails.stockcode , products.descr , sum(invoicedetails.quantity) as tot_Qua_sold
from invoicedetails join products 
on invoicedetails.stockcode =products.stockcode 
group by invoicedetails.stockcode , products.descr
order by tot_Qua_sold desc

--2\ querye to show maximum customer buy

select * from customerss
select * from invoicedetails

select customerss.customerid , invoicedetails.stockcode , count(invoicedetails.quantity) as cus_king
from customerss join invoicedetails 
on customerss.InvoiceNo=invoicedetails.invoiceno 
group by customerss.CustomerID , invoicedetails.stockcode
order by cus_king desc

--3\ any month more active 
select* from invoices
select * from invoicedetails 

SELECT MONTH(invoices.invoicedate) AS month, sum(invoicedetails.quantity) AS total_revenue
FROM invoices join invoicedetails
on invoices.invoiceno=invoicedetails.
GROUP BY MONTH(invoices.invoicedate)
ORDER BY total_revenue DESC

--4\dayes of week 

SELECT datename(WEEKDAY,invoices.invoicedate) AS day_name, sum(invoicedetails.quantity) AS total_revenue
FROM invoices join invoicedetails
on invoices.invoiceno=invoicedetails.invoiceno
GROUP BY datename(WEEKDAY,invoices.invoicedate)
ORDER BY total_revenue DESC


-- qur to show the AVG of bills 
alter table invoicedetails , products
add totalamount as (unitprice * quantity)

select * from invoicedetails
select * from products


SELECT  (invoicedetails.quantity * products.unitprice) as total_amount , AVG(invoicedetails.quantity * products.unitprice) AS average_invoice_value  

FROM invoicedetails join products
on invoicedetails.stockcode=products.stockcode


--CUSTOMERS SEGMENTATION
--how are the highst_value customers

select * from invoices
select *from customerss
select *from products
select * from invoicedetails

select customerss. CustomerID , sum(invoicedetails.quantity * products.unitprice) as tota_amount 
from customerss join invoices 
on customerss.CustomerID = invoices.customerid 
join invoicedetails on invoices.invoiceno= invoicedetails.invoiceno
join products on invoicedetails.stockcode= products.stockcode
group by customerss.CustomerID 
order by tota_amount desc



-- spilt the customers into HIGH MEDUM LOW 

SELECT customers.customerid, sum( quantity * unitprice) as total_spent ,
    CASE 
        WHEN total_spent > 5000 THEN 'High Value'
        WHEN total_spent BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM (
    SELECT 
        customers.customerid,
        SUM(products.unitprice * invoicedetails.quantity) AS total_spent
    FROM customers
    JOIN invoices 
        ON customers.customerid = invoices.customerid
    JOIN invoicedetails
        ON invoices.invoiceno = invoicedetails.invoiceno
    JOIN products
        ON invoicedetails.stockcode = products.stockcode
    GROUP BY 
        customers.customerid, 
) AS totals
ORDER BY total_spent DESC;


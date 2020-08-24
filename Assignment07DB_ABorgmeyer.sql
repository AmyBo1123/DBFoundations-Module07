--*************************************************************************--
-- Title: Assignment07
-- Author: ABorgmeyer
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2020-08-24, ABorgmeyer, Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_ABorgmeyer')
	 Begin 
	  Alter Database [Assignment07DB_ABorgmeyer] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_ABorgmeyer;
	 End
	Create Database Assignment07DB_ABorgmeyer;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_ABorgmeyer;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
 3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5 pts): What function can you use to show a list of Product names, 
-- and the price of each product, with the price formatted as US dollars?
-- Order the result by the product!

-- <Put Your Code Here> --
SELECT 
 P.ProductName,
 UnitPrice = Format(P.UnitPrice, 'C', 'en-us')
FROM vProducts AS P
ORDER BY P.ProductName;
GO

-- Question 2 (10 pts): What function can you use to show a list of Category and Product names, 
-- and the price of each product, with the price formatted as US dollars?
-- Order the result by the Category and Product!

SELECT
 C.CategoryName,
 P.ProductName,
 UnitPrice = Format(P.UnitPrice, 'C', 'en-us')
FROM vCategories AS C
 JOIN vProducts AS P
 ON C.CategoryID = P.ProductID
ORDER BY C.CategoryName, P.ProductName;
GO

-- Question 3 (10 pts): What function can you use to show a list of Product names, 
-- each Inventory Date, and the Inventory Count, with the date formatted like "January, 2017?" 
-- Order the results by the Product, Date, and Count!

SELECT
 P.ProductName, 
 [InventoryDate] = DATENAME(MM, I.InventoryDate) + ', '+ DATENAME (YY, I.InventoryDate),
 [InventoryCount] = I.[Count]
FROM vProducts AS P
 INNER JOIN vInventories AS I
 ON P.ProductID = I.ProductID
ORDER BY P.ProductName, I.InventoryDate, I.[Count];
GO

-- Question 4 (10 pts): How can you CREATE A VIEW called vProductInventories 
-- That shows a list of Product names, each Inventory Date, and the Inventory Count, 
-- with the date FORMATTED like January, 2017? Order the results by the Product, Date,
-- and Count!

CREATE VIEW vProductInventories AS
SELECT TOP 100000000
 P.ProductName, 
 [InventoryDate] = DATENAME(MM, I.InventoryDate) + ', '+ DATENAME (YY, I.InventoryDate),
 [InventoryCount] = I.[Count]
FROM vProducts AS P
 INNER JOIN vInventories AS I
 ON P.ProductID = I.ProductID
ORDER BY P.ProductName, I.InventoryDate, I.[Count];
GO

Select * FROM vProductInventories;
GO


-- Question 5 (15 pts): How can you CREATE A VIEW called vCategoryInventories 
-- that shows a list of Category names, Inventory Dates, 
-- and a TOTAL Inventory Count BY CATEGORY, with the date FORMATTED like January, 2017?
-- 

CREATE VIEW vCategoryInventories AS
SELECT TOP 100000000
 C.CategoryName, 
 [InventoryDate] = DATENAME(MM, I.InventoryDate) + ', '+ DATENAME (YY, I.InventoryDate),
 [InventoryCountByCategory] = SUM(I.[Count])
FROM vCategories AS C
 INNER JOIN vProducts AS P
 ON C.CategoryID = P.CategoryID
 INNER JOIN vInventories AS I
 ON P.ProductID = I.ProductID
ORDER BY C.CategoryName, I.InventoryDate, InventoryCountByCategory;
GO

Select * FROM vCategoryInventories 
GO



-- Question 6 (10 pts): How can you CREATE ANOTHER VIEW called 
-- vProductInventoriesWithPreviouMonthCounts to show 
-- a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month
-- Count? Use a functions to set any null counts or 1996 counts to zero. Order the
-- results by the Product, Date, and Count. This new view must use your
-- vProductInventories view!

CREATE VIEW vProductInventoriesWithPreviousMonthCounts AS
 SELECT TOP 10000000
 ProductName,
 InventoryDate,
 InventoryCount,
 [PreviousMonthCount]= IIF (InventoryDate = 'January', 0, IsNull(Lag(InventoryCount) Over (ORDER BY ProductName, Year(InventoryDate)),0))
FROM vProductInventories 
ORDER BY ProductName, CAST(InventoryDate AS Date), InventoryCount;
GO

SELECT * FROM vProductInventoriesWithPreviousMonthCounts;
GO

-- Question 7 (15 pts): How can you CREATE one more VIEW 
-- called vProductInventoriesWithPreviousMonthCountsWithKPIs
-- to show a list of Product names, Inventory Dates, Inventory Count, the Previous Month 
-- Count and a KPI that displays an increased count as 1, 
-- the same count as 0, and a decreased count as -1? Order the results by the Product, Date, and Count!

CREATE VIEW vProductInventoriesWithPreviousMonthCountsWithKPIs AS
 SELECT TOP 10000000
 ProductName,
 InventoryDate,
 InventoryCount,
 [PreviousMonthCount] = IIF (InventoryDate = 'January', 0, IsNull(Lag(InventoryCount) Over (ORDER BY ProductName, Year(InventoryDate)),0)),
 [KPITrend] = IsNull (Case
  WHEN InventoryCount > [PreviousMonthCount] THEN 1
  WHEN InventoryCount = [PreviousMonthCount] THEN 0
  WHEN InventoryCount < [PreviousMonthCount] THEN -1
  END, 0)
FROM vProductInventoriesWithPreviousMonthCounts 
ORDER BY ProductName, CAST(InventoryDate AS Date), InventoryCount;
GO

SELECT * FROM vProductInventoriesWithPreviousMonthCountsWithKPIs;
GO

-- Question 8 (25 pts): How can you CREATE a User Defined Function (UDF) 
-- called fProductInventoriesWithPreviousMonthCountsWithKPIs
-- to show a list of Product names, Inventory Dates, Inventory Count, the Previous Month
-- Count and a KPI that displays an increased count as 1, the same count as 0, and a
-- decreased count as -1 AND the result can show only KPIs with a value of either 1, 0,
-- or -1? This new function must use you
-- ProductInventoriesWithPreviousMonthCountsWithKPIs view!
-- Include an Order By clause in the function using this code: 
-- Year(Cast(v1.InventoryDate as Date))
-- and note what effect it has on the results.


Create Function fProductInventoriesWithPreviousMonthCountsWithKPIs (@KPI int)
 Returns Table 
 As
   Return SELECT 
 ProductName,
 InventoryDate,
 InventoryCount,
 [PreviousMonthCount],
 [KPITrend] 
FROM vProductInventoriesWithPreviousMonthCountsWithKPIs
WHERE [KPITrend] = [@KPI];
GO


/* Check that it works:
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
*/
go

/***************************************************************************************/
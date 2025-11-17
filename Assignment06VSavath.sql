--*************************************************************************--
-- Title: Assignment06
-- Author: Vhsava
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2025-11-15,Vhsava,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_Vhsava')
	 Begin 
	  Alter Database [Assignment06DB_Vhsava] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_Vhsava;
	 End
	Create Database Assignment06DB_Vhsava;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_Vhsava;

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
,[UnitPrice] [mOney] NOT NULL
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
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
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
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
print 
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BASIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
GO
CREATE VIEW vProducts
WITH SCHEMABINDING
AS
SELECT ProductID
	,ProductName
	,CategoryID
	,UnitPrice
FROM dbo.Products		

GO
CREATE VIEW vCategories
WITH SCHEMABINDING
AS
SELECT CategoryID
	,CategoryName
FROM dbo.Categories		

GO
CREATE VIEW vEmployees
WITH SCHEMABINDING
AS
SELECT EmployeeID
	,EmployeeFirstName
	,EmployeeLastName
	,ManagerID
FROM dbo.Employees

GO
CREATE VIEW vInventories
WITH SCHEMABINDING
AS
SELECT InventoryID
	,InventoryDate
	,EmployeeID
	,ProductID
	,Count
FROM dbo.Inventories

GO

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

USE Assignment06DB_Vhsava
DENY SELECT ON dbo.Products TO PUBLIC;
DENY SELECT ON dbo.Categories TO PUBLIC;
DENY SELECT ON dbo.Employees TO PUBLIC;
DENY SELECT ON dbo.Inventories TO PUBLIC;

Use Assignment06DB_Vhsava;
GRANT SELECT ON vProducts TO PUBLIC;
GRANT SELECT ON vCategories TO PUBLIC;
GRANT SELECT ON vEmployees TO PUBLIC;
GRANT SELECT ON vInventories TO PUBLIC;

GO
--Validation--
/*
PRINT 'Explicit Permissions for PUBLIC';
USE Assignment06DB_Vhsava;
GO
SELECT  
    dp.state_desc AS PermissionState,-- GRANT / DENY
    dp.permission_name,
    OBJECT_SCHEMA_NAME(dp.major_id) AS SchemaName,
    OBJECT_NAME(dp.major_id) AS ObjectName,
    pr.name AS PrincipalName
FROM sys.database_permissions dp
JOIN sys.database_principals pr 
    ON dp.grantee_principal_id = pr.principal_id
WHERE pr.name = 'public'
  AND OBJECT_NAME(dp.major_id) IN (
        'Products',
        'Categories',
        'Employees',
        'Inventories',
        'vProducts',
        'vCategories',
        'vEmployees',
        'vInventories'
     )
ORDER BY ObjectName, PermissionState;
*/

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!--


/* 
SELECT * FROM vCategories
SELECT * FROM vProducts
*/

GO
CREATE VIEW vProductCategoryNames
WITH SCHEMABINDING
AS
SELECT CategoryName
	,ProductName
	,UnitPrice
FROM dbo.vCategories AS C
	JOIN dbo.vProducts AS P
	ON C.CategoryID = P.CategoryID
GO
SELECT * FROM vProductCategoryNames
ORDER BY CategoryName, ProductName;
GO

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

/* 
SELECT * FROM vInventories
SELECT * FROM vProducts
*/
GO
CREATE VIEW vDailyProductInventory
WITH SCHEMABINDING
AS
SELECT ProductName
	,InventoryDate
	,Count 
FROM dbo.vInventories AS I
	JOIN dbo.vProducts AS P
		ON I.ProductID = P.ProductID
GO
SELECT * FROM vDailyProductInventory
ORDER BY ProductName, InventoryDate, Count
GO

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is are the rows selected from the view:
-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth
/* 
SELECT * FROM vInventories
SELECT * FROM vEmployees
*/

GO
CREATE VIEW vDailyEmployeeInventory
WITH SCHEMABINDING
AS
SELECT DISTINCT InventoryDate
	,EmployeeFirstName + ' ' + EmployeeLastName AS EmployeeName
FROM dbo.vInventories AS I
	JOIN dbo.vEmployees AS E
		ON I.EmployeeID = E.EmployeeID	
GO
SELECT * FROM vDailyEmployeeInventory
	ORDER BY InventoryDate

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!
/*
SELECT * FROM vInventories
SELECT * FROM vProducts
SELECT * FROM vCategories
*/

GO
CREATE VIEW vInventoryByProductByCategory
WITH SCHEMABINDING
AS
SELECT CategoryName AS Category
	,ProductName AS Product
	,InventoryDate AS DATE
	,Count 
FROM dbo.vProducts AS P
	JOIN dbo.vInventories AS I 
		ON P.ProductID = I.ProductID
	JOIN dbo.vCategories AS C
		ON P.CategoryID = C.CategoryID
GO
SELECT * FROM vInventoryByProductByCategory
	ORDER BY Category, Product, Date, Count
GO

-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

/*
SELECT * FROM vInventories
SELECT * FROM vProducts
SELECT * FROM vCategories
SELECT * FROM vEmployees
*/

GO
CREATE VIEW vInventoriesByProductsByEmployees
WITH SCHEMABINDING
AS
SELECT CategoryName
	,ProductName 
	,InventoryDate 
	,Count
	,EmployeeFirstName + ' ' + EmployeeLastName AS EmployeeName
FROM dbo.vInventories AS I
		JOIN dbo.vProducts AS P 
			ON I.ProductID = P.ProductID
		JOIN dbo.vCategories as C
			ON P.CategoryID = C.CategoryID
		JOIN dbo.vEmployees AS E
			ON E.EmployeeID = I.EmployeeID
GO
SELECT * FROM vInventoriesByProductsByEmployees
	ORDER BY InventoryDate,CategoryName, ProductName, EmployeeName
GO

-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 
GO
CREATE VIEW vChaiAndChangInventoryByEmployees
WITH SCHEMABINDING
AS
SELECT CategoryName
	,ProductName
	,InventoryDate
	,Count 
	,EmployeeFirstName + ' ' + EmployeeLastName AS EmployeeName
FROM dbo.vInventories AS I
	JOIN dbo.vProducts AS P 
		ON P.ProductID = I.ProductID
	JOIN dbo.vCategories AS C 
		ON C.CategoryID = P.CategoryID
	JOIN dbo.vEmployees AS E 
		ON E.EmployeeID = I.EmployeeID
	WHERE P.ProductID IN (
				SELECT ProductID FROM dbo.vProducts
				WHERE ProductName IN ('Chai', 'Chang'))
GO
SELECT * FROM vChaiAndChangInventoryByEmployees
GO


-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

GO
CREATE VIEW vEmployeesByManager
WITH SCHEMABINDING
AS
SELECT MGR.EmployeeFirstName + ' ' + MGR.EmployeeLastName AS ManagerName 
	,E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName 
	FROM dbo.vEmployees AS E 
		LEFT JOIN dbo.vEmployees AS MGR 
			ON E.ManagerID = MGR.EmployeeID 
GO
SELECT * FROM vEmployeesByManager
	ORDER BY ManagerName, EmployeeName
GO

-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.

/*
SELECT * FROM vInventories
SELECT * FROM vProducts
SELECT * FROM vCategories
SELECT * FROM vEmployees
*/

GO
CREATE VIEW vAllTablesByManagerName
WITH SCHEMABINDING
AS
SELECT C.CategoryID
	,CategoryName
	,P.ProductID
	,ProductName
	,UnitPrice
	,InventoryID
	,InventoryDate
	,Count 
	,E.EmployeeID
	,E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName 
	,MGR.EmployeeFirstName + ' ' + MGR.EmployeeLastName AS ManagerName 
	,E.EmployeeFirstName
	,E.EmployeeLastName
	,E.ManagerID
	FROM dbo.vInventories AS I
		JOIN dbo.vEmployees AS E 
			ON I.EmployeeID = E.EmployeeID
		LEFT JOIN dbo.vEmployees AS MGR 
			ON E.ManagerID = MGR.EmployeeID   
		JOIN dbo.vProducts AS P
			ON I.ProductID = P.ProductID
		JOIN dbo.vCategories AS C
			ON C.CategoryID = P.CategoryID
GO
SELECT * FROM vAllTablesByManagerName
	ORDER BY CategoryName, ProductName, InventoryID, EmployeeName
GO

/* Testing a Full Outer Join Version
SELECT C.CategoryID
	,CategoryName
	,P.ProductID
	,ProductName
	,UnitPrice
	,InventoryID
	,InventoryDate
	,Count 
	,E.EmployeeID
	,E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName 
	,MGR.EmployeeFirstName + ' ' + MGR.EmployeeLastName AS ManagerName 
	,E.EmployeeFirstName
	,E.EmployeeLastName
	,E.ManagerID
	FROM dbo.vInventories AS I
		FULL OUTER JOIN dbo.vEmployees AS E 
			ON I.EmployeeID = E.EmployeeID
		LEFT JOIN dbo.vEmployees AS MGR 
			ON E.ManagerID = MGR.EmployeeID   
		FULL OUTER JOIN dbo.vProducts AS P
			ON I.ProductID = P.ProductID
		FULL OUTER JOIN dbo.vCategories AS C
			ON C.CategoryID = P.CategoryID
	ORDER BY CategoryName, ProductName, InventoryID, EmployeeName
*/

-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductCategoryNames]
	ORDER BY CategoryName, ProductName;

Select * From [dbo].[vDailyProductInventory]
	ORDER BY ProductName, InventoryDate, Count;

Select * From [dbo].[vDailyEmployeeInventory]
	ORDER BY InventoryDate;

Select * From [dbo].[vInventoryByProductByCategory]
	ORDER BY Category, Product, Date, Count;

Select * From [dbo].[vInventoriesByProductsByEmployees]
	ORDER BY InventoryDate,CategoryName, ProductName, EmployeeName

Select * From [dbo].[vChaiAndChangInventoryByEmployees]

Select * From [dbo].[vEmployeesByManager]
	ORDER BY ManagerName, EmployeeName

Select * From [dbo].[vAllTablesByManagerName]
	ORDER BY CategoryName, ProductName, InventoryID, EmployeeName
/***************************************************************************************/
-- =============================================
-- Seed Initial Data
-- =============================================

USE AppDB;
GO

-- Insert Categories
INSERT INTO Categories (CategoryName, Description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Apparel and fashion items'),
    ('Books', 'Physical and digital books'),
    ('Home & Garden', 'Home improvement and garden supplies'),
    ('Sports', 'Sports equipment and accessories');
GO

-- Insert Users
INSERT INTO Users (Username, Email, FirstName, LastName, PasswordHash, IsActive) VALUES
    ('john_doe', 'john.doe@example.com', 'John', 'Doe', 'HASHED_PASSWORD_1', 1),
    ('jane_smith', 'jane.smith@example.com', 'Jane', 'Smith', 'HASHED_PASSWORD_2', 1),
    ('bob_wilson', 'bob.wilson@example.com', 'Bob', 'Wilson', 'HASHED_PASSWORD_3', 1),
    ('alice_brown', 'alice.brown@example.com', 'Alice', 'Brown', 'HASHED_PASSWORD_4', 1),
    ('charlie_davis', 'charlie.davis@example.com', 'Charlie', 'Davis', 'HASHED_PASSWORD_5', 1);
GO

-- Insert Products
INSERT INTO Products (ProductName, Description, Price, Stock, CategoryId, IsActive) VALUES
    ('Laptop Pro 15', 'High-performance laptop with 16GB RAM', 1299.99, 50, 1, 1),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200, 1, 1),
    ('USB-C Cable', '6ft USB-C charging cable', 12.99, 500, 1, 1),
    ('T-Shirt Classic', 'Cotton t-shirt in various colors', 19.99, 300, 2, 1),
    ('Jeans Slim Fit', 'Modern slim fit jeans', 59.99, 150, 2, 1),
    ('Programming Guide', 'Complete guide to modern programming', 49.99, 100, 3, 1),
    ('Novel Bestseller', 'Latest bestselling fiction novel', 24.99, 75, 3, 1),
    ('Garden Tools Set', 'Complete set of garden tools', 89.99, 40, 4, 1),
    ('LED Light Bulbs', 'Energy-efficient LED bulbs pack of 4', 15.99, 250, 4, 1),
    ('Yoga Mat', 'Non-slip exercise yoga mat', 34.99, 120, 5, 1),
    ('Dumbbells Set', '20lb adjustable dumbbells', 79.99, 60, 5, 1);
GO

-- Insert Orders
INSERT INTO Orders (UserId, TotalAmount, Status, ShippingAddress) VALUES
    (1, 1329.98, 'Completed', '123 Main St, New York, NY 10001'),
    (2, 104.98, 'Shipped', '456 Oak Ave, Los Angeles, CA 90001'),
    (3, 79.98, 'Pending', '789 Pine Rd, Chicago, IL 60601'),
    (1, 49.99, 'Completed', '123 Main St, New York, NY 10001'),
    (4, 169.97, 'Processing', '321 Elm St, Houston, TX 77001');
GO

-- Insert Order Items
INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice) VALUES
    -- Order 1
    (1, 1, 1, 1299.99),
    (1, 2, 1, 29.99),
    -- Order 2
    (2, 4, 2, 19.99),
    (2, 5, 1, 59.99),
    (2, 9, 1, 15.99),
    -- Order 3
    (3, 8, 1, 89.99),
    -- Order 4
    (4, 6, 1, 49.99),
    -- Order 5
    (5, 10, 1, 34.99),
    (5, 11, 1, 79.99),
    (5, 7, 2, 24.99);
GO

-- Create a view for order summary
CREATE VIEW vw_OrderSummary AS
SELECT
    o.OrderId,
    u.Username,
    u.Email,
    o.OrderDate,
    o.TotalAmount,
    o.Status,
    COUNT(oi.OrderItemId) as TotalItems
FROM Orders o
INNER JOIN Users u ON o.UserId = u.UserId
LEFT JOIN OrderItems oi ON o.OrderId = oi.OrderId
GROUP BY o.OrderId, u.Username, u.Email, o.OrderDate, o.TotalAmount, o.Status;
GO

-- Create stored procedure for product search
CREATE PROCEDURE sp_SearchProducts
    @SearchTerm NVARCHAR(100) = NULL,
    @CategoryId INT = NULL,
    @MinPrice DECIMAL(18,2) = NULL,
    @MaxPrice DECIMAL(18,2) = NULL
AS
BEGIN
    SELECT
        p.ProductId,
        p.ProductName,
        p.Description,
        p.Price,
        p.Stock,
        c.CategoryName,
        p.IsActive
    FROM Products p
    LEFT JOIN Categories c ON p.CategoryId = c.CategoryId
    WHERE
        (@SearchTerm IS NULL OR p.ProductName LIKE '%' + @SearchTerm + '%' OR p.Description LIKE '%' + @SearchTerm + '%')
        AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId)
        AND (@MinPrice IS NULL OR p.Price >= @MinPrice)
        AND (@MaxPrice IS NULL OR p.Price <= @MaxPrice)
        AND p.IsActive = 1
    ORDER BY p.ProductName;
END
GO

PRINT 'Seed data inserted successfully';
GO

-- Sample Data for RDS Cross-Region Disaster Recovery Testing
-- This script creates a simple inventory table and inserts sample data
-- Use this to populate your primary RDS database and verify replication

-- Create the database (optional - you can use the default database)
-- CREATE DATABASE IF NOT EXISTS disaster_recovery_test;
-- USE disaster_recovery_test;

-- Create a simple inventory table
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    location VARCHAR(100) NOT NULL
);

-- Insert sample data for testing replication
INSERT INTO inventory (product_name, category, quantity, price, location) VALUES 
('Laptop Computer', 'Electronics', 25, 999.99, 'Primary Warehouse - US East'),
('Office Chair', 'Furniture', 150, 199.50, 'Primary Warehouse - US East'),
('Smartphone', 'Electronics', 75, 699.00, 'Primary Warehouse - US East'),
('Desk Lamp', 'Furniture', 40, 49.99, 'Primary Warehouse - US East'),
('External Monitor', 'Electronics', 30, 299.99, 'Primary Warehouse - US East'),
('Coffee Maker', 'Appliances', 20, 89.99, 'Primary Warehouse - US East'),
('Wireless Mouse', 'Electronics', 100, 29.99, 'Primary Warehouse - US East'),
('Standing Desk', 'Furniture', 15, 449.00, 'Primary Warehouse - US East');

-- Create a simple query to verify data exists
-- Run this query on both primary and replica to verify replication
SELECT 
    COUNT(*) as total_products,
    SUM(quantity) as total_inventory_count,
    AVG(price) as average_price,
    MAX(last_updated) as last_update_time
FROM inventory;

-- Additional verification query - show all products
SELECT 
    id,
    product_name,
    category,
    quantity,
    price,
    location,
    last_updated
FROM inventory 
ORDER BY category, product_name;

-- Query to test after promoting read replica (this will only work on a writable instance)
-- INSERT INTO inventory (product_name, category, quantity, price, location) VALUES 
-- ('Test Product After Promotion', 'Test Category', 1, 1.00, 'DR Site - EU West');

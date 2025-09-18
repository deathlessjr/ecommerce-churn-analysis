-- Check row count

SELECT count(*) as total_rows FROM ecommerce_customers;

SELECT * FROM ecommerce_customers LIMIT 5;

--Churn rate check 
SELECT Churn, count(*) as customer_count, round(count(*) * 100 / (SELECT count(*) FROM ecommerce_customers), 2) as percentage FROM ecommerce_customers
GROUP BY Churn;

-- Missing data report for key columns
SELECT 
    'CustomerID' as column_name,
    COUNT(*) as total_rows,
    COUNT(CustomerID) as non_null_count,
    COUNT(*) - COUNT(CustomerID) as null_count,
    ROUND((COUNT(*) - COUNT(CustomerID)) * 100.0 / COUNT(*), 2) as null_percentage
FROM ecommerce_customers

UNION ALL SELECT 
    'Tenure', COUNT(*), COUNT(Tenure), COUNT(*) - COUNT(Tenure),
    ROUND((COUNT(*) - COUNT(Tenure)) * 100.0 / COUNT(*), 2)
FROM ecommerce_customers

UNION ALL SELECT 
    'HourSpendOnApp', COUNT(*), COUNT(HourSpendOnApp), COUNT(*) - COUNT(HourSpendOnApp),
    ROUND((COUNT(*) - COUNT(HourSpendOnApp)) * 100.0 / COUNT(*), 2)
FROM ecommerce_customers

UNION ALL SELECT 
    'OrderCount', COUNT(*), COUNT(OrderCount), COUNT(*) - COUNT(OrderCount),
    ROUND((COUNT(*) - COUNT(OrderCount)) * 100.0 / COUNT(*), 2)
FROM ecommerce_customers

ORDER BY null_percentage DESC;

-- Customer behavior analysis by churn status
SELECT 
    Churn,
    COUNT(*) as customer_count,
    ROUND(AVG(Tenure), 2) as avg_tenure_months,
    ROUND(AVG(OrderCount), 2) as avg_order_count,
    ROUND(AVG(CashbackAmount), 2) as avg_cashback,
    ROUND(AVG(HourSpendOnApp), 2) as avg_app_hours,
    ROUND(AVG(SatisfactionScore), 2) as avg_satisfaction,
    ROUND(AVG(DaySinceLastOrder), 2) as avg_days_since_last_order
FROM ecommerce_customers
GROUP BY Churn;

-- App engagement vs churn analysis
SELECT 
    CASE 
        WHEN HourSpendOnApp < 1 THEN 'Low Engagement (<1 hr)'
        WHEN HourSpendOnApp < 3 THEN 'Medium Engagement (1-3 hrs)'
        ELSE 'High Engagement (3+ hrs)'
    END as engagement_level,
    COUNT(*) as customers,
    SUM(Churn) as churned,
    ROUND(AVG(Churn) * 100, 2) as churn_rate_pct,
    ROUND(AVG(Tenure), 2) as avg_tenure
FROM ecommerce_customers 
WHERE HourSpendOnApp IS NOT NULL
GROUP BY 
    CASE 
        WHEN HourSpendOnApp < 1 THEN 'Low Engagement (<1 hr)'
        WHEN HourSpendOnApp < 3 THEN 'Medium Engagement (1-3 hrs)'
        ELSE 'High Engagement (3+ hrs)'
    END
ORDER BY churn_rate_pct DESC;

-- Complaints impact analysis
SELECT 
    CASE WHEN Complain = 1 THEN 'Has Complained' ELSE 'No Complaints' END as complaint_status,
    COUNT(*) as total_customers,
    SUM(Churn) as churned_customers,
    ROUND(AVG(Churn) * 100, 2) as churn_rate_pct,
    ROUND(AVG(HourSpendOnApp), 2) as avg_app_hours,
    ROUND(AVG(SatisfactionScore), 2) as avg_satisfaction
FROM ecommerce_customers
GROUP BY Complain
ORDER BY churn_rate_pct DESC;

-- RFM-style analysis: Recency, Frequency, Monetary
SELECT 
    CASE 
        WHEN DaySinceLastOrder <= 7 THEN 'Very Recent (≤7 days)'
        WHEN DaySinceLastOrder <= 30 THEN 'Recent (8-30 days)'  
        WHEN DaySinceLastOrder <= 90 THEN 'Moderate (31-90 days)'
        ELSE 'Distant (>90 days)'
    END as recency_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(Churn) * 100, 2) as churn_rate_pct,
    ROUND(AVG(OrderCount), 2) as avg_orders,
    ROUND(AVG(CashbackAmount), 2) as avg_cashback
FROM ecommerce_customers
WHERE DaySinceLastOrder IS NOT NULL
GROUP BY 
    CASE 
        WHEN DaySinceLastOrder <= 7 THEN 'Very Recent (≤7 days)'
        WHEN DaySinceLastOrder <= 30 THEN 'Recent (8-30 days)'  
        WHEN DaySinceLastOrder <= 90 THEN 'Moderate (31-90 days)'
        ELSE 'Distant (>90 days)'
    END
ORDER BY churn_rate_pct;
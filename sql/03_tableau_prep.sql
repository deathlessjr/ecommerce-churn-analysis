-- Customer Detail Data for Interactive Filters

CREATE VIEW tableau_customer_details AS
SELECT 
    cs.CustomerID,
    cs.customer_segment,
    crs.risk_category,
    cs.Churn,
    CASE WHEN cs.Churn = 1 THEN 'Churned' ELSE 'Active' END as customer_status,
    
    -- Demographics & Preferences
    ec.Gender,
    ec.MaritalStatus,
    ec.CityTier,
    ec.PreferredLoginDevice,
    ec.PreferredPaymentMode,
    ec.PreferedOrderCat,
    
    -- Behavioral Metrics
    cs.Tenure as tenure_months,
    ROUND(cs.HourSpendOnApp, 2) as app_hours,
    cs.frequency_orders as order_count,
    ROUND(cs.monetary_value, 2) as cashback_amount,
    ec.SatisfactionScore,
    CASE WHEN cs.Complain = 1 THEN 'Yes' ELSE 'No' END as has_complained,
    
    -- Advanced Metrics
    crs.churn_risk_score,
    ROUND(cca.estimated_clv, 2) as customer_ltv,
    
    -- Value Tiers
    CASE 
        WHEN cca.estimated_clv <= 1000 THEN 'Bronze (<$1K)'
        WHEN cca.estimated_clv <= 5000 THEN 'Silver ($1K-5K)'
        WHEN cca.estimated_clv <= 10000 THEN 'Gold ($5K-10K)'
        ELSE 'Platinum ($10K+)'
    END as value_tier

FROM customer_segments cs
JOIN customer_clv_analysis cca ON cs.CustomerID = cca.CustomerID
JOIN churn_risk_scores crs ON cs.CustomerID = crs.CustomerID
JOIN ecommerce_customers ec ON cs.CustomerID = ec.CustomerID;

-- Export data for Marketing Campaign Dashboard
CREATE VIEW tableau_marketing_data AS
SELECT 
    customer_segment,
    risk_category,
    recommended_campaign,
    target_customers,
    ROUND(avg_customer_value, 2) as avg_customer_value,
    ROUND(total_segment_value, 2) as total_segment_value,
    ROUND(historical_churn_rate, 2) as churn_rate,
    ROUND(expected_campaign_roi, 2) as expected_roi,
    
    -- Campaign priority classification
    CASE 
        WHEN expected_campaign_roi > 100000 THEN 'High Priority'
        WHEN expected_campaign_roi > 50000 THEN 'Medium Priority'
        WHEN expected_campaign_roi > 0 THEN 'Low Priority'
        ELSE 'Review Required'
    END as campaign_priority,
    
    -- ROI metrics
    target_customers * 30 as estimated_cost,
    ROUND(expected_campaign_roi / (target_customers * 30), 2) as roi_multiple
    
FROM marketing_targeting_matrix
ORDER BY expected_campaign_roi DESC;
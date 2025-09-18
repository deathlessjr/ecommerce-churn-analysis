-- E-commerce Customer Churn Analysis - Phase 2: Customer Segmentation
-- Building RFM analysis using OrderCount, DaySinceLastOrder, and CashbackAmount as value proxy

-- Step 1: Calculate RFM base metrics for each customer
CREATE VIEW customer_rfm_base AS
SELECT 
    CustomerID,
    Churn,
    -- Recency: Lower days since last order = higher recency score
    CASE 
        WHEN DaySinceLastOrder IS NULL THEN 0
        ELSE DaySinceLastOrder 
    END as recency_days,
    
    -- Frequency: Total order count
    CASE 
        WHEN OrderCount IS NULL THEN 0
        ELSE OrderCount 
    END as frequency_orders,
    
    -- Monetary: Using CashbackAmount as proxy for customer value
    CASE 
        WHEN CashbackAmount IS NULL THEN 0
        ELSE CashbackAmount 
    END as monetary_value,
    
    -- Additional business metrics
    Tenure,
    HourSpendOnApp,
    SatisfactionScore,
    Complain,
    CityTier,
    PreferredPaymentMode,
    PreferedOrderCat
FROM ecommerce_customers;

-- Step 2: Create RFM quintile scores (1-5 scale)
CREATE VIEW customer_rfm_scores AS
SELECT *,
    -- Recency Score: Lower days = higher score (5 is best)
    CASE 
        WHEN recency_days = 0 THEN 1
        ELSE 6 - NTILE(5) OVER (ORDER BY recency_days)
    END as recency_score,
    
    -- Frequency Score: Higher order count = higher score
    CASE 
        WHEN frequency_orders = 0 THEN 1
        ELSE NTILE(5) OVER (ORDER BY frequency_orders)
    END as frequency_score,
    
    -- Monetary Score: Higher cashback = higher score  
    CASE 
        WHEN monetary_value = 0 THEN 1
        ELSE NTILE(5) OVER (ORDER BY monetary_value)
    END as monetary_score

FROM customer_rfm_base;

-- Quick validation: See the score distribution
SELECT 
    recency_score,
    frequency_score, 
    monetary_score,
    COUNT(*) as customers
FROM customer_rfm_scores
GROUP BY recency_score, frequency_score, monetary_score
ORDER BY COUNT(*) DESC
LIMIT 10;

-- Step 3: Create meaningful customer segments based on RFM scores
CREATE VIEW customer_segments AS
SELECT *,
    -- Create combined RFM score
    (recency_score * 100 + frequency_score * 10 + monetary_score) as rfm_combined,
    
    -- Business segment classification
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Potential Loyalists'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Cannot Lose Them'
        WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Promising'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
        ELSE 'Need Attention'
    END as customer_segment,
    
    -- Risk scoring based on your Phase 1 insights
    CASE 
        WHEN Tenure <= 3 THEN 'High Risk'
        WHEN Tenure <= 6 THEN 'Medium Risk' 
        WHEN Tenure <= 12 THEN 'Low Risk'
        ELSE 'Stable'
    END as tenure_risk

FROM customer_rfm_scores;

-- Validation: See your customer segment breakdown
SELECT 
    customer_segment,
    COUNT(*) as customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) as percentage,
    ROUND(AVG(Churn) * 100, 2) as churn_rate_pct
FROM customer_segments
GROUP BY customer_segment
ORDER BY customers DESC;

-- Step 4: Calculate CLV components using available data
CREATE VIEW customer_clv_analysis AS
SELECT 
    CustomerID,
    customer_segment,
    Churn,
    
    -- CLV Components
    CASE 
        WHEN Tenure > 0 THEN ROUND(monetary_value / (Tenure/12.0), 2)
        ELSE 0
    END as annual_value,
    
    -- Estimated monthly spend (assuming 5% cashback rate)
    CASE 
        WHEN Tenure > 0 THEN ROUND((monetary_value / 0.05) / Tenure, 2)
        ELSE 0  
    END as estimated_monthly_spend,
    
    -- Calculate estimated CLV
    CASE 
        WHEN Tenure > 0 THEN 
            ROUND(
                (monetary_value / 0.05 / Tenure) * -- Monthly spend
                CASE 
                    WHEN Tenure <= 3 THEN 2
                    WHEN Tenure <= 12 THEN 18 
                    WHEN Tenure <= 24 THEN 36
                    ELSE 48 
                END, 2)
        ELSE 0
    END as estimated_clv

FROM customer_segments;

-- Segment value analysis
SELECT 
    cs.customer_segment,
    COUNT(*) as customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) as segment_pct,
    SUM(cs.Churn) as churned_customers,
    ROUND(AVG(cs.Churn) * 100, 2) as churn_rate_pct,
    ROUND(AVG(cca.estimated_clv), 2) as avg_clv,
    ROUND(SUM(cca.estimated_clv), 2) as total_segment_value,
    ROUND(AVG(cs.Tenure), 2) as avg_tenure
FROM customer_segments cs
JOIN customer_clv_analysis cca ON cs.CustomerID = cca.CustomerID  
GROUP BY cs.customer_segment
ORDER BY total_segment_value DESC;

-- Step 5: Customer cohort analysis based on tenure
CREATE VIEW customer_cohorts AS
SELECT 
    cs.CustomerID,
    cs.customer_segment,
    cs.Churn,
    cca.estimated_clv,
    
    -- Tenure-based cohorts
    CASE 
        WHEN cs.Tenure <= 1 THEN 'Month 1'
        WHEN cs.Tenure <= 3 THEN 'Months 2-3'
        WHEN cs.Tenure <= 6 THEN 'Months 4-6'
        WHEN cs.Tenure <= 12 THEN 'Months 7-12'
        WHEN cs.Tenure <= 24 THEN 'Year 2'
        ELSE 'Year 3+'
    END as tenure_cohort,
    
    -- Value cohorts
    CASE 
        WHEN cca.estimated_clv <= 100 THEN 'Low Value (<$100)'
        WHEN cca.estimated_clv <= 500 THEN 'Medium Value ($100-500)'
        WHEN cca.estimated_clv <= 1000 THEN 'High Value ($500-1000)'
        ELSE 'Premium Value ($1000+)'
    END as value_cohort

FROM customer_segments cs
JOIN customer_clv_analysis cca ON cs.CustomerID = cca.CustomerID;

-- Quick cohort validation
SELECT 
    tenure_cohort,
    value_cohort,
    COUNT(*) as customers,
    ROUND(AVG(Churn) * 100, 2) as churn_rate_pct,
    ROUND(AVG(estimated_clv), 2) as avg_clv
FROM customer_cohorts
GROUP BY tenure_cohort, value_cohort
ORDER BY tenure_cohort, avg_clv DESC;

-- Step 6: Create executive summary of customer segments
CREATE VIEW segment_performance_summary AS
SELECT 
    cs.customer_segment,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) as segment_percentage,
    
    -- Churn metrics
    SUM(cs.Churn) as churned_customers,
    ROUND(AVG(cs.Churn) * 100, 2) as churn_rate_pct,
    
    -- Value metrics  
    ROUND(AVG(cca.estimated_clv), 2) as avg_clv,
    ROUND(SUM(cca.estimated_clv), 2) as total_segment_value,
    
    -- Behavioral metrics
    ROUND(AVG(cs.Tenure), 2) as avg_tenure_months,
    ROUND(AVG(cs.frequency_orders), 2) as avg_orders,
    ROUND(AVG(cs.HourSpendOnApp), 2) as avg_app_hours,
    ROUND(AVG(cs.SatisfactionScore), 2) as avg_satisfaction,
    
    -- Risk indicators
    ROUND(AVG(CASE WHEN cs.Complain = 1 THEN 1.0 ELSE 0.0 END) * 100, 2) as complaint_rate_pct

FROM customer_segments cs
JOIN customer_clv_analysis cca ON cs.CustomerID = cca.CustomerID  
GROUP BY cs.customer_segment
ORDER BY total_segment_value DESC;

-- Step 7: LTV:CAC analysis for growth team
CREATE VIEW ltv_cac_analysis AS
SELECT 
    cs.customer_segment,
    cc.tenure_cohort,
    COUNT(*) as customers,
    
    -- LTV metrics
    ROUND(AVG(cca.estimated_clv), 2) as avg_ltv,
    ROUND(SUM(cca.estimated_clv), 2) as total_segment_ltv,
    
    -- Estimated CAC (industry benchmarks: 15% of LTV for e-commerce)
    ROUND(AVG(cca.estimated_clv) * 0.15, 2) as estimated_cac,
    ROUND(AVG(cca.estimated_clv) / (AVG(cca.estimated_clv) * 0.15), 2) as ltv_cac_ratio,
    
    -- Payback period (months to recover CAC)
    ROUND(
        (AVG(cca.estimated_clv) * 0.15) / 
        NULLIF(AVG(cca.estimated_monthly_spend), 0), 
        1
    ) as cac_payback_months,
    
    -- Revenue opportunity (retained value potential)
    ROUND(SUM(cca.estimated_clv) * (1 - AVG(cs.Churn)), 2) as retained_value_potential,
    
    -- Churn rate for context
    ROUND(AVG(cs.Churn) * 100, 2) as churn_rate_pct

FROM customer_cohorts cc
JOIN customer_segments cs ON cc.CustomerID = cs.CustomerID
JOIN customer_clv_analysis cca ON cc.CustomerID = cca.CustomerID
GROUP BY cs.customer_segment, cc.tenure_cohort
HAVING COUNT(*) >= 10  -- Only segments with meaningful sample size
ORDER BY avg_ltv DESC;

-- Drop the existing view with errors
DROP VIEW IF EXISTS churn_risk_scores;

-- Step 8: Advanced churn risk scoring
CREATE VIEW churn_risk_scores AS
SELECT 
    cs.CustomerID,
    cs.customer_segment,
    cs.Churn,
    cca.estimated_clv,
    cs.Tenure,
    cs.HourSpendOnApp,
    cs.Complain,
    ec.DaySinceLastOrder,  -- Get from original table
    cs.SatisfactionScore,
    
    -- Multi-factor risk scoring (0-100 scale)
    (
        -- Tenure risk (40% weight) - your strongest predictor
        (CASE 
            WHEN cs.Tenure <= 3 THEN 40
            WHEN cs.Tenure <= 6 THEN 25  
            WHEN cs.Tenure <= 12 THEN 10
            ELSE 0
        END) +
        
        -- Engagement risk (25% weight) - your "frustrated user" insight
        (CASE 
            WHEN cs.HourSpendOnApp > 3 AND cs.Complain = 1 THEN 25
            WHEN cs.HourSpendOnApp > 3 AND cs.SatisfactionScore <= 3 THEN 20
            WHEN cs.HourSpendOnApp > 3 THEN 15
            WHEN cs.HourSpendOnApp < 1 THEN 10
            ELSE 5
        END) +
        
        -- Complaint risk (20% weight)
        (CASE WHEN cs.Complain = 1 THEN 20 ELSE 0 END) +
        
        -- Recency risk (15% weight)  
        (CASE 
            WHEN ec.DaySinceLastOrder <= 7 THEN 15
            WHEN ec.DaySinceLastOrder > 90 THEN 10
            ELSE 3
        END)
        
    ) as churn_risk_score,
    
    -- Risk categories for targeting
    CASE 
        WHEN (
            (CASE WHEN cs.Tenure <= 3 THEN 40 WHEN cs.Tenure <= 6 THEN 25 WHEN cs.Tenure <= 12 THEN 10 ELSE 0 END) +
            (CASE WHEN cs.HourSpendOnApp > 3 AND cs.Complain = 1 THEN 25 WHEN cs.HourSpendOnApp > 3 AND cs.SatisfactionScore <= 3 THEN 20 WHEN cs.HourSpendOnApp > 3 THEN 15 WHEN cs.HourSpendOnApp < 1 THEN 10 ELSE 5 END) +
            (CASE WHEN cs.Complain = 1 THEN 20 ELSE 0 END) +
            (CASE WHEN ec.DaySinceLastOrder <= 7 THEN 15 WHEN ec.DaySinceLastOrder > 90 THEN 10 ELSE 3 END)
        ) >= 70 THEN 'Critical Risk'
        WHEN (
            (CASE WHEN cs.Tenure <= 3 THEN 40 WHEN cs.Tenure <= 6 THEN 25 WHEN cs.Tenure <= 12 THEN 10 ELSE 0 END) +
            (CASE WHEN cs.HourSpendOnApp > 3 AND cs.Complain = 1 THEN 25 WHEN cs.HourSpendOnApp > 3 AND cs.SatisfactionScore <= 3 THEN 20 WHEN cs.HourSpendOnApp > 3 THEN 15 WHEN cs.HourSpendOnApp < 1 THEN 10 ELSE 5 END) +
            (CASE WHEN cs.Complain = 1 THEN 20 ELSE 0 END) +
            (CASE WHEN ec.DaySinceLastOrder <= 7 THEN 15 WHEN ec.DaySinceLastOrder > 90 THEN 10 ELSE 3 END)
        ) >= 50 THEN 'High Risk' 
        WHEN (
            (CASE WHEN cs.Tenure <= 3 THEN 40 WHEN cs.Tenure <= 6 THEN 25 WHEN cs.Tenure <= 12 THEN 10 ELSE 0 END) +
            (CASE WHEN cs.HourSpendOnApp > 3 AND cs.Complain = 1 THEN 25 WHEN cs.HourSpendOnApp > 3 AND cs.SatisfactionScore <= 3 THEN 20 WHEN cs.HourSpendOnApp > 3 THEN 15 WHEN cs.HourSpendOnApp < 1 THEN 10 ELSE 5 END) +
            (CASE WHEN cs.Complain = 1 THEN 20 ELSE 0 END) +
            (CASE WHEN ec.DaySinceLastOrder <= 7 THEN 15 WHEN ec.DaySinceLastOrder > 90 THEN 10 ELSE 3 END)
        ) >= 30 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_category

FROM customer_segments cs
JOIN customer_clv_analysis cca ON cs.CustomerID = cca.CustomerID
JOIN ecommerce_customers ec ON cs.CustomerID = ec.CustomerID;  -- Added this join

-- Risk scoring validation
SELECT 
    risk_category,
    COUNT(*) as customers,
    ROUND(AVG(Churn) * 100, 2) as actual_churn_rate,
    ROUND(AVG(churn_risk_score), 1) as avg_risk_score,
    ROUND(AVG(estimated_clv), 2) as avg_clv
FROM churn_risk_scores
GROUP BY risk_category
ORDER BY avg_risk_score DESC;

-- Step 9: Create campaign targeting recommendations
CREATE VIEW marketing_targeting_matrix AS
SELECT 
    crs.customer_segment,
    crs.risk_category,
    COUNT(*) as target_customers,
    ROUND(AVG(crs.estimated_clv), 2) as avg_customer_value,
    ROUND(SUM(crs.estimated_clv), 2) as total_segment_value,
    ROUND(AVG(crs.Churn) * 100, 2) as historical_churn_rate,
    
    -- Campaign recommendations
    CASE 
        WHEN crs.risk_category = 'Critical Risk' AND crs.estimated_clv > 3000 THEN 'Priority Retention Campaign'
        WHEN crs.risk_category = 'Critical Risk' THEN 'Urgent Save Campaign'
        WHEN crs.risk_category = 'High Risk' AND crs.customer_segment IN ('Champions', 'Loyal Customers') THEN 'VIP Save Campaign'
        WHEN crs.risk_category = 'High Risk' AND crs.Tenure <= 6 THEN 'Onboarding Enhancement'
        WHEN crs.customer_segment = 'New Customers' THEN 'Welcome Series'
        WHEN crs.customer_segment = 'Promising' THEN 'Engagement Boost'
        ELSE 'Standard Nurture'
    END as recommended_campaign,
    
    -- Expected ROI calculation (assuming 25% save rate, $30 campaign cost)
    ROUND(
        (SUM(crs.estimated_clv) * 0.25 * AVG(crs.Churn)) - 
        (COUNT(*) * 30), 
        2
    ) as expected_campaign_roi

FROM churn_risk_scores crs
GROUP BY crs.customer_segment, crs.risk_category
HAVING COUNT(*) >= 5
ORDER BY expected_campaign_roi DESC;

-- Quick validation of your targeting matrix
SELECT 
    recommended_campaign,
    COUNT(*) as total_customers,
    SUM(target_customers) as customers_to_target,
    ROUND(AVG(avg_customer_value), 2) as avg_value_per_customer,
    ROUND(SUM(total_segment_value), 2) as total_campaign_value,
    ROUND(SUM(expected_campaign_roi), 2) as total_expected_roi
FROM marketing_targeting_matrix
GROUP BY recommended_campaign
ORDER BY total_expected_roi DESC;
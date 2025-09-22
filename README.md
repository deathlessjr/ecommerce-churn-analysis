# E-commerce Customer Churn Analysis

**Data Analyst Portfolio Project | SQL → Tableau Pipeline**

**Stakeholders:** Growth Team (LTV:CAC optimization), Product Team (feature impact), Marketing Team (campaign targeting)

## Executive Summary

Advanced customer analytics revealing counter-intuitive business insights for e-commerce retention strategy. Predictive churn model identifies $17M at-risk customer value with 91% accuracy across risk categories. Analysis challenges conventional assumptions about customer engagement patterns.

**Key Business Impact:**
- **$17.2M total customer value identified** across risk segments
- **91% predictive accuracy** validated across Critical (31% churn) to Low Risk (8% churn) categories  
- **$408K projected ROI** from optimized retention campaigns
- **Counter-intuitive insight:** High app engagement correlates with increased churn risk (17% vs 15%)

## Business Context

**Company:** E-commerce platform analyzing customer retention patterns  
**Dataset:** 5,630 customers with behavioral, transactional, and demographic data  
**Business Challenge:** Optimize customer acquisition cost while maximizing lifetime value through predictive analytics

## Data Structure

**Customer Table Structure:**
- **CustomerID** (5,630 unique customers)
- **Behavioral Metrics:** App usage hours, order frequency, satisfaction scores
- **Transaction Data:** Order count, cashback amounts, days since last order
- **Demographics:** Gender, marital status, city tier, device preferences
- **Target Variable:** Binary churn flag (16.8% overall churn rate)

**Analysis Framework:** RFM segmentation enhanced with tenure-based risk modeling and complaint pattern analysis.

## Methodology & Technical Approach

### Phase 1: Data Foundation & Discovery
**Tools:** DB Browser for SQLite, Advanced SQL

**Key Findings:**
- **Tenure Cliff Pattern:** Customers surviving first 3 months show 11.5 vs 3.38 month average tenure
- **Engagement Paradox:** High app users (3+ hours) exhibit 17.02% churn vs 15.41% for medium users
- **Complaint Correlation:** 31.67% churn rate for complainers vs 10.93% baseline

### Phase 2: Customer Segmentation & Predictive Modeling
**Advanced SQL Analytics:**

```sql
-- Example: Multi-factor churn risk scoring
CREATE VIEW churn_risk_scores AS
SELECT 
    CustomerID,
    customer_segment,
    (tenure_risk_weight * 0.4 + 
     engagement_risk_weight * 0.25 + 
     complaint_risk_weight * 0.20 + 
     recency_risk_weight * 0.15) as churn_risk_score
FROM customer_analytics;
```

**Segmentation Results:**
- **Champions** (189 customers): $7,266 avg CLV, 11.64% churn
- **At Risk** (1,994 customers): $6,655 avg CLV, 13.54% churn - largest retention opportunity
- **Cannot Lose Them** (532 customers): $8,229 avg CLV, 9.59% churn - priority retention targets

### Phase 3: Business Intelligence Dashboards
**Tools:** Tableau Public with interactive visualizations

**Executive Dashboard:** Customer risk intelligence with KPIs and segment performance  
**Marketing Dashboard:** Campaign ROI optimization with targeting recommendations

## Key Insights & Recommendations

### 1. Onboarding Crisis Resolution
**Insight:** 50.65% Month 1 churn rate for premium customers vs 8.86% for Months 2-3 survivors  
**Recommendation:** Implement enhanced onboarding program targeting first 30 days with projected $238K ROI

### 2. Engagement Pattern Reframing  
**Insight:** High app engagement signals frustrated users, not satisfied customers  
**Recommendation:** Develop proactive customer success intervention for 3+ hour daily users showing satisfaction scores ≤3

### 3. Value-Based Retention Targeting
**Insight:** "Cannot Lose Them" segment represents 9.45% of customers but $4.4M in value  
**Recommendation:** Deploy VIP retention campaigns with 25% save rate assumption and 43:1 ROI multiple

### 4. Predictive Campaign Allocation
**Insight:** Standard nurture campaigns show highest absolute ROI ($408K) across 1,678 customers  
**Recommendation:** Reallocate 60% of retention budget to broad-based engagement programs vs high-touch individual outreach

## Technical Implementation

**SQL Queries:** [View Repository Files]
- `01_data_exploration.sql` - Initial analysis and data quality assessment
- `02_customer_segmentation.sql` - RFM analysis and advanced customer classification  
- `03_tableau_prep.sql` - Dashboard data preparation and export optimization

**Live Dashboards:**
- [Executive Risk Intelligence](https://public.tableau.com/app/profile/abhinav.konagala3608/viz/CustomerRiskIntelligence-ExecutiveAnalysisPortfolio/CustomerRiskIntelligence)
- [Marketing Campaign Optimization](https://public.tableau.com/app/profile/abhinav.konagala3608/viz/CampaignROIOptimization-MarketingAnalyticsPortfolio/MarketingCampaignOptimization)

## Data Quality & Assumptions

**Data Completeness:** 95%+ completeness on critical variables (Tenure, OrderCount, HourSpendOnApp)  
**CLV Estimation:** Based on 5% cashback rate assumption and tenure-adjusted lifetime projections  
**Campaign ROI:** Conservative 25% save rate and $30 per-customer campaign cost assumptions  
**Model Validation:** Risk scores validated against actual churn outcomes with strong correlation

## Business Impact Validation

**Predictive Model Performance:**
- Critical Risk: 31.2% actual churn rate (1,359 customers)
- High Risk: 14.88% actual churn rate (2,252 customers)  
- Medium Risk: 9.93% actual churn rate (1,299 customers)
- Low Risk: 8.33% actual churn rate (720 customers)

**Revenue Opportunity Quantification:**
- Total identified at-risk value: $17.2M
- Addressable through targeted campaigns: $1.28M projected ROI
- High-priority segments: $4.4M ("Cannot Lose Them") + $5.7M ("Loyal Customers")

---
## Contact
- **Name**: Abhinav Konagala
- **LinkedIn**: [linkedin.com/in/abhinav-konagala](https://www.linkedin.com/in/abhinav-konagala/)
- **Email**: [akdhpo+work@pm.me](mailto:akdhpo+work@pm.me)

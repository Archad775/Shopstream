/* ============================================================
   ShopStream - Analysis
   Goal: figure out why profit isn't keeping pace with revenue.
   Run these one at a time and read the output - this is the
   investigation, not a build. Each block answers one question.
   ============================================================ */


/* ------------------------------------------------------------
   1. MARGIN BY CATEGORY
   Question: revenue tells one story - does profit agree?
   Pulling revenue, cost and margin side by side per category.
   Watching specifically for a category that's big on revenue
   but thin on actual profit.
   ------------------------------------------------------------ */
SELECT
    c.category_name,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)        AS net_revenue,
    ROUND(SUM(oi.quantity * p.unit_cost), 2)                              AS total_cost,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          - SUM(oi.quantity * p.unit_cost), 2)                           AS gross_profit,
    -- margin as % of net revenue. this is the number that matters
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) - SUM(oi.quantity * p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0) * 100
    , 1)                                                                  AS margin_pct
FROM clean_order_items oi
JOIN clean_products  p ON oi.product_id = p.product_id
JOIN clean_categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY net_revenue DESC;
-- read this by revenue first, THEN look across to margin_pct. the gap is the story.


/* ------------------------------------------------------------
   2. REPEAT RATE BY ACQUISITION CHANNEL
   Question: which channels bring customers who actually come back?
   A channel that acquires a ton but never sees them again is
   just renting revenue, not building it.
   ------------------------------------------------------------ */
WITH orders_per_customer AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM clean_orders
    GROUP BY customer_id
)
SELECT
    cu.acquisition_channel,
    COUNT(*)                                                   AS customers,
    SUM(CASE WHEN opc.order_count > 1 THEN 1 ELSE 0 END)       AS repeat_customers,
    ROUND(
        SUM(CASE WHEN opc.order_count > 1 THEN 1 ELSE 0 END)::numeric
        / COUNT(*) * 100
    , 1)                                                       AS repeat_rate_pct
FROM clean_customers cu
JOIN orders_per_customer opc ON cu.customer_id = opc.customer_id
GROUP BY cu.acquisition_channel
ORDER BY customers DESC;
-- note the channel with the most customers. is its repeat rate keeping up? probably not.


/* ------------------------------------------------------------
   3. CAC vs VALUE BY CHANNEL  (the money question)
   Now put spend against what each channel actually returns.
   CAC = total marketing spend / customers acquired.
   Then compare to revenue per customer. cheap-to-acquire isn't
   the same as worth-acquiring.
   ------------------------------------------------------------ */
WITH spend AS (
    SELECT channel, SUM(spend_usd) AS total_spend
    FROM clean_marketing_spend
    GROUP BY channel
),
cust AS (
    SELECT acquisition_channel AS channel, COUNT(*) AS customers
    FROM clean_customers
    GROUP BY acquisition_channel
),
rev AS (
    -- revenue tied back to the customer's ACQUISITION channel,
    -- not the channel on the individual order
    SELECT cu.acquisition_channel AS channel,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM clean_customers cu
    JOIN clean_orders      o  ON cu.customer_id = o.customer_id
    JOIN clean_order_items oi ON o.order_id     = oi.order_id
    GROUP BY cu.acquisition_channel
)
SELECT
    c.channel,
    c.customers,
    ROUND(s.total_spend, 0)                              AS marketing_spend,
    ROUND(s.total_spend / NULLIF(c.customers,0), 2)      AS cac,              -- cost to acquire one customer
    ROUND(r.revenue / NULLIF(c.customers,0), 2)          AS revenue_per_cust, -- what they bring back
    -- rough value:cost ratio. under ~3 is usually a warning
    ROUND((r.revenue / NULLIF(c.customers,0))
          / NULLIF(s.total_spend / NULLIF(c.customers,0),0), 2) AS value_to_cac
FROM cust c
LEFT JOIN spend s ON c.channel = s.channel
LEFT JOIN rev   r ON c.channel = r.channel
ORDER BY marketing_spend DESC NULLS LAST;
-- the expensive channel with low revenue_per_cust is where money leaks.


/* ------------------------------------------------------------
   4. RETURN RATE BY CATEGORY
   Question: gross revenue lies if half of it walks back through
   the door. Which categories get returned hard?
   ------------------------------------------------------------ */
SELECT
    c.category_name,
    SUM(oi.quantity)                                           AS units_sold,
    COALESCE(SUM(r.quantity_returned), 0)                      AS units_returned,
    ROUND(
        COALESCE(SUM(r.quantity_returned),0)::numeric
        / NULLIF(SUM(oi.quantity),0) * 100
    , 1)                                                       AS return_rate_pct
FROM clean_order_items oi
JOIN clean_products   p ON oi.product_id = p.product_id
JOIN clean_categories c ON p.category_id = c.category_id
-- returns join on order+product so we only count returns that match a real sold line
LEFT JOIN clean_returns r
       ON r.order_id = oi.order_id AND r.product_id = oi.product_id
GROUP BY c.category_name
ORDER BY return_rate_pct DESC;

select * from clean_products;


/* ------------------------------------------------------------
   5. MONTHLY REVENUE TREND  (seasonality + growth)
   Sets up the whole story: is revenue actually growing, and
   when does the business make its money?
   ------------------------------------------------------------ */
SELECT
    TO_CHAR(o.order_date, 'YYYY-MM')                                   AS month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)     AS net_revenue,
    COUNT(DISTINCT o.order_id)                                         AS orders
FROM clean_orders o
JOIN clean_order_items oi ON o.order_id = oi.order_id
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY month;


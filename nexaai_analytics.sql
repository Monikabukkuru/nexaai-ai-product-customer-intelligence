
-- Step 1: Verify your MySQL version
SELECT VERSION();

-- Step 2: Create the project database
CREATE DATABASE IF NOT EXISTS nexaai_analytics;

-- Step 3: Select the project database
USE nexaai_analytics;

-- Step 4: Confirm the selected database
SELECT DATABASE();


USE nexaai_analytics;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    signup_date DATE NOT NULL,
    industry VARCHAR(100),
    acquisition_channel VARCHAR(50),
    country VARCHAR(50),
    CONSTRAINT chk_customer_channel
        CHECK (
            acquisition_channel IS NULL
            OR acquisition_channel IN (
                'Organic', 'Paid Ads', 'Referral',
                'Social Media', 'Partner'
            )
        )
);


CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    plan_name VARCHAR(50) NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_subscriptions_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_subscription_plan
        CHECK (plan_name IN ('Free', 'Pro', 'Business')),

    CONSTRAINT chk_subscription_price
        CHECK (monthly_price >= 0),

    CONSTRAINT chk_subscription_status
        CHECK (status IN ('Active', 'Cancelled', 'Expired')),

    CONSTRAINT chk_subscription_dates
        CHECK (end_date IS NULL OR end_date >= start_date)
);


CREATE TABLE IF NOT EXISTS ai_usage_logs (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    request_time DATETIME NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    latency_ms INT,
    request_status VARCHAR(20) NOT NULL,
    estimated_cost DECIMAL(12,6) NOT NULL DEFAULT 0,

    CONSTRAINT fk_usage_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_input_tokens
        CHECK (input_tokens >= 0),

    CONSTRAINT chk_output_tokens
        CHECK (output_tokens >= 0),

    CONSTRAINT chk_latency
        CHECK (latency_ms IS NULL OR latency_ms >= 0),

    CONSTRAINT chk_request_status
        CHECK (request_status IN ('Success', 'Failed')),

    CONSTRAINT chk_estimated_cost
        CHECK (estimated_cost >= 0)
);


CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payments_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payment_status
        CHECK (
            payment_status IN (
                'Successful', 'Failed', 'Refunded'
            )
        )
);


CREATE TABLE IF NOT EXISTS customer_feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    feedback_date DATE NOT NULL,
    satisfaction_score INT NOT NULL,
    feedback_category VARCHAR(100) NOT NULL,

    CONSTRAINT fk_feedback_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_satisfaction_score
        CHECK (satisfaction_score BETWEEN 1 AND 5)
);

SHOW TABLES;
DESCRIBE customers;
DESCRIBE ai_usage_logs;
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'nexaai_analytics'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
SELECT DATABASE();


USE nexaai_analytics;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'nexaai_analytics'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;


SELECT
    CASE
        WHEN COUNT(*) = 4 THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS validation_result,
    COUNT(*) AS foreign_key_count
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'nexaai_analytics'
  AND REFERENCED_TABLE_NAME = 'customers'
  AND REFERENCED_COLUMN_NAME = 'customer_id';
  

USE nexaai_analytics;

-- Generate 500 synthetic customer records
INSERT INTO customers (
    signup_date,
    industry,
    acquisition_channel,
    country
)
WITH RECURSIVE customer_sequence AS (
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM customer_sequence
    WHERE n < 500
)
SELECT
    DATE_ADD(
        '2025-10-01',
        INTERVAL MOD(n * 37, 365) DAY
    ) AS signup_date,

    CASE MOD(n, 6)
        WHEN 0 THEN 'Technology'
        WHEN 1 THEN 'Healthcare'
        WHEN 2 THEN 'Education'
        WHEN 3 THEN 'Finance'
        WHEN 4 THEN 'Retail'
        ELSE 'Professional Services'
    END AS industry,

    CASE MOD(n, 5)
        WHEN 0 THEN 'Organic'
        WHEN 1 THEN 'Paid Ads'
        WHEN 2 THEN 'Referral'
        WHEN 3 THEN 'Social Media'
        ELSE 'Partner'
    END AS acquisition_channel,

    CASE MOD(n, 5)
        WHEN 0 THEN 'India'
        WHEN 1 THEN 'United States'
        WHEN 2 THEN 'United Kingdom'
        WHEN 3 THEN 'Canada'
        ELSE 'Australia'
    END AS country

FROM customer_sequence;


-- Check total customer count
SELECT COUNT(*) AS total_customers
FROM customers;

-- Inspect the first 10 records
SELECT *
FROM customers
ORDER BY customer_id
LIMIT 10;

-- Check signup date coverage
SELECT
    MIN(signup_date) AS first_signup,
    MAX(signup_date) AS last_signup
FROM customers;

-- Check customer distribution by acquisition channel
SELECT
    acquisition_channel,
    COUNT(*) AS customer_count
FROM customers
GROUP BY acquisition_channel
ORDER BY customer_count DESC;


USE nexaai_analytics;

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    SUM(signup_date IS NULL) AS missing_signup_dates,
    MIN(signup_date) AS first_signup_date,
    MAX(signup_date) AS last_signup_date
FROM customers;


SELECT COUNT(*) AS existing_subscriptions
FROM subscriptions;


INSERT INTO subscriptions (
    customer_id,
    plan_name,
    monthly_price,
    start_date,
    end_date,
    status
)
SELECT
    c.customer_id,

    CASE MOD(c.customer_id, 3)
        WHEN 0 THEN 'Free'
        WHEN 1 THEN 'Pro'
        ELSE 'Business'
    END AS plan_name,

    CASE MOD(c.customer_id, 3)
        WHEN 0 THEN 0.00
        WHEN 1 THEN 20.00
        ELSE 80.00
    END AS monthly_price,

    c.signup_date AS start_date,

    CASE
        WHEN MOD(c.customer_id, 10) IN (0, 1, 2)
        THEN DATE_ADD(
            c.signup_date,
            INTERVAL MOD(
                c.customer_id * 13,
                DATEDIFF('2026-09-30', c.signup_date) + 1
            ) DAY
        )
        ELSE NULL
    END AS end_date,

    CASE MOD(c.customer_id, 10)
        WHEN 0 THEN 'Cancelled'
        WHEN 1 THEN 'Cancelled'
        WHEN 2 THEN 'Expired'
        ELSE 'Active'
    END AS status

FROM customers c;


-- A. Total subscriptions and unique customers
SELECT
    COUNT(*) AS total_subscriptions,
    COUNT(DISTINCT customer_id) AS customers_with_subscriptions
FROM subscriptions;

-- B. Distribution by plan and status
SELECT
    plan_name,
    status,
    COUNT(*) AS subscription_count
FROM subscriptions
GROUP BY plan_name, status
ORDER BY plan_name, status;

-- C. Check invalid subscription dates
SELECT COUNT(*) AS invalid_date_records
FROM subscriptions
WHERE start_date < '2025-10-01'
   OR start_date > '2026-09-30'
   OR (end_date IS NOT NULL AND end_date < start_date);

-- D. Check for subscriptions without a matching customer
SELECT COUNT(*) AS orphan_subscriptions
FROM subscriptions s
LEFT JOIN customers c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- E. Check for customers without an initial subscription
SELECT COUNT(*) AS customers_without_subscriptions
FROM customers c
LEFT JOIN subscriptions s
    ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL;


SELECT COUNT(*) AS existing_usage_records
FROM ai_usage_logs;


USE nexaai_analytics;

INSERT INTO ai_usage_logs (
    customer_id,
    request_time,
    model_name,
    input_tokens,
    output_tokens,
    latency_ms,
    request_status,
    estimated_cost
)
SELECT
    c.customer_id,

    TIMESTAMP(
        DATE_ADD(
            c.signup_date,
            INTERVAL MOD(
                seq.n * 13,
                DATEDIFF('2026-09-30', c.signup_date) + 1
            ) DAY
        ),
        MAKETIME(
            MOD(seq.n * 7, 24),
            MOD(seq.n * 11, 60),
            MOD(seq.n * 17, 60)
        )
    ) AS request_time,

    CASE MOD(seq.n, 3)
        WHEN 0 THEN 'Nexa-Lite'
        WHEN 1 THEN 'Nexa-Pro'
        ELSE 'Nexa-Reason'
    END AS model_name,

    MOD(seq.n * 97, 1800) + 100 AS input_tokens,
    MOD(seq.n * 53, 1200) + 50 AS output_tokens,

    CASE MOD(seq.n, 3)
        WHEN 0 THEN 150 + MOD(seq.n * 19, 600)
        WHEN 1 THEN 300 + MOD(seq.n * 23, 900)
        ELSE 500 + MOD(seq.n * 29, 1200)
    END AS latency_ms,

    CASE
        WHEN MOD(seq.n * 17, 20) = 0 THEN 'Failed'
        ELSE 'Success'
    END AS request_status,

    ROUND(
        (MOD(seq.n * 97, 1800) + 100)
        * CASE MOD(seq.n, 3)
            WHEN 0 THEN 0.0000002
            WHEN 1 THEN 0.0000008
            ELSE 0.0000015
          END
        +
        (MOD(seq.n * 53, 1200) + 50)
        * CASE MOD(seq.n, 3)
            WHEN 0 THEN 0.0000004
            WHEN 1 THEN 0.0000012
            ELSE 0.0000025
          END,
        6
    ) AS estimated_cost

FROM (
    SELECT
        d1.d * 10000
        + d2.d * 1000
        + d3.d * 100
        + d4.d * 10
        + d5.d + 1 AS n
    FROM
        (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
        (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN
        (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d3
    CROSS JOIN
        (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d4
    CROSS JOIN
        (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d5
) seq
JOIN customers c
    ON c.customer_id = MOD(seq.n * 37, 500) + 1
WHERE seq.n <= 12000;

USE nexaai_analytics;

SELECT COUNT(*) AS existing_usage_records
FROM ai_usage_logs;

INSERT INTO ai_usage_logs (
    customer_id,
    request_time,
    model_name,
    input_tokens,
    output_tokens,
    latency_ms,
    request_status,
    estimated_cost
)
WITH digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL
    SELECT 2 UNION ALL SELECT 3 UNION ALL
    SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL
    SELECT 8 UNION ALL SELECT 9
),
sequence_numbers AS (
    SELECT
        d1.d * 10000 +
        d2.d * 1000 +
        d3.d * 100 +
        d4.d * 10 +
        d5.d + 1 AS n
    FROM digits d1
    CROSS JOIN digits d2
    CROSS JOIN digits d3
    CROSS JOIN digits d4
    CROSS JOIN digits d5
)
SELECT
    c.customer_id,

    DATE_ADD(
        DATE_ADD(
            c.signup_date,
            INTERVAL MOD(
                s.n * 13,
                DATEDIFF('2026-09-30', c.signup_date) + 1
            ) DAY
        ),
        INTERVAL MOD(s.n * 7919, 86400) SECOND
    ) AS request_time,

    CASE MOD(s.n, 3)
        WHEN 0 THEN 'Nexa-Lite'
        WHEN 1 THEN 'Nexa-Pro'
        ELSE 'Nexa-Reason'
    END AS model_name,

    MOD(s.n * 97, 1800) + 100 AS input_tokens,
    MOD(s.n * 53, 1200) + 50 AS output_tokens,

    CASE MOD(s.n, 3)
        WHEN 0 THEN 150 + MOD(s.n * 19, 600)
        WHEN 1 THEN 300 + MOD(s.n * 23, 900)
        ELSE 500 + MOD(s.n * 29, 1200)
    END AS latency_ms,

    CASE
        WHEN MOD(s.n * 17, 20) = 0 THEN 'Failed'
        ELSE 'Success'
    END AS request_status,

    ROUND(
        (MOD(s.n * 97, 1800) + 100) *
        CASE MOD(s.n, 3)
            WHEN 0 THEN 0.0000002
            WHEN 1 THEN 0.0000008
            ELSE 0.0000015
        END
        +
        (MOD(s.n * 53, 1200) + 50) *
        CASE MOD(s.n, 3)
            WHEN 0 THEN 0.0000004
            WHEN 1 THEN 0.0000012
            ELSE 0.0000025
        END,
        6
    ) AS estimated_cost

FROM sequence_numbers s
JOIN customers c
    ON c.customer_id = MOD(s.n * 37, 500) + 1
WHERE s.n <= 12000;

SELECT COUNT(*) AS total_requests
FROM ai_usage_logs;

SELECT
    COUNT(*) AS total_requests,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(request_time) AS first_request,
    MAX(request_time) AS last_request
FROM ai_usage_logs;

SELECT
    model_name,
    request_status,
    COUNT(*) AS request_count
FROM ai_usage_logs
GROUP BY model_name, request_status
ORDER BY model_name, request_status;

SELECT
    customer_id,
    request_time,
    model_name,
    input_tokens,
    output_tokens,
    COUNT(*) AS duplicate_count
FROM ai_usage_logs
GROUP BY
    customer_id,
    request_time,
    model_name,
    input_tokens,
    output_tokens
HAVING COUNT(*) > 1
LIMIT 10;

SELECT COUNT(*) AS total_requests
FROM ai_usage_logs;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT_WS('|',
        customer_id,
        request_time,
        model_name,
        input_tokens,
        output_tokens
    )) AS distinct_request_combinations
FROM ai_usage_logs;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT_WS('|',
        customer_id,
        request_time,
        model_name,
        input_tokens,
        output_tokens
    )) AS distinct_request_combinations
FROM ai_usage_logs;
	
SELECT
    COUNT(*) AS total_requests,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT CONCAT(
        customer_id, '|',
        request_time, '|',
        model_name, '|',
        input_tokens, '|',
        output_tokens
    )) AS distinct_request_combinations
FROM ai_usage_logs;

SELECT
    model_name,
    COUNT(*) AS request_count
FROM ai_usage_logs
GROUP BY model_name
ORDER BY model_name;

SELECT
    COUNT(*) AS total_requests,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(CASE WHEN request_status = 'Failed' THEN 1 ELSE 0 END) AS failed_requests,
    SUM(CASE WHEN request_status = 'Success' THEN 1 ELSE 0 END) AS successful_requests,
    ROUND(AVG(latency_ms), 2) AS avg_latency_ms,
    ROUND(SUM(estimated_cost), 4) AS total_estimated_cost
FROM ai_usage_logs;

SELECT COUNT(*) AS invalid_records
FROM ai_usage_logs
WHERE customer_id IS NULL
   OR request_time IS NULL
   OR model_name IS NULL
   OR input_tokens < 0
   OR output_tokens < 0
   OR latency_ms < 0
   OR estimated_cost < 0;
   
   SELECT COUNT(*) AS orphan_requests
FROM ai_usage_logs u
LEFT JOIN customers c
    ON u.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

USE nexaai_analytics;

SELECT COUNT(*) AS existing_payment_records
FROM payments;


USE nexaai_analytics;

INSERT INTO payments (
    customer_id,
    payment_date,
    amount,
    payment_status
)
SELECT
    c.customer_id,

    DATE_ADD(
        c.signup_date,
        INTERVAL MOD(
            s.n * 7,
            DATEDIFF('2026-09-30', c.signup_date) + 1
        ) DAY
    ) AS payment_date,

    CASE
        WHEN MOD(s.n, 3) = 0 THEN 0.00
        WHEN MOD(s.n, 3) = 1 THEN 20.00
        ELSE 80.00
    END AS amount,

    CASE
        WHEN MOD(s.n, 20) = 0 THEN 'Refunded'
        WHEN MOD(s.n, 10) = 0 THEN 'Failed'
        ELSE 'Successful'
    END AS payment_status

FROM (
    SELECT
        d1.n * 1000 + d2.n * 100 + d3.n * 10 + d4.n + 1 AS n
    FROM (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL
        SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL
        SELECT 8 UNION ALL SELECT 9
    ) d1
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL
        SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL
        SELECT 8 UNION ALL SELECT 9
    ) d2
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL
        SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL
        SELECT 8 UNION ALL SELECT 9
    ) d3
    CROSS JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL
        SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL
        SELECT 8 UNION ALL SELECT 9
    ) d4
) s
JOIN customers c
    ON c.customer_id = MOD(s.n * 37, 500) + 1
WHERE s.n <= 2000;

SELECT COUNT(*) AS total_payments
FROM payments;

SELECT
    payment_status,
    COUNT(*) AS payment_count,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM payments
GROUP BY payment_status
ORDER BY payment_status;

SELECT COUNT(*) AS invalid_payments
FROM payments
WHERE customer_id IS NULL
   OR payment_date IS NULL
   OR amount < 0
   OR payment_status NOT IN ('Successful', 'Failed', 'Refunded');
   
SELECT COUNT(*) AS orphan_payments
FROM payments p
LEFT JOIN customers c
    ON p.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS existing_feedback_records
FROM customer_feedback;


USE nexaai_analytics;

INSERT INTO customer_feedback (
    customer_id,
    feedback_date,
    satisfaction_score,
    feedback_category
)
SELECT
    c.customer_id,

    DATE_ADD(
        c.signup_date,
        INTERVAL MOD(
            c.customer_id * 11,
            DATEDIFF('2026-09-30', c.signup_date) + 1
        ) DAY
    ) AS feedback_date,

    CASE
        WHEN MOD(c.customer_id, 10) < 2 THEN 1
        WHEN MOD(c.customer_id, 10) < 4 THEN 2
        WHEN MOD(c.customer_id, 10) < 6 THEN 3
        WHEN MOD(c.customer_id, 10) < 8 THEN 4
        ELSE 5
    END AS satisfaction_score,

    CASE MOD(c.customer_id, 5)
        WHEN 0 THEN 'Performance'
        WHEN 1 THEN 'Pricing'
        WHEN 2 THEN 'Ease of Use'
        WHEN 3 THEN 'Reliability'
        ELSE 'Feature Request'
    END AS feedback_category

FROM customers c;

SELECT COUNT(*) AS total_feedback
FROM customer_feedback;

SELECT
    satisfaction_score,
    COUNT(*) AS feedback_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_feedback),
        2
    ) AS percentage
FROM customer_feedback
GROUP BY satisfaction_score
ORDER BY satisfaction_score;

SELECT COUNT(*) AS invalid_feedback
FROM customer_feedback
WHERE customer_id IS NULL
   OR feedback_date IS NULL
   OR satisfaction_score NOT BETWEEN 1 AND 5
   OR feedback_category IS NULL;
   
SELECT COUNT(*) AS orphan_feedback
FROM customer_feedback f
LEFT JOIN customers c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS total_feedback
FROM customer_feedback;

SELECT COUNT(*) AS invalid_feedback
FROM customer_feedback
WHERE customer_id IS NULL
   OR feedback_date IS NULL
   OR satisfaction_score NOT BETWEEN 1 AND 5
   OR feedback_category IS NULL;
   
SELECT COUNT(*) AS orphan_feedback
FROM customer_feedback f
LEFT JOIN customers c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM customers
UNION ALL
SELECT 'subscriptions', COUNT(*)
FROM subscriptions
UNION ALL
SELECT 'ai_usage_logs', COUNT(*)
FROM ai_usage_logs
UNION ALL
SELECT 'payments', COUNT(*)
FROM payments
UNION ALL
SELECT 'customer_feedback', COUNT(*)
FROM customer_feedback;


USE nexaai_analytics;

SELECT
    s.plan_name,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT s.customer_id) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS customer_percentage
FROM subscriptions s
GROUP BY s.plan_name
ORDER BY total_customers DESC;


SELECT
    status AS subscription_status,
    COUNT(*) AS total_subscriptions,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM subscriptions),
        2
    ) AS percentage
FROM subscriptions
GROUP BY status
ORDER BY total_subscriptions DESC;


SELECT
    plan_name,
    COUNT(*) AS active_subscriptions,
    ROUND(SUM(monthly_price), 2) AS monthly_revenue_potential,
    ROUND(AVG(monthly_price), 2) AS average_price_per_subscription
FROM subscriptions
WHERE status = 'Active'
GROUP BY plan_name
ORDER BY monthly_revenue_potential DESC;


SELECT
    DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
    COUNT(*) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;


SELECT
    model_name,
    COUNT(*) AS total_requests,
    ROUND(AVG(latency_ms), 2) AS avg_latency_ms,
    MIN(latency_ms) AS min_latency_ms,
    MAX(latency_ms) AS max_latency_ms
FROM ai_usage_logs
GROUP BY model_name
ORDER BY avg_latency_ms DESC;


SELECT
    model_name,
    COUNT(*) AS total_requests,
    SUM(
        CASE WHEN request_status = 'Failed'
             THEN 1 ELSE 0 END
    ) AS failed_requests,
    ROUND(
        SUM(CASE WHEN request_status = 'Failed'
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS failure_rate_pct
FROM ai_usage_logs
GROUP BY model_name
ORDER BY failure_rate_pct DESC;


SELECT
    model_name,
    COUNT(*) AS total_requests,
    SUM(input_tokens) AS total_input_tokens,
    SUM(output_tokens) AS total_output_tokens,
    ROUND(SUM(estimated_cost), 4) AS total_inference_cost,
    ROUND(AVG(estimated_cost), 6) AS avg_cost_per_request
FROM ai_usage_logs
GROUP BY model_name
ORDER BY total_inference_cost DESC;


SELECT
    feedback_category,
    COUNT(*) AS feedback_count,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction,
    SUM(
        CASE WHEN satisfaction_score <= 2
             THEN 1 ELSE 0 END
    ) AS low_satisfaction_count
FROM customer_feedback
GROUP BY feedback_category
ORDER BY avg_satisfaction ASC;


SELECT
    COUNT(*) AS total_feedback,
    ROUND(AVG(satisfaction_score), 2) AS overall_avg_satisfaction,
    SUM(
        CASE WHEN satisfaction_score <= 2
             THEN 1 ELSE 0 END
    ) AS low_score_count,
    ROUND(
        SUM(CASE WHEN satisfaction_score <= 2
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS low_score_percentage
FROM customer_feedback;


SELECT
    plan_name,
    COUNT(*) AS total_subscriptions,
    SUM(
        CASE
            WHEN status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_subscriptions,
    ROUND(
        SUM(
            CASE
                WHEN status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate_pct
FROM subscriptions
GROUP BY plan_name
ORDER BY cancellation_rate_pct DESC;


SELECT
    payment_status,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM payments),
        2
    ) AS transaction_percentage
FROM payments
GROUP BY payment_status
ORDER BY total_transactions DESC;


SELECT
    DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN payment_status = 'Successful' THEN 1
            ELSE 0
        END
    ) AS successful_transactions,
    ROUND(
        SUM(
            CASE
                WHEN payment_status = 'Successful' THEN amount
                ELSE 0
            END
        ), 2
    ) AS successful_payment_amount
FROM payments
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY payment_month;


SELECT
    customer_id,
    COUNT(*) AS successful_transactions,
    ROUND(SUM(amount), 2) AS successful_payment_amount
FROM payments
WHERE payment_status = 'Successful'
GROUP BY customer_id
ORDER BY successful_payment_amount DESC
LIMIT 10;


SELECT
    s.plan_name,
    COUNT(p.payment_id) AS total_successful_transactions,
    ROUND(SUM(p.amount), 2) AS successful_payment_amount
FROM subscriptions AS s
JOIN payments AS p
    ON s.customer_id = p.customer_id
WHERE p.payment_status = 'Successful'
GROUP BY s.plan_name
ORDER BY successful_payment_amount DESC;


SELECT
    COUNT(*) AS total_ai_requests,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(
        COUNT(*) * 1.0 /
        COUNT(DISTINCT customer_id),
        2
    ) AS avg_requests_per_customer,
    ROUND(AVG(input_tokens), 2) AS avg_input_tokens_per_request,
    ROUND(AVG(output_tokens), 2) AS avg_output_tokens_per_request
FROM ai_usage_logs;


SELECT
    s.plan_name,
    COUNT(a.request_id) AS total_ai_requests,
    COUNT(DISTINCT a.customer_id) AS unique_customers,
    ROUND(
        COUNT(a.request_id) * 1.0 /
        COUNT(DISTINCT a.customer_id),
        2
    ) AS avg_requests_per_customer,
    ROUND(AVG(a.latency_ms), 2) AS avg_latency_ms
FROM subscriptions AS s
JOIN ai_usage_logs AS a
    ON s.customer_id = a.customer_id
GROUP BY s.plan_name
ORDER BY total_ai_requests DESC;


SELECT
    s.plan_name,
    COUNT(a.request_id) AS total_ai_requests,
    ROUND(SUM(a.estimated_cost), 4) AS total_estimated_ai_cost,
    ROUND(AVG(a.estimated_cost), 6) AS avg_cost_per_request,
    ROUND(
        SUM(a.estimated_cost) /
        COUNT(DISTINCT a.customer_id),
        4
    ) AS avg_ai_cost_per_customer
FROM subscriptions AS s
JOIN ai_usage_logs AS a
    ON s.customer_id = a.customer_id
GROUP BY s.plan_name
ORDER BY total_estimated_ai_cost DESC;


SELECT
    s.plan_name,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.monthly_price), 2) AS potential_monthly_revenue,
    ROUND(SUM(a.estimated_cost), 4) AS total_estimated_ai_cost,
    ROUND(
        SUM(s.monthly_price) - SUM(a.estimated_cost),
        4
    ) AS revenue_minus_ai_cost
FROM subscriptions AS s
JOIN ai_usage_logs AS a
    ON s.customer_id = a.customer_id
WHERE s.status = 'Active'
GROUP BY s.plan_name
ORDER BY revenue_minus_ai_cost DESC;


WITH active_revenue AS (
    SELECT
        plan_name,
        COUNT(*) AS active_customers,
        SUM(monthly_price) AS potential_monthly_revenue
    FROM subscriptions
    WHERE status = 'Active'
    GROUP BY plan_name
),
active_ai_cost AS (
    SELECT
        s.plan_name,
        SUM(a.estimated_cost) AS accumulated_ai_cost
    FROM subscriptions AS s
    JOIN ai_usage_logs AS a
        ON s.customer_id = a.customer_id
    WHERE s.status = 'Active'
    GROUP BY s.plan_name
)
SELECT
    r.plan_name,
    r.active_customers,
    ROUND(r.potential_monthly_revenue, 2)
        AS potential_monthly_revenue,
    ROUND(c.accumulated_ai_cost, 4)
        AS accumulated_ai_cost,
    ROUND(
        r.potential_monthly_revenue - c.accumulated_ai_cost,
        4
    ) AS revenue_minus_ai_cost
FROM active_revenue AS r
JOIN active_ai_cost AS c
    ON r.plan_name = c.plan_name
ORDER BY revenue_minus_ai_cost DESC;

SELECT
    DATE_FORMAT(request_time, '%Y-%m') AS request_month,
    COUNT(*) AS total_requests,
    SUM(
        CASE
            WHEN request_status = 'Failed' THEN 1
            ELSE 0
        END
    ) AS failed_requests,
    ROUND(
        SUM(
            CASE
                WHEN request_status = 'Failed' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_rate_pct
FROM ai_usage_logs
GROUP BY DATE_FORMAT(request_time, '%Y-%m')
ORDER BY request_month;


SELECT
    feedback_category,
    COUNT(*) AS total_feedback,
    ROUND(AVG(satisfaction_score), 2)
        AS avg_satisfaction,
    SUM(
        CASE
            WHEN satisfaction_score <= 2 THEN 1
            ELSE 0
        END
    ) AS low_score_count,
    ROUND(
        SUM(
            CASE
                WHEN satisfaction_score <= 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS low_score_percentage
FROM customer_feedback
GROUP BY feedback_category
ORDER BY avg_satisfaction ASC;


SELECT
    model_name,
    COUNT(*) AS total_requests,
    ROUND(AVG(latency_ms), 2) AS avg_latency_ms,
    SUM(
        CASE
            WHEN request_status = 'Failed' THEN 1
            ELSE 0
        END
    ) AS failed_requests,
    ROUND(
        SUM(
            CASE
                WHEN request_status = 'Failed' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_rate_pct
FROM ai_usage_logs
GROUP BY model_name
ORDER BY avg_latency_ms ASC, failure_rate_pct ASC;


SELECT
    c.industry,
    COUNT(a.request_id) AS total_ai_requests,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(
        COUNT(a.request_id) * 1.0 /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS avg_requests_per_customer,
    ROUND(SUM(a.estimated_cost), 4)
        AS total_estimated_ai_cost
FROM customers AS c
JOIN ai_usage_logs AS a
    ON c.customer_id = a.customer_id
GROUP BY c.industry
ORDER BY total_ai_requests DESC;


SELECT
    acquisition_channel,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS customer_percentage,
    COUNT(
        CASE
            WHEN s.status = 'Active' THEN 1
        END
    ) AS active_customers,
    ROUND(
        COUNT(
            CASE
                WHEN s.status = 'Active' THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS active_customer_percentage
FROM customers AS c
JOIN subscriptions AS s
    ON c.customer_id = s.customer_id
GROUP BY acquisition_channel
ORDER BY total_customers DESC;


SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(
        DISTINCT CASE
            WHEN s.status = 'Active' THEN c.customer_id
        END
    ) AS active_customers,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN s.status = 'Active' THEN c.customer_id
            END
        ) * 100.0 /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS active_subscription_rate_pct,
    COUNT(
        DISTINCT CASE
            WHEN s.status = 'Cancelled' THEN c.customer_id
        END
    ) AS cancelled_customers
FROM customers AS c
LEFT JOIN subscriptions AS s
    ON c.customer_id = s.customer_id
GROUP BY c.acquisition_channel
ORDER BY active_subscription_rate_pct DESC;


SELECT
    c.acquisition_channel,
    s.status,
    COUNT(*) AS customer_count
FROM customers AS c
JOIN subscriptions AS s
    ON c.customer_id = s.customer_id
GROUP BY
    c.acquisition_channel,
    s.status
ORDER BY
    c.acquisition_channel,
    s.status;


SELECT
    s.plan_name,
    COUNT(f.feedback_id) AS total_feedback,
    ROUND(AVG(f.satisfaction_score), 2)
        AS avg_satisfaction,
    SUM(
        CASE
            WHEN f.satisfaction_score <= 2 THEN 1
            ELSE 0
        END
    ) AS low_score_count,
    ROUND(
        SUM(
            CASE
                WHEN f.satisfaction_score <= 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(f.feedback_id),
        2
    ) AS low_score_percentage
FROM subscriptions AS s
JOIN customer_feedback AS f
    ON s.customer_id = f.customer_id
GROUP BY s.plan_name
ORDER BY avg_satisfaction DESC;


SELECT
    s.plan_name,
    COUNT(*) AS total_subscriptions,
    SUM(
        CASE
            WHEN s.status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_subscriptions,
    ROUND(
        SUM(
            CASE
                WHEN s.status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate_pct,
    ROUND(AVG(f.satisfaction_score), 2)
        AS avg_satisfaction
FROM subscriptions AS s
JOIN customer_feedback AS f
    ON s.customer_id = f.customer_id
GROUP BY s.plan_name
ORDER BY cancellation_rate_pct DESC, avg_satisfaction ASC;


SELECT
    DATE_FORMAT(c.signup_date, '%Y-%m') AS signup_month,
    COUNT(*) AS total_customers,
    SUM(
        CASE WHEN s.status = 'Active' THEN 1 ELSE 0 END
    ) AS active_customers,
    SUM(
        CASE WHEN s.status = 'Cancelled' THEN 1 ELSE 0 END
    ) AS cancelled_customers,
    SUM(
        CASE WHEN s.status = 'Expired' THEN 1 ELSE 0 END
    ) AS expired_customers,
    ROUND(
        SUM(CASE WHEN s.status = 'Active' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS active_percentage
FROM customers AS c
JOIN subscriptions AS s
    ON c.customer_id = s.customer_id
GROUP BY DATE_FORMAT(c.signup_date, '%Y-%m')
ORDER BY signup_month;



SELECT
    COUNT(*) AS eligible_customers_90_days,
    SUM(
        CASE
            WHEN s.status = 'Active' THEN 1
            ELSE 0
        END
    ) AS currently_active_customers,
    ROUND(
        SUM(
            CASE
                WHEN s.status = 'Active' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS current_active_rate_pct
FROM subscriptions AS s
WHERE s.start_date <= DATE_SUB('2026-09-30', INTERVAL 90 DAY);


SELECT
    COUNT(*) AS eligible_customers_90_days,
    SUM(
        CASE
            WHEN s.end_date IS NULL
                 OR s.end_date >= DATE_ADD(
                     s.start_date, INTERVAL 90 DAY
                 )
            THEN 1
            ELSE 0
        END
    ) AS retained_at_90_days,
    ROUND(
        SUM(
            CASE
                WHEN s.end_date IS NULL
                     OR s.end_date >= DATE_ADD(
                         s.start_date, INTERVAL 90 DAY
                     )
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS retention_rate_90_days_pct
FROM subscriptions AS s
WHERE DATE_ADD(
    s.start_date, INTERVAL 90 DAY
) <= '2026-09-30';

USE nexaai_analytics;
SHOW TABLES;
SHOW VARIABLES
WHERE Variable_name IN (
    'port',
    'hostname',
    'bind_address',
    'mysqlx_port'
);
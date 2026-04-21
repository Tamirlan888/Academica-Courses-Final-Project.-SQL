-- Запрос 1: Клиенты с непрерывной историей за год

SELECT
    c.*,
    t.avg_check,
    t.avg_sum_per_month,
    t.total_operations
FROM customers c
JOIN (
    SELECT
        ID_client,
        COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS count_months,
        AVG(Sum_payment)                               AS avg_check,
        SUM(Sum_payment) / 12                          AS avg_sum_per_month,
        COUNT(Id_check)                                AS total_operations
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
    HAVING count_months = 12
) t ON c.Id_client = t.ID_client;

-- Запрос 2: Аналитика по месяцам

SELECT
    month,
    avg_check,
    total_operations,
    unique_clients,
    total_operations / (
        SELECT COUNT(*)
        FROM transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS share_operations,
    sum_month / (
        SELECT SUM(Sum_payment)
        FROM transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS share_sum
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        AVG(Sum_payment)               AS avg_check,
        SUM(Sum_payment)               AS sum_month,
        COUNT(Id_check)                AS total_operations,
        COUNT(DISTINCT ID_client)      AS unique_clients
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) t;

-- Запрос 3: Гендерное соотношение M / F / NA по месяцам

SELECT
    month,
    gender,
    unique_clients,
    sum_payment,
    unique_clients / SUM(unique_clients) OVER (PARTITION BY month) AS share_clients,
    sum_payment    / SUM(sum_payment)    OVER (PARTITION BY month) AS share_sum
FROM (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        COALESCE(c.Gender, 'NA')         AS gender,
        COUNT(DISTINCT t.ID_client)      AS unique_clients,
        SUM(t.Sum_payment)               AS sum_payment
    FROM transactions t
    JOIN customers c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), COALESCE(c.Gender, 'NA')
) t;

-- Запрос 4: Возрастные группы клиентов (шаг 10 лет)

SELECT
    CASE
        WHEN c.age IS NULL THEN 'NA'
        WHEN c.age < 10    THEN '0-9'
        WHEN c.age < 20    THEN '10-19'
        WHEN c.age < 30    THEN '20-29'
        WHEN c.age < 40    THEN '30-39'
        WHEN c.age < 50    THEN '40-49'
        WHEN c.age < 60    THEN '50-59'
        WHEN c.age < 70    THEN '60-69'
        ELSE                    '70+'
    END                  AS age_group,
    YEAR(t.date_new)     AS year,
    QUARTER(t.date_new)  AS quarter,
    COUNT(t.Id_check)    AS total_operations,
    SUM(t.Sum_payment)   AS total_sum,
    AVG(t.Sum_payment)   AS avg_check,
    COUNT(t.Id_check)  / SUM(COUNT(t.Id_check))  OVER (PARTITION BY YEAR(t.date_new), QUARTER(t.date_new)) AS share_operations,
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY YEAR(t.date_new), QUARTER(t.date_new)) AS share_sum
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group, YEAR(t.date_new), QUARTER(t.date_new)
ORDER BY year, quarter, age_group;
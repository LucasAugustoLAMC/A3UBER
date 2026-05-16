-- ============================================================
-- PROJETO: Big Data Analytics — Transporte por Aplicativo
-- SCRIPT SQL FINAL — Validado contra o banco real
-- Todas as colunas em snake_case (minúsculo, sem espaços)
--
-- IMPORTANTE: Execute este script no banco transporte_v2.db
-- que foi gerado pelo script Python abaixo (rodar antes):
--   python3 gerar_banco.py
-- ============================================================

-- ============================================================
-- LIMPEZA: apaga views antigas se existirem
-- ============================================================
DROP VIEW IF EXISTS vw_kpi_status;
DROP VIEW IF EXISTS vw_receita_por_veiculo;
DROP VIEW IF EXISTS vw_pico_sem_motorista;
DROP VIEW IF EXISTS vw_receita_por_local;
DROP VIEW IF EXISTS vw_motivos_cancel_por_veiculo;
DROP VIEW IF EXISTS vw_tat_vs_cancelamento;
DROP VIEW IF EXISTS vw_resumo_mensal;

-- ============================================================
-- VIEW 1: KPI Geral — Taxa de Sucesso x Cancelamento
-- ============================================================
CREATE VIEW vw_kpi_status AS
SELECT
    booking_status,
    COUNT(*)                                              AS total_corridas,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)    AS percentual,
    ROUND(SUM(booking_value), 2)                          AS receita_total,
    ROUND(AVG(booking_value), 2)                          AS ticket_medio,
    ROUND(AVG(avg_vtat), 2)                               AS vtat_medio,
    ROUND(AVG(avg_ctat), 2)                               AS ctat_medio
FROM fato_corridas
GROUP BY booking_status
ORDER BY total_corridas DESC;

-- ============================================================
-- VIEW 2: Faturamento por Tipo de Veículo
-- ============================================================
CREATE VIEW vw_receita_por_veiculo AS
SELECT
    vehicle_type,
    COUNT(*)                                              AS total_corridas,
    SUM(is_completed)                                     AS corridas_concluidas,
    ROUND(SUM(booking_value), 2)                          AS receita_total,
    ROUND(AVG(booking_value), 2)                          AS ticket_medio,
    ROUND(AVG(ride_distance), 2)                          AS distancia_media_km,
    ROUND(SUM(is_completed) * 100.0 / COUNT(*), 2)        AS taxa_conclusao_pct,
    ROUND(AVG(avg_vtat), 2)                               AS vtat_medio
FROM fato_corridas
GROUP BY vehicle_type
ORDER BY receita_total DESC;

-- ============================================================
-- VIEW 3: Horários de Pico — "No Driver Found"
-- ============================================================
CREATE VIEW vw_pico_sem_motorista AS
SELECT
    order_hour,
    COUNT(*)                                              AS total_corridas,
    SUM(no_driver_found)                                  AS sem_motorista,
    ROUND(SUM(no_driver_found) * 100.0 / COUNT(*), 2)    AS taxa_sem_motorista_pct,
    SUM(cancelled_by_driver)                              AS cancelados_motorista,
    ROUND(SUM(cancelled_by_driver) * 100.0 / COUNT(*), 2) AS taxa_cancel_motorista_pct,
    ROUND(AVG(avg_vtat), 2)                               AS vtat_medio,
    CASE
        WHEN order_hour BETWEEN 0  AND 5  THEN 'Madrugada'
        WHEN order_hour BETWEEN 6  AND 11 THEN 'Manha'
        WHEN order_hour BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END                                                   AS periodo_dia
FROM fato_corridas
GROUP BY order_hour
ORDER BY taxa_sem_motorista_pct DESC;

-- ============================================================
-- VIEW 4: Receita por Local de Origem (Pickup Location)
-- ============================================================
CREATE VIEW vw_receita_por_local AS
SELECT
    pickup_location,
    COUNT(*)                                              AS total_corridas,
    SUM(is_completed)                                     AS corridas_concluidas,
    SUM(no_driver_found)                                  AS sem_motorista,
    ROUND(SUM(booking_value), 2)                          AS receita_total,
    ROUND(AVG(booking_value), 2)                          AS ticket_medio,
    ROUND(SUM(no_driver_found) * 100.0 / COUNT(*), 2)    AS taxa_sem_motorista_pct,
    ROUND(SUM(is_completed) * 100.0 / COUNT(*), 2)        AS taxa_conclusao_pct
FROM fato_corridas
GROUP BY pickup_location
ORDER BY receita_total DESC;

-- ============================================================
-- VIEW 5: Ranking de Motivos de Cancelamento por Veículo
-- ============================================================
CREATE VIEW vw_motivos_cancel_por_veiculo AS
SELECT
    vehicle_type,
    cancel_reason_unified,
    COUNT(*)                                              AS ocorrencias,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (PARTITION BY vehicle_type), 2
    )                                                     AS pct_dentro_veiculo
FROM fato_corridas
WHERE booking_status IN (
    'Cancelled by Driver',
    'Cancelled by Customer',
    'No Driver Found'
)
GROUP BY vehicle_type, cancel_reason_unified
ORDER BY vehicle_type, ocorrencias DESC;

-- ============================================================
-- VIEW 6: TAT x Taxa de Cancelamento
-- ============================================================
CREATE VIEW vw_tat_vs_cancelamento AS
SELECT
    vtat_category,
    COUNT(*)                                                      AS total,
    SUM(is_completed)                                             AS concluidas,
    COUNT(*) - SUM(is_completed)                                  AS nao_concluidas,
    ROUND((COUNT(*) - SUM(is_completed)) * 100.0 / COUNT(*), 2)  AS taxa_nao_conclusao_pct,
    ROUND(AVG(avg_vtat), 2)                                       AS vtat_medio,
    ROUND(AVG(avg_ctat), 2)                                       AS ctat_medio,
    ROUND(AVG(booking_value), 2)                                  AS ticket_medio
FROM fato_corridas
WHERE vtat_category IS NOT NULL
  AND vtat_category != 'nan'
GROUP BY vtat_category
ORDER BY vtat_medio;

-- ============================================================
-- VIEW 7: Resumo Mensal Executivo
-- ============================================================
CREATE VIEW vw_resumo_mensal AS
SELECT
    order_month                                           AS mes,
    COUNT(*)                                              AS total_corridas,
    SUM(is_completed)                                     AS corridas_concluidas,
    ROUND(SUM(is_completed) * 100.0 / COUNT(*), 2)        AS taxa_conclusao_pct,
    ROUND(SUM(booking_value), 2)                          AS receita_total,
    ROUND(AVG(booking_value), 2)                          AS ticket_medio,
    SUM(no_driver_found)                                  AS sem_motorista,
    SUM(cancelled_by_driver)                              AS cancel_motorista,
    SUM(cancelled_by_customer)                            AS cancel_cliente
FROM fato_corridas
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- QUERY A: Impacto Financeiro dos Cancelamentos
-- ============================================================
SELECT
    'Receita Realizada'                 AS categoria,
    ROUND(SUM(CASE WHEN is_completed = 1 THEN booking_value ELSE 0 END), 0) AS valor
FROM fato_corridas
UNION ALL
SELECT
    'Receita Potencial Perdida (est.)' AS categoria,
    ROUND(
        (SELECT AVG(booking_value) FROM fato_corridas WHERE is_completed = 1)
        * SUM(CASE WHEN is_completed = 0 AND booking_value = 0 THEN 1 ELSE 0 END),
    0) AS valor
FROM fato_corridas;

-- ============================================================
-- QUERY B: Locais críticos — candidatos a bônus de motoristas
-- ============================================================
SELECT
    pickup_location,
    total_corridas,
    sem_motorista,
    taxa_sem_motorista_pct,
    receita_total,
    CASE
        WHEN taxa_sem_motorista_pct >= 10 AND total_corridas >= 400
            THEN 'CRITICO — Bonus Urgente'
        WHEN taxa_sem_motorista_pct >= 7  AND total_corridas >= 300
            THEN 'ALTO — Incentivo Recomendado'
        WHEN taxa_sem_motorista_pct >= 5
            THEN 'MODERADO — Monitorar'
        ELSE 'NORMAL'
    END AS prioridade_incentivo
FROM vw_receita_por_local
ORDER BY taxa_sem_motorista_pct DESC, total_corridas DESC
LIMIT 20;

-- ============================================================
-- QUERY C: Performance por período do dia
-- ============================================================
SELECT
    periodo_dia,
    SUM(total_corridas)                   AS total,
    SUM(sem_motorista)                    AS sem_motorista,
    ROUND(AVG(taxa_sem_motorista_pct), 2) AS taxa_media_sem_motorista_pct,
    ROUND(AVG(vtat_medio), 2)             AS vtat_medio_periodo
FROM vw_pico_sem_motorista
GROUP BY periodo_dia
ORDER BY taxa_media_sem_motorista_pct DESC;

-- ============================================================
-- TESTE RÁPIDO — rode estas 3 linhas para confirmar que tudo
-- está funcionando corretamente:
-- ============================================================
-- SELECT * FROM vw_kpi_status;
-- SELECT * FROM vw_receita_por_veiculo;
-- SELECT * FROM vw_receita_por_local LIMIT 10;
ALTER TABLE customer_interactions
  ADD COLUMN question_embedding vector(768),
  ADD COLUMN cluster_id INT;

CREATE INDEX idx_interactions_cluster ON customer_interactions(cluster_id);

CREATE VIEW recurring_topics AS
SELECT cluster_id,
       COUNT(*)                                   AS occurrences,
       COUNT(DISTINCT customer_id)                AS customers,
       MIN(created_at)                            AS first_seen,
       MAX(created_at)                            AS last_seen,
       (array_agg(summary ORDER BY created_at))[1] AS example_summary
FROM customer_interactions
WHERE cluster_id IS NOT NULL AND created_at > NOW() - INTERVAL '30 days'
GROUP BY cluster_id
HAVING COUNT(*) >= 3;
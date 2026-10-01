CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TABLE customers (
  customer_id      SERIAL PRIMARY KEY,
  company_name     TEXT NOT NULL,
  industry         TEXT,
  customer_segment TEXT NOT NULL CHECK (customer_segment IN ('SMB','Mid-Market','Enterprise')),
  account_owner    TEXT NOT NULL,
  contact_name     TEXT,
  contact_email    TEXT NOT NULL UNIQUE,
  plan             TEXT NOT NULL CHECK (plan IN ('Starter','Professional','Enterprise')),
  renewal_date     DATE,
  health_status    TEXT NOT NULL DEFAULT 'healthy'
                   CHECK (health_status IN ('healthy','watch','at_risk','high_risk')),
  adoption_score   INT NOT NULL DEFAULT 50 CHECK (adoption_score BETWEEN 0 AND 100),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customer_interactions (
  interaction_id  SERIAL PRIMARY KEY,
  customer_id     INT REFERENCES customers(customer_id) ON DELETE CASCADE,
  message_id      TEXT NOT NULL UNIQUE,  -- duplicate-message protection
  channel         TEXT NOT NULL DEFAULT 'email',
  sender_email    TEXT NOT NULL,
  subject         TEXT,
  message_body    TEXT NOT NULL,
  request_type    TEXT CHECK (request_type IN ('Technical Support','Adoption Question',
                    'How-To / Product Guidance','Billing / Administrative','Feature Request',
                    'Account / Access','Strategic Adoption Blocker','Commercial Opportunity',
                    'General Question')),
  sentiment       TEXT CHECK (sentiment IN ('positive','neutral','negative','very_negative')),
  summary         TEXT,
  topic_key       TEXT,                  -- used for recurring-question detection
  ai_confidence   NUMERIC(3,2) CHECK (ai_confidence BETWEEN 0 AND 1),
  status          TEXT NOT NULL DEFAULT 'new'
                  CHECK (status IN ('new','open','awaiting_review','resolved','escalated')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ
);

CREATE TABLE customer_health (
  health_id       SERIAL PRIMARY KEY,
  customer_id     INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  interaction_id  INT REFERENCES customer_interactions(interaction_id) ON DELETE SET NULL,
  health_status   TEXT NOT NULL CHECK (health_status IN ('healthy','watch','at_risk','high_risk')),
  adoption_score  INT CHECK (adoption_score BETWEEN 0 AND 100),
  risk_reason     TEXT,
  signal_source   TEXT NOT NULL CHECK (signal_source IN ('ai','rule','manual')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE followup_tasks (
  task_id         SERIAL PRIMARY KEY,
  customer_id     INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  interaction_id  INT REFERENCES customer_interactions(interaction_id) ON DELETE SET NULL,
  task_type       TEXT NOT NULL CHECK (task_type IN ('adoption_check_in','commercial_followup',
                    'risk_review','billing_handoff','other')),
  description     TEXT NOT NULL,
  assigned_to     TEXT,
  status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_progress','done','cancelled')),
  due_date        DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE TABLE escalations (
  escalation_id   SERIAL PRIMARY KEY,
  customer_id     INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  interaction_id  INT REFERENCES customer_interactions(interaction_id) ON DELETE SET NULL,
  reason          TEXT NOT NULL,
  severity        TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  escalated_to    TEXT,
  status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','acknowledged','resolved')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ
);

CREATE TABLE knowledge_documents (
  doc_id       SERIAL PRIMARY KEY,
  title        TEXT NOT NULL,
  category     TEXT NOT NULL CHECK (category IN ('Product Guide','Playbook','FAQ')),
  content      TEXT NOT NULL,
  tags         TEXT[] DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE automation_logs (
  log_id              SERIAL PRIMARY KEY,
  customer_id         INT REFERENCES customers(customer_id) ON DELETE SET NULL,
  interaction_id      INT REFERENCES customer_interactions(interaction_id) ON DELETE SET NULL,
  event               TEXT NOT NULL,
  classification      TEXT,
  retrieved_doc_ids   INT[] DEFAULT '{}',
  decision            TEXT,
  rule_triggered      TEXT,
  ai_confidence       NUMERIC(3,2),
  human_involved      BOOLEAN NOT NULL DEFAULT FALSE,
  action_taken        TEXT,
  success             BOOLEAN NOT NULL,
  error_message       TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes (foreign keys aren't indexed automatically in Postgres)
CREATE INDEX idx_interactions_customer ON customer_interactions(customer_id, created_at DESC);
CREATE INDEX idx_interactions_topic    ON customer_interactions(topic_key);
CREATE INDEX idx_interactions_status   ON customer_interactions(status);
CREATE INDEX idx_health_customer       ON customer_health(customer_id, created_at DESC);
CREATE INDEX idx_tasks_customer_status ON followup_tasks(customer_id, status);
CREATE INDEX idx_escalations_customer  ON escalations(customer_id, status);
CREATE INDEX idx_logs_interaction      ON automation_logs(interaction_id);
CREATE INDEX idx_logs_created          ON automation_logs(created_at DESC);
CREATE INDEX idx_customers_health      ON customers(health_status);

CREATE TRIGGER trg_customers_updated BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_docs_updated BEFORE UPDATE ON knowledge_documents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
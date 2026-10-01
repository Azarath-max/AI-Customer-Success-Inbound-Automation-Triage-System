INSERT INTO customers
(company_name, industry, customer_segment, account_owner, contact_name, contact_email, plan, renewal_date, health_status, adoption_score) VALUES
('Northwind Academy',        'K-12 Education',      'Enterprise', 'Maria Santos',  'Elena Cruz',    'elena@northwind-academy.example',   'Enterprise',   '2027-03-15', 'healthy',  85),
('Brightpath Learning',      'Tutoring',            'SMB',        'Daniel Reyes',  'Paolo Tan',     'paolo@brightpath.example',          'Starter',      '2027-01-20', 'watch',    28),
('Summit Training Co',       'Corporate Training',  'Mid-Market', 'Maria Santos',  'Rachel Lim',    'rachel@summit-training.example',    'Professional', '2026-12-10', 'at_risk',  40),
('Harbor Health Institute',  'Healthcare Training', 'Mid-Market', 'Daniel Reyes',  'Dr. Ana Garcia','ana@harborhealth.example',          'Professional', '2027-05-30', 'healthy',  78),
('Lakeside Technical College','Higher Education',   'Enterprise', 'Carlo Mendoza', 'James Ong',     'james@lakeside-tech.example',       'Enterprise',   '2027-08-01', 'healthy',  72),
('Pioneer Skills Hub',       'Vocational Training', 'SMB',        'Carlo Mendoza', 'Liza Ramos',    'liza@pioneer-skills.example',       'Starter',      '2026-11-25', 'watch',    55);

-- Summit Training: repeated unresolved problems (for the escalation scenario)
INSERT INTO customer_interactions
(customer_id, message_id, sender_email, subject, message_body, request_type, sentiment, summary, topic_key, ai_confidence, status, created_at) VALUES
(3,'seed-001','rachel@summit-training.example','Reports not exporting','Our monthly completion report fails to export to CSV.','Technical Support','negative','CSV export of completion report fails.','report_export',0.90,'open', NOW() - INTERVAL '21 days'),
(3,'seed-002','rachel@summit-training.example','Re: Reports not exporting','Still broken. No update since my last message.','Technical Support','negative','Follow-up: CSV export still failing, no response.','report_export',0.88,'open', NOW() - INTERVAL '12 days'),
(3,'seed-003','rachel@summit-training.example','Instructor import failing','Bulk instructor import also errors out now.','Technical Support','negative','Bulk instructor import failing.','instructor_import',0.85,'open', NOW() - INTERVAL '5 days');

-- Summit Training: declining health history
INSERT INTO customer_health (customer_id, health_status, adoption_score, risk_reason, signal_source, created_at) VALUES
(3,'healthy',62,'Baseline','manual', NOW() - INTERVAL '90 days'),
(3,'watch',51,'Usage dropped after export issues','rule', NOW() - INTERVAL '30 days'),
(3,'at_risk',40,'Repeated unresolved tickets','rule', NOW() - INTERVAL '5 days');
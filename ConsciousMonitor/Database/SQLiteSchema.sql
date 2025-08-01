-- SQLite Schema for ConsciousMonitor
-- Migrates from JSON-based storage to relational database
-- Compatible with existing AppActivationEvent and ContextSwitchMetrics models

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- Enable WAL mode for better performance
PRAGMA journal_mode = WAL;

-- App Categories table (reference data)
CREATE TABLE app_categories (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    is_default BOOLEAN DEFAULT 0,
    color_hex TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table for explicit session tracking
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    switch_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- App Activation Events (main table)
CREATE TABLE app_activation_events (
    id TEXT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    app_name TEXT,
    bundle_identifier TEXT,
    
    -- Chrome Integration
    chrome_tab_title TEXT,
    chrome_tab_url TEXT,
    site_domain TEXT,
    
    -- Categorization
    category_name TEXT NOT NULL DEFAULT 'Other',
    
    -- Session Management
    session_id TEXT,
    session_start_time DATETIME,
    session_end_time DATETIME,
    is_session_start BOOLEAN DEFAULT 0,
    is_session_end BOOLEAN DEFAULT 0,
    session_switch_count INTEGER DEFAULT 1,
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Context Switch Metrics table
CREATE TABLE context_switch_metrics (
    id TEXT PRIMARY KEY,
    from_app TEXT NOT NULL,
    to_app TEXT NOT NULL,
    from_bundle_id TEXT,
    to_bundle_id TEXT,
    timestamp DATETIME NOT NULL,
    time_spent REAL NOT NULL, -- TimeInterval in seconds
    switch_type TEXT NOT NULL, -- quick/normal/focused
    from_category TEXT NOT NULL,
    to_category TEXT NOT NULL,
    session_id TEXT,
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Analysis Entries (AI insights)
CREATE TABLE analysis_entries (
    id TEXT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    insights TEXT NOT NULL,
    data_points INTEGER NOT NULL,
    analysis_type TEXT NOT NULL,
    time_range_analyzed TEXT NOT NULL,
    
    -- OpenAI integration metadata
    token_count INTEGER,
    api_model TEXT,
    analysis_version TEXT DEFAULT '1.0',
    
    -- Context data as JSON for flexibility
    data_context TEXT, -- JSON blob for AnalysisDataContext
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes for common queries

-- Events table indexes
CREATE INDEX idx_events_timestamp ON app_activation_events(timestamp DESC);
CREATE INDEX idx_events_app_name ON app_activation_events(app_name);
CREATE INDEX idx_events_bundle ON app_activation_events(bundle_identifier);
CREATE INDEX idx_events_category ON app_activation_events(category_name);
CREATE INDEX idx_events_session ON app_activation_events(session_id);
CREATE INDEX idx_events_domain ON app_activation_events(site_domain) WHERE site_domain IS NOT NULL;

-- Date-based queries optimization
CREATE INDEX idx_events_date ON app_activation_events(date(timestamp));
CREATE INDEX idx_events_date_app ON app_activation_events(date(timestamp), app_name);
CREATE INDEX idx_events_date_category ON app_activation_events(date(timestamp), category_name);

-- Session boundary queries
CREATE INDEX idx_events_session_boundaries ON app_activation_events(session_id, is_session_start, is_session_end);

-- Context switches indexes
CREATE INDEX idx_switches_timestamp ON context_switch_metrics(timestamp DESC);
CREATE INDEX idx_switches_apps ON context_switch_metrics(from_app, to_app);
CREATE INDEX idx_switches_categories ON context_switch_metrics(from_category, to_category);
CREATE INDEX idx_switches_time_spent ON context_switch_metrics(time_spent DESC);
CREATE INDEX idx_switches_session ON context_switch_metrics(session_id);
CREATE INDEX idx_switches_type ON context_switch_metrics(switch_type);

-- Date-based context switch queries
CREATE INDEX idx_switches_date ON context_switch_metrics(date(timestamp));

-- Analysis entries indexes
CREATE INDEX idx_analysis_timestamp ON analysis_entries(timestamp DESC);
CREATE INDEX idx_analysis_type ON analysis_entries(analysis_type);
CREATE INDEX idx_analysis_date ON analysis_entries(date(timestamp));

-- Sessions table indexes
CREATE INDEX idx_sessions_start_time ON sessions(start_time DESC);
CREATE INDEX idx_sessions_active ON sessions(is_active) WHERE is_active = 1;

-- Insert default app categories
INSERT INTO app_categories (id, name, is_default, color_hex, description) VALUES
('productivity', 'Productivity', 1, '#4CAF50', 'Work and productivity applications'),
('communication', 'Communication', 1, '#2196F3', 'Email, messaging, and communication tools'),
('social_media', 'Social Media', 1, '#FF5722', 'Social networking and media platforms'),
('development', 'Development', 1, '#9C27B0', 'Programming and development tools'),
('entertainment', 'Entertainment', 1, '#FF9800', 'Games, videos, and entertainment'),
('design', 'Design', 1, '#E91E63', 'Graphics, design, and creative tools'),
('utilities', 'Utilities', 1, '#607D8B', 'System utilities and tools'),
('education', 'Education', 1, '#8BC34A', 'Learning and educational resources'),
('finance', 'Finance', 1, '#4CAF50', 'Banking, finance, and money management'),
('health_fitness', 'Health & Fitness', 1, '#F44336', 'Health, fitness, and wellness apps'),
('lifestyle', 'Lifestyle', 1, '#795548', 'Lifestyle and personal apps'),
('news', 'News', 1, '#3F51B5', 'News and information sources'),
('shopping', 'Shopping', 1, '#FF5722', 'E-commerce and shopping apps'),
('travel', 'Travel', 1, '#00BCD4', 'Travel and navigation apps'),
('knowledge_management', 'Knowledge Management', 1, '#9E9E9E', 'Note-taking and knowledge tools'),
('other', 'Other', 1, '#9E9E9E', 'Uncategorized applications');

-- Create views for common analytics queries

-- Daily app usage summary
CREATE VIEW daily_app_usage AS
SELECT 
    date(timestamp) as usage_date,
    app_name,
    bundle_identifier,
    category_name,
    COUNT(*) as activation_count,
    MAX(timestamp) as last_activation
FROM app_activation_events 
WHERE app_name IS NOT NULL
GROUP BY date(timestamp), app_name, bundle_identifier, category_name
ORDER BY usage_date DESC, activation_count DESC;

-- Daily context switch summary
CREATE VIEW daily_switch_summary AS
SELECT 
    date(timestamp) as switch_date,
    COUNT(*) as total_switches,
    AVG(time_spent) as avg_time_spent,
    SUM(CASE WHEN switch_type = 'quick' THEN 1 ELSE 0 END) as quick_switches,
    SUM(CASE WHEN switch_type = 'focused' THEN 1 ELSE 0 END) as focused_periods
FROM context_switch_metrics
GROUP BY date(timestamp)
ORDER BY switch_date DESC;

-- Category usage trends
CREATE VIEW category_usage_trends AS
SELECT 
    date(timestamp) as usage_date,
    category_name,
    COUNT(*) as activation_count,
    COUNT(DISTINCT app_name) as unique_apps,
    MIN(timestamp) as first_activation,
    MAX(timestamp) as last_activation
FROM app_activation_events
WHERE app_name IS NOT NULL
GROUP BY date(timestamp), category_name
ORDER BY usage_date DESC, activation_count DESC;

-- Performance monitoring view
CREATE VIEW performance_metrics AS
SELECT 
    'app_activation_events' as table_name,
    COUNT(*) as record_count,
    MIN(timestamp) as earliest_record,
    MAX(timestamp) as latest_record,
    MAX(created_at) as last_inserted
FROM app_activation_events
UNION ALL
SELECT 
    'context_switch_metrics' as table_name,
    COUNT(*) as record_count,
    MIN(timestamp) as earliest_record,
    MAX(timestamp) as latest_record,
    MAX(created_at) as last_inserted
FROM context_switch_metrics;
-- ContractAnalyzer Database Initialization Script
-- This script sets up the basic database structure for development

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schemas for different services
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS analysis;
CREATE SCHEMA IF NOT EXISTS citation;
CREATE SCHEMA IF NOT EXISTS ocr;

-- Basic health check table
CREATE TABLE IF NOT EXISTS public.health_check (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'healthy',
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial health check records
INSERT INTO public.health_check (service_name, status) VALUES 
    ('api-gateway', 'healthy'),
    ('auth', 'healthy'),
    ('analysis', 'healthy'),
    ('citation', 'healthy'),
    ('ocr-wrapper', 'healthy')
ON CONFLICT DO NOTHING;

-- Create a simple logging table for development
CREATE TABLE IF NOT EXISTS public.service_logs (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_health_check_service ON public.health_check(service_name);
CREATE INDEX IF NOT EXISTS idx_health_check_status ON public.health_check(status);
CREATE INDEX IF NOT EXISTS idx_service_logs_service ON public.service_logs(service_name);
CREATE INDEX IF NOT EXISTS idx_service_logs_level ON public.service_logs(level);
CREATE INDEX IF NOT EXISTS idx_service_logs_created ON public.service_logs(created_at);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analysis TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analysis TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA citation TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA citation TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ocr TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ocr TO postgres;

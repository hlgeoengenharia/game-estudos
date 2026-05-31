-- Habilitar UUID e extensões matemáticas se necessário
create extension if not exists "uuid-ossp";

-- 1. Tabela de Perfis de Usuários (Integrado com Supabase Auth)
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  updated_at timestamp with time zone,
  username text unique,
  full_name text,
  avatar_url text,
  total_score integer default 0
);

-- 2. Tabela de Concursos Cadastrados
create table if not exists contests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade,
  name text not null, -- ex: "Analista Judiciário"
  board text not null, -- ex: "IBFC", "FGV", "Cebraspe", "FCC"
  exam_style text not null, -- "multipla_escolha" ou "certo_errado"
  institution text, -- ex: "TJPE", "RFB", "INSS"
  notice_text text, -- Conteúdo completo do edital extraído
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Tabela de Matérias
create table if not exists subjects (
  id uuid default uuid_generate_v4() primary key,
  contest_id uuid references contests(id) on delete cascade,
  name text not null, -- ex: "Segurança da Informação"
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Tabela de Assuntos/Tópicos do Edital
create table if not exists topics (
  id uuid default uuid_generate_v4() primary key,
  subject_id uuid references subjects(id) on delete cascade,
  title text not null, -- ex: "Criptografia Simétrica e Assimétrica"
  theory_content text, -- Teoria padrão ou inserida pelo usuário
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Tabela de Estatísticas de Recorrência (Raio-X de Assuntos)
create table if not exists topic_recurrence_stats (
  id uuid default uuid_generate_v4() primary key,
  topic_id uuid references topics(id) on delete cascade,
  recurrence_percentage numeric(5,2) default 0.00, -- ex: 45.50 (% de chance de cair)
  notes text, -- ex: "FGV cobrou 12 vezes nos últimos 2 anos"
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Tabela de Materiais de Estudo (Cumulative context para o robô)
create table if not exists study_materials (
  id uuid default uuid_generate_v4() primary key,
  topic_id uuid references topics(id) on delete cascade,
  material_type text not null, -- "pdf_text", "web_link", "youtube_link"
  content_data text not null, -- Texto extraído do PDF, URL do site ou URL do YouTube
  display_name text not null, -- Nome para exibição
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Tabela de Configuração de Redação (Pre-configurável e dinâmica)
create table if not exists essay_configs (
  id uuid default uuid_generate_v4() primary key,
  contest_id uuid references contests(id) on delete cascade unique,
  guidelines text, -- Itens colados do edital
  essay_type text, -- "Dissertativa-Argumentativa", "Estudo de Caso", "Questão Discursiva"
  max_lines integer default 30,
  complementary_notes text,
  
  -- PARÂMETROS DE CORREÇÃO DINÂMICOS (Pré-configuráveis)
  macro_score_max numeric(5,2) default 100.00, -- Pontuação máxima total
  structure_score_max numeric(5,2) default 30.00, -- Pontuação estrutural máxima
  content_score_max numeric(5,2) default 70.00, -- Pontuação de conteúdo máxima
  
  -- Regras de dedução por erros microestruturais (JSON configurável pelo usuário)
  error_deduction_rates jsonb default '{
    "spelling_error_deduction": 0.20,
    "grammatical_error_deduction": 0.30,
    "syntax_error_deduction": 0.30,
    "vocabulary_error_deduction": 0.20
  }'::jsonb,
  
  -- Configuração da fórmula matemática (CEBRASPE, FGV, FCC ou Personalizada)
  formula_type text default 'cebraspe', -- "cebraspe" (com desconto proporcional), "fgv" (subtrativo direto) ou "fcc" (pesos fixos)
  formula_multiplier numeric(5,2) default 2.00, -- O multiplicador "K" na fórmula de erro (ex: 2.00 no Cebraspe)
  formula_explanation text default 'NF = NC - (K * (NE / TLE))', -- NF: nota final, NC: conteúdo, K: multiplicador, NE: erros, TLE: linhas efetivas
  
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 8. Tabela de Histórico de Redações Submetidas e Corrigidas pela IA
create table if not exists user_essays (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade,
  essay_config_id uuid references essay_configs(id) on delete cascade,
  prompt_theme text not null, -- Tema proposto pela IA
  user_draft text not null, -- Redação escrita pelo aluno
  score numeric(5,2), -- Nota final calculada pela IA
  eval_report jsonb, -- Relatório estruturado (erros gramaticais, notas por critério)
  submitted_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 9. Histórico de Progresso do Usuário
create table if not exists user_progress (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade,
  topic_id uuid references topics(id) on delete cascade,
  correct_count integer default 0,
  incorrect_count integer default 0,
  last_played timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, topic_id)
);

-- Habilitar RLS (Row Level Security) básica (opcional, pode ser customizado pelo usuário)
-- alter table profiles enable row level security;
-- alter table contests enable row level security;
-- alter table subjects enable row level security;
-- alter table topics enable row level security;
-- alter table topic_recurrence_stats enable row level security;
-- alter table study_materials enable row level security;
-- alter table essay_configs enable row level security;
-- alter table user_essays enable row level security;
-- alter table user_progress enable row level security;

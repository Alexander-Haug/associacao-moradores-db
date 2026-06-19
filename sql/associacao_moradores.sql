-- ============================================================================
--  PROJETO DE BANCO DE DADOS — ASSOCIAÇÃO DE MORADORES
--  Disciplina: Banco de Dados (CEAPI) — CDIA / PUC-SP
--  SGBD: SQLite 3
--  Arquivo executável: roda sem erros no DB Browser for SQLite e no Python (sqlite3)
-- ============================================================================
--  COMO USAR:
--    DB Browser:  Execute SQL  ->  cole este arquivo  ->  Run (F5)
--    Python:      sqlite3.connect("associacao_moradores.db").executescript(open(...).read())
-- ============================================================================

-- Garante que as chaves estrangeiras sejam de fato verificadas (no SQLite vêm
-- desligadas por padrão a cada conexão).
PRAGMA foreign_keys = ON;

-- Limpeza opcional para reexecução do script sem erro de "table already exists".
DROP TABLE IF EXISTS Reuniao_Participante;
DROP TABLE IF EXISTS Reserva_Area;
DROP TABLE IF EXISTS Reuniao;
DROP TABLE IF EXISTS Ocorrencia;
DROP TABLE IF EXISTS Contribuicao;
DROP TABLE IF EXISTS Morador_Unidade;
DROP TABLE IF EXISTS Morador;
DROP TABLE IF EXISTS Unidade;


-- ============================================================================
--  SEÇÃO 3 — CRIAÇÃO DAS TABELAS (DDL)
-- ============================================================================

-- ----------------------------------------------------------------------------
--  Unidade: cada apartamento/casa do condomínio. É a unidade física cobrada.
-- ----------------------------------------------------------------------------
CREATE TABLE Unidade (
    id_unidade INTEGER PRIMARY KEY AUTOINCREMENT,
    numero     INTEGER NOT NULL,
    bloco      TEXT    NOT NULL CHECK (bloco IN ('A','B')),
    tipo       TEXT    NOT NULL CHECK (tipo IN ('apartamento','casa')),
    area_m2    REAL    NOT NULL CHECK (area_m2 > 0),
    -- Não pode existir o mesmo número repetido dentro de um mesmo bloco.
    UNIQUE (numero, bloco)
);

-- ----------------------------------------------------------------------------
--  Morador: pessoa física. CPF é único (identifica a pessoa, não a unidade).
-- ----------------------------------------------------------------------------
CREATE TABLE Morador (
    id_morador      INTEGER PRIMARY KEY AUTOINCREMENT,
    nome            TEXT NOT NULL,
    -- CPF guardado só com dígitos (11 caracteres); UNIQUE evita cadastro duplicado.
    cpf             TEXT NOT NULL UNIQUE CHECK (length(cpf) = 11),
    email           TEXT,
    telefone        TEXT,
    data_nascimento TEXT   -- formato ISO 'AAAA-MM-DD'
);

-- ----------------------------------------------------------------------------
--  Morador_Unidade: tabela ASSOCIATIVA que resolve o N:M entre Morador e
--  Unidade. Um morador pode ocupar várias unidades ao longo do tempo e uma
--  unidade pode ter vários moradores (casal, troca de inquilino etc.).
--  data_saida NULL = vínculo ainda ativo.
-- ----------------------------------------------------------------------------
CREATE TABLE Morador_Unidade (
    id_morador_unidade INTEGER PRIMARY KEY AUTOINCREMENT,
    id_morador   INTEGER NOT NULL,
    id_unidade   INTEGER NOT NULL,
    tipo         TEXT    NOT NULL CHECK (tipo IN ('proprietario','inquilino')),
    data_entrada TEXT    NOT NULL,
    data_saida   TEXT,   -- NULL enquanto o morador ainda mora na unidade
    FOREIGN KEY (id_morador) REFERENCES Morador(id_morador),
    FOREIGN KEY (id_unidade) REFERENCES Unidade(id_unidade),
    -- Saída nunca pode ser anterior à entrada.
    CHECK (data_saida IS NULL OR data_saida >= data_entrada)
);

-- ----------------------------------------------------------------------------
--  Contribuicao: cobrança mensal (taxa de condomínio) por UNIDADE.
--  Relação 1:N -> uma unidade tem muitas contribuições (uma por mês).
-- ----------------------------------------------------------------------------
CREATE TABLE Contribuicao (
    id_contribuicao INTEGER PRIMARY KEY AUTOINCREMENT,
    id_unidade      INTEGER NOT NULL,
    mes_referencia  TEXT    NOT NULL,                 -- 'AAAA-MM'
    valor           REAL    NOT NULL CHECK (valor > 0),
    data_pagamento  TEXT,                             -- NULL enquanto não pago
    status          TEXT    NOT NULL CHECK (status IN ('pago','pendente','atrasado')),
    FOREIGN KEY (id_unidade) REFERENCES Unidade(id_unidade),
    -- Uma única cobrança por unidade em cada mês de referência.
    UNIQUE (id_unidade, mes_referencia),
    -- Regra de integridade: se está 'pago', precisa ter data de pagamento;
    -- se não está pago, não pode ter data de pagamento.
    CHECK (
        (status = 'pago'  AND data_pagamento IS NOT NULL) OR
        (status <> 'pago' AND data_pagamento IS NULL)
    )
);

-- ----------------------------------------------------------------------------
--  Ocorrencia: chamado/reclamação aberta por um morador, vinculada à unidade.
--  Relação 1:N a partir de Morador e a partir de Unidade.
-- ----------------------------------------------------------------------------
CREATE TABLE Ocorrencia (
    id_ocorrencia INTEGER PRIMARY KEY AUTOINCREMENT,
    id_morador    INTEGER NOT NULL,
    id_unidade    INTEGER NOT NULL,
    tipo          TEXT    NOT NULL,   -- ex.: 'Barulho', 'Vazamento', 'Manutenção'
    descricao     TEXT,
    data          TEXT    NOT NULL,
    status        TEXT    NOT NULL CHECK (status IN ('aberta','em andamento','resolvida')),
    FOREIGN KEY (id_morador) REFERENCES Morador(id_morador),
    FOREIGN KEY (id_unidade) REFERENCES Unidade(id_unidade)
);

-- ----------------------------------------------------------------------------
--  Reuniao: assembleias e reuniões da associação.
-- ----------------------------------------------------------------------------
CREATE TABLE Reuniao (
    id_reuniao INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo     TEXT NOT NULL,
    data       TEXT NOT NULL,
    local      TEXT,
    pauta      TEXT,
    ata        TEXT,   -- preenchida depois da reunião realizada
    status     TEXT NOT NULL CHECK (status IN ('agendada','realizada','cancelada'))
);

-- ----------------------------------------------------------------------------
--  Reserva_Area: reserva de área comum por um morador.
--  Relação 1:N -> um morador faz muitas reservas.
-- ----------------------------------------------------------------------------
CREATE TABLE Reserva_Area (
    id_reserva  INTEGER PRIMARY KEY AUTOINCREMENT,
    area_comum  TEXT    NOT NULL CHECK (area_comum IN ('salao','churrasqueira','quadra','piscina','playground')),
    id_morador  INTEGER NOT NULL,
    data        TEXT    NOT NULL,
    hora_inicio TEXT    NOT NULL,   -- 'HH:MM'
    hora_fim    TEXT    NOT NULL,   -- 'HH:MM'
    status      TEXT    NOT NULL CHECK (status IN ('confirmada','pendente','cancelada')),
    FOREIGN KEY (id_morador) REFERENCES Morador(id_morador),
    -- Horário de término precisa ser depois do início.
    CHECK (hora_fim > hora_inicio)
);

-- ----------------------------------------------------------------------------
--  Reuniao_Participante: tabela ASSOCIATIVA (N:M) entre Reuniao e Morador.
--  Necessária para registrar "reuniões com participantes" / presença.
--  PK composta evita o mesmo morador duas vezes na mesma reunião.
-- ----------------------------------------------------------------------------
CREATE TABLE Reuniao_Participante (
    id_reuniao INTEGER NOT NULL,
    id_morador INTEGER NOT NULL,
    presente   INTEGER NOT NULL DEFAULT 1 CHECK (presente IN (0,1)),  -- 0=ausente, 1=presente
    PRIMARY KEY (id_reuniao, id_morador),
    FOREIGN KEY (id_reuniao) REFERENCES Reuniao(id_reuniao),
    FOREIGN KEY (id_morador) REFERENCES Morador(id_morador)
);


-- ============================================================================
--  SEÇÃO 4 — INSERÇÃO DE DADOS DE TESTE
-- ============================================================================

-- ---- Unidades (8 unidades: 4 no bloco A, 4 no bloco B) ---------------------
-- Bloco A = apartamentos; Bloco B = casas (sobrados).
INSERT INTO Unidade (numero, bloco, tipo, area_m2) VALUES
    (101, 'A', 'apartamento', 65.5),   -- id 1
    (102, 'A', 'apartamento', 65.5),   -- id 2
    (201, 'A', 'apartamento', 72.0),   -- id 3
    (202, 'A', 'apartamento', 72.0),   -- id 4
    (1,   'B', 'casa',        120.0),  -- id 5
    (2,   'B', 'casa',        120.0),  -- id 6
    (3,   'B', 'casa',        95.0),   -- id 7
    (4,   'B', 'casa',        95.0);   -- id 8

-- ---- Moradores (12 moradores) ---------------------------------------------
INSERT INTO Morador (nome, cpf, email, telefone, data_nascimento) VALUES
    ('Ana Carolina Souza',     '12345678901', 'ana.souza@email.com',      '(11) 98123-4501', '1985-04-12'), -- 1
    ('Bruno Henrique Lima',    '23456789012', 'bruno.lima@email.com',     '(11) 98123-4502', '1990-09-23'), -- 2
    ('Carla Mendes Oliveira',  '34567890123', 'carla.mendes@email.com',   '(11) 98123-4503', '1978-12-01'), -- 3
    ('Diego Ferreira Santos',  '45678901234', 'diego.santos@email.com',   '(11) 98123-4504', '1995-06-15'), -- 4
    ('Eduarda Ribeiro Alves',  '56789012345', 'eduarda.alves@email.com',  '(11) 98123-4505', '1982-02-28'), -- 5
    ('Felipe Augusto Costa',   '67890123456', 'felipe.costa@email.com',   '(11) 98123-4506', '1998-11-07'), -- 6
    ('Gabriela Martins Rocha', '78901234567', 'gabriela.rocha@email.com', '(11) 98123-4507', '1988-07-19'), -- 7
    ('Henrique Barbosa Dias',  '89012345678', 'henrique.dias@email.com',  '(11) 98123-4508', '1975-03-30'), -- 8
    ('Isabela Cardoso Pinto',  '90123456789', 'isabela.pinto@email.com',  '(11) 98123-4509', '1993-10-05'), -- 9
    ('Joao Pedro Almeida',     '01234567890', 'joao.almeida@email.com',   '(11) 98123-4510', '1991-01-22'), -- 10
    ('Larissa Gomes Teixeira', '11223344556', 'larissa.gomes@email.com',  '(11) 98123-4511', '1987-08-14'), -- 11
    ('Marcos Vinicius Nunes',  '22334455667', 'marcos.nunes@email.com',   '(11) 98123-4512', '1996-05-03'); -- 12

-- ---- Vínculos Morador x Unidade -------------------------------------------
-- Casos demonstram o N:M: unidades com 2 moradores (casal), e um morador
-- (Marcos, id 12) que TROCOU de unidade no tempo (vínculo encerrado + novo).
INSERT INTO Morador_Unidade (id_morador, id_unidade, tipo, data_entrada, data_saida) VALUES
    (1,  1, 'proprietario', '2018-03-15', NULL),
    (2,  2, 'proprietario', '2019-07-01', NULL),
    (11, 2, 'proprietario', '2019-07-01', NULL),                 -- cônjuge co-proprietário da unidade 2
    (3,  3, 'inquilino',    '2021-02-10', NULL),
    (4,  4, 'proprietario', '2017-11-20', NULL),
    (5,  5, 'proprietario', '2015-05-05', NULL),
    (9,  5, 'proprietario', '2015-05-05', NULL),                 -- co-proprietária da unidade 5
    (6,  6, 'inquilino',    '2022-01-15', NULL),
    (10, 6, 'inquilino',    '2022-01-15', NULL),                 -- casal alugando a unidade 6
    (7,  7, 'proprietario', '2020-09-30', NULL),
    (8,  8, 'proprietario', '2016-08-12', NULL),
    (12, 8, 'inquilino',    '2021-06-01', '2023-12-20'),         -- vínculo ANTIGO (já saiu)
    (12, 7, 'inquilino',    '2024-01-10', NULL);                 -- vínculo ATUAL do mesmo morador

-- ---- Contribuições: 3 meses de referência (jan, fev, mar/2025) -------------
-- Valor: apartamentos (unid. 1-4) = R$ 450,00 ; casas (unid. 5-8) = R$ 650,00.
-- Status variados para validar consultas de inadimplência e arrecadação.

-- Janeiro/2025 (quase tudo pago)
INSERT INTO Contribuicao (id_unidade, mes_referencia, valor, data_pagamento, status) VALUES
    (1, '2025-01', 450.0, '2025-01-08', 'pago'),
    (2, '2025-01', 450.0, '2025-01-05', 'pago'),
    (3, '2025-01', 450.0, '2025-01-10', 'pago'),
    (4, '2025-01', 450.0, NULL,         'atrasado'),   -- unidade 4 inadimplente desde jan
    (5, '2025-01', 650.0, '2025-01-07', 'pago'),
    (6, '2025-01', 650.0, '2025-01-09', 'pago'),
    (7, '2025-01', 650.0, '2025-01-06', 'pago'),
    (8, '2025-01', 650.0, '2025-01-12', 'pago');

-- Fevereiro/2025 (mistura maior)
INSERT INTO Contribuicao (id_unidade, mes_referencia, valor, data_pagamento, status) VALUES
    (1, '2025-02', 450.0, '2025-02-08', 'pago'),
    (2, '2025-02', 450.0, '2025-02-06', 'pago'),
    (3, '2025-02', 450.0, NULL,         'pendente'),
    (4, '2025-02', 450.0, NULL,         'atrasado'),
    (5, '2025-02', 650.0, '2025-02-09', 'pago'),
    (6, '2025-02', 650.0, NULL,         'atrasado'),
    (7, '2025-02', 650.0, '2025-02-05', 'pago'),
    (8, '2025-02', 650.0, '2025-02-11', 'pago');

-- Março/2025 (vários em aberto)
INSERT INTO Contribuicao (id_unidade, mes_referencia, valor, data_pagamento, status) VALUES
    (1, '2025-03', 450.0, '2025-03-07', 'pago'),
    (2, '2025-03', 450.0, NULL,         'pendente'),
    (3, '2025-03', 450.0, NULL,         'pendente'),
    (4, '2025-03', 450.0, NULL,         'atrasado'),
    (5, '2025-03', 650.0, '2025-03-08', 'pago'),
    (6, '2025-03', 650.0, NULL,         'atrasado'),
    (7, '2025-03', 650.0, NULL,         'pendente'),
    (8, '2025-03', 650.0, '2025-03-10', 'pago');

-- ---- Ocorrências (6 tipos diferentes) -------------------------------------
INSERT INTO Ocorrencia (id_morador, id_unidade, tipo, descricao, data, status) VALUES
    (3, 3, 'Barulho',             'Som alto vindo da unidade vizinha apos as 23h.',          '2025-03-02', 'aberta'),
    (5, 5, 'Vazamento',           'Infiltracao no teto da garagem proxima a casa 1.',        '2025-03-05', 'em andamento'),
    (1, 1, 'Manutencao Elevador', 'Elevador do bloco A travando entre andares.',             '2025-02-18', 'resolvida'),
    (7, 7, 'Animal Solto',        'Cachorro sem coleira circulando na area comum.',          '2025-03-11', 'aberta'),
    (2, 2, 'Vaga de Garagem',     'Carro estacionado em vaga de outro morador.',             '2025-01-25', 'resolvida'),
    (8, 8, 'Iluminacao',          'Lampada queimada no corredor externo do bloco B.',        '2025-03-14', 'em andamento');

-- ---- Reuniões (2) ----------------------------------------------------------
INSERT INTO Reuniao (titulo, data, local, pauta, ata, status) VALUES
    ('Assembleia Geral Ordinaria 2025',
     '2025-03-20', 'Salao de Festas',
     'Prestacao de contas 2024; aprovacao do orcamento 2025; eleicao do sindico.',
     'Aprovadas as contas de 2024 por maioria. Orcamento 2025 aprovado com reajuste de 5% na taxa. Sindico reeleito.',
     'realizada'),
    ('Reuniao Extraordinaria - Reforma da Fachada',
     '2025-04-15', 'Salao de Festas',
     'Apresentacao de orcamentos para pintura da fachada e definicao de rateio.',
     NULL,
     'agendada');

-- ---- Participantes das reuniões (N:M) -------------------------------------
-- Reunião 1 (Assembleia, realizada): vários moradores, alguns ausentes.
INSERT INTO Reuniao_Participante (id_reuniao, id_morador, presente) VALUES
    (1, 1, 1),
    (1, 2, 1),
    (1, 4, 0),   -- convocado, mas ausente
    (1, 5, 1),
    (1, 7, 1),
    (1, 8, 1),
    (1, 11, 0);  -- ausente
-- Reunião 2 (Extraordinária, agendada): confirmados como participantes.
INSERT INTO Reuniao_Participante (id_reuniao, id_morador, presente) VALUES
    (2, 1, 1),
    (2, 3, 1),
    (2, 5, 1),
    (2, 6, 1);

-- ---- Reservas de áreas comuns (3) -----------------------------------------
INSERT INTO Reserva_Area (area_comum, id_morador, data, hora_inicio, hora_fim, status) VALUES
    ('salao',         1, '2025-05-10', '14:00', '22:00', 'confirmada'),
    ('churrasqueira', 5, '2025-05-17', '11:00', '16:00', 'confirmada'),
    ('quadra',        7, '2025-05-20', '18:00', '20:00', 'pendente');


-- ============================================================================
--  SEÇÃO 5 — CONSULTAS DE EXEMPLO (DQL)
--  Execute cada bloco separadamente para ver os resultados.
-- ============================================================================

-- ---- 5.1) Moradores INADIMPLENTES --------------------------------------------
-- Lista moradores ATIVOS (data_saida IS NULL) cuja unidade tem contribuição
-- 'pendente' ou 'atrasada', somando o total em aberto por pessoa.
SELECT  m.nome,
        u.bloco,
        u.numero,
        COUNT(*)            AS qtd_em_aberto,
        SUM(c.valor)        AS total_devido
FROM    Contribuicao   c
JOIN    Unidade        u  ON u.id_unidade = c.id_unidade
JOIN    Morador_Unidade mu ON mu.id_unidade = u.id_unidade AND mu.data_saida IS NULL
JOIN    Morador        m  ON m.id_morador = mu.id_morador
WHERE   c.status IN ('pendente','atrasado')
GROUP BY m.id_morador, u.bloco, u.numero
ORDER BY total_devido DESC;

-- ---- 5.2) Ocorrências ABERTAS por bloco --------------------------------------
-- Conta ocorrências não resolvidas (abertas + em andamento) agrupadas por bloco.
SELECT  u.bloco,
        COUNT(*) AS ocorrencias_em_aberto
FROM    Ocorrencia o
JOIN    Unidade    u ON u.id_unidade = o.id_unidade
WHERE   o.status IN ('aberta','em andamento')
GROUP BY u.bloco
ORDER BY ocorrencias_em_aberto DESC;

-- ---- 5.3) Histórico de RESERVAS por morador ----------------------------------
SELECT  m.nome,
        r.area_comum,
        r.data,
        r.hora_inicio,
        r.hora_fim,
        r.status
FROM    Reserva_Area r
JOIN    Morador      m ON m.id_morador = r.id_morador
ORDER BY m.nome, r.data;

-- ---- 5.4) Total ARRECADADO por mês -------------------------------------------
-- Soma apenas o que foi efetivamente pago em cada mês de referência.
SELECT  c.mes_referencia,
        COUNT(*)     AS qtd_pagamentos,
        SUM(c.valor) AS total_arrecadado
FROM    Contribuicao c
WHERE   c.status = 'pago'
GROUP BY c.mes_referencia
ORDER BY c.mes_referencia;

-- ---- 5.5) ATAS das reuniões já realizadas ------------------------------------
SELECT  titulo,
        data,
        local,
        ata
FROM    Reuniao
WHERE   status = 'realizada'
  AND   ata IS NOT NULL
ORDER BY data DESC;

-- ---- 5.6) (extra) Lista de PRESENÇA por reunião ------------------------------
-- Demonstra o uso da tabela associativa Reuniao_Participante (N:M).
SELECT  re.titulo,
        re.data,
        m.nome,
        CASE WHEN rp.presente = 1 THEN 'Presente' ELSE 'Ausente' END AS presenca
FROM    Reuniao_Participante rp
JOIN    Reuniao re ON re.id_reuniao = rp.id_reuniao
JOIN    Morador m  ON m.id_morador  = rp.id_morador
ORDER BY re.data, m.nome;

-- ---- 5.7) (extra) Moradores ATIVOS por unidade -------------------------------
-- Mostra quem mora hoje em cada unidade (vínculo sem data de saída).
SELECT  u.bloco,
        u.numero,
        u.tipo,
        m.nome,
        mu.tipo AS vinculo
FROM    Morador_Unidade mu
JOIN    Unidade u ON u.id_unidade = mu.id_unidade
JOIN    Morador m ON m.id_morador = mu.id_morador
WHERE   mu.data_saida IS NULL
ORDER BY u.bloco, u.numero;

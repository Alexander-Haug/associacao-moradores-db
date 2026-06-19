# 🏢 Sistema de Banco de Dados — Associação de Moradores

![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-ANSI-orange)
![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?logo=jupyter&logoColor=white)
![Status](https://img.shields.io/badge/status-concluído-success)

Banco de dados relacional que centraliza toda a gestão de uma associação de moradores — **moradores, unidades, taxas de condomínio, ocorrências, reuniões e reservas de áreas comuns** — em uma única base íntegra e consultável.

> Projeto desenvolvido para a disciplina **Banco de Dados (CEAPI)** do curso de **Ciência de Dados e Inteligência Artificial (CDIA) — PUC-SP**.

---

## 📑 Índice

- [O problema](#-o-problema)
- [A solução](#-a-solução)
- [Diagrama Entidade-Relacionamento](#-diagrama-entidade-relacionamento)
- [Tecnologias](#-tecnologias)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Como executar](#-como-executar)
- [Exemplos de consultas](#-exemplos-de-consultas)
- [Destaques técnicos](#-destaques-técnicos)
- [Documentação](#-documentação)
- [Autores](#-autores)

---

## 🎯 O problema

Associações de moradores costumam controlar tudo de forma manual e dispersa — planilhas soltas, cadernos, grupos de mensagens e papéis, sem nenhuma integração. Isso gera dores reais:

- ❌ **Inadimplência sem visibilidade** — não se sabe rapidamente quem está devendo, em qual mês e quanto.
- ❌ **Histórico que se perde** — quando muda o inquilino ou o proprietário de uma unidade, o registro de ocupação desaparece.
- ❌ **Ocorrências esquecidas** — reclamações informais ficam sem status nem responsável.
- ❌ **Conflitos de reserva** — áreas comuns marcadas por mensagem geram dupla reserva.
- ❌ **Decisões pouco transparentes** — pautas e atas dispersas dificultam comprovar o que foi decidido e quem participou.

## 💡 A solução

Um banco de dados relacional em **SQLite** com **8 tabelas** que elimina duplicidades e inconsistências, oferecendo:

- ✅ Identificação imediata de inadimplentes e cálculo automático da arrecadação por mês.
- ✅ Histórico completo dos vínculos morador–unidade ao longo do tempo.
- ✅ Rastreabilidade de ocorrências (com status e responsável) e controle de reservas sem conflito.
- ✅ Relatórios gerenciais em segundos, via consultas SQL.

---

## 🗺️ Diagrama Entidade-Relacionamento

<p align="center">
  <img src="docs/er_diagram.png" alt="Diagrama Entidade-Relacionamento" width="430"/>
</p>

O modelo conta com **8 tabelas**: as 7 entidades principais mais a tabela associativa `Reuniao_Participante`. Os relacionamentos cobrem os três tipos de cardinalidade:

| Relacionamento | Cardinalidade | Como é resolvido |
|---|---|---|
| Morador ↔ Unidade | **N:M** | Tabela associativa `Morador_Unidade` |
| Reunião ↔ Morador | **N:M** | Tabela associativa `Reuniao_Participante` |
| Unidade → Contribuição | **1:N** | Chave estrangeira em `Contribuicao` |
| Morador / Unidade → Ocorrência | **1:N** | Chaves estrangeiras em `Ocorrencia` |
| Morador → Reserva de Área | **1:N** | Chave estrangeira em `Reserva_Area` |

---

## 🛠️ Tecnologias

- **SGBD:** SQLite 3 (arquivo único, sem servidor, compatível com [DB Browser for SQLite](https://sqlitebrowser.org/))
- **Linguagem:** SQL (DDL, DML e DQL)
- **Análise/execução:** Python 3, `sqlite3` e `pandas` (via Jupyter Notebook)

---

## 📂 Estrutura do repositório

```
associacao-moradores-db/
├── README.md
├── sql/
│   └── associacao_moradores.sql        # Script completo: CREATE + INSERT + consultas
├── notebook/
│   └── Projeto_Banco_de_Dados.ipynb    # Projeto autoexecutável (cria o .db e roda as queries)
├── docs/
│   ├── Documentacao_Projeto.docx       # Documentação formal completa
│   └── er_diagram.png                   # Diagrama ER
└── database/
    └── associacao_moradores.db          # Banco já populado, pronto para abrir
```

---

## ▶️ Como executar

### Opção 1 — DB Browser for SQLite (mais simples)
1. Baixe o [DB Browser for SQLite](https://sqlitebrowser.org/).
2. Abra o arquivo `database/associacao_moradores.db`.
3. Vá em **Execute SQL** e rode qualquer consulta da seção abaixo.

### Opção 2 — Recriar do zero pelo script
```bash
sqlite3 associacao_moradores.db < sql/associacao_moradores.sql
```

### Opção 3 — Jupyter Notebook (recomendado)
```bash
pip install pandas notebook
jupyter notebook notebook/Projeto_Banco_de_Dados.ipynb
```
O notebook cria o banco, insere os dados e executa todas as consultas exibindo os resultados em tabelas.

---

## 🔎 Exemplos de consultas

**Moradores inadimplentes** — junta 4 tabelas para listar quem deve e quanto:

```sql
SELECT m.nome, u.bloco, u.numero,
       COUNT(*) AS qtd_em_aberto, SUM(c.valor) AS total_devido
FROM Contribuicao c
JOIN Unidade u  ON u.id_unidade = c.id_unidade
JOIN Morador_Unidade mu ON mu.id_unidade = u.id_unidade AND mu.data_saida IS NULL
JOIN Morador m  ON m.id_morador = mu.id_morador
WHERE c.status IN ('pendente','atrasado')
GROUP BY m.id_morador, u.bloco, u.numero
ORDER BY total_devido DESC;
```

| nome | bloco | numero | qtd_em_aberto | total_devido |
|---|---|---|---|---|
| Diego Ferreira Santos | A | 202 | 3 | 1350.0 |
| Felipe Augusto Costa | B | 2 | 2 | 1300.0 |
| Carla Mendes Oliveira | A | 201 | 2 | 900.0 |

**Total arrecadado por mês** — soma apenas o que foi efetivamente pago:

```sql
SELECT mes_referencia, COUNT(*) AS qtd_pagamentos, SUM(valor) AS total_arrecadado
FROM Contribuicao
WHERE status = 'pago'
GROUP BY mes_referencia
ORDER BY mes_referencia;
```

| mes_referencia | qtd_pagamentos | total_arrecadado |
|---|---|---|
| 2025-01 | 7 | 3950.0 |
| 2025-02 | 5 | 2850.0 |
| 2025-03 | 3 | 1750.0 |

> O script traz **7 consultas** prontas: inadimplentes, ocorrências abertas por bloco, histórico de reservas, arrecadação por mês, atas, lista de presença e ocupação atual das unidades.

---

## ⭐ Destaques técnicos

- **Tabelas associativas para N:M** — `Morador_Unidade` e `Reuniao_Participante` resolvem os relacionamentos muitos-para-muitos e ainda carregam atributos próprios (tipo de vínculo, datas de entrada/saída, presença).
- **Integridade referencial** — `PRAGMA foreign_keys = ON` e chaves estrangeiras em todas as ligações impedem registros órfãos.
- **Restrições de domínio e de negócio** — `CHECK` valida status, tipos e valores positivos; uma contribuição só pode ter `data_pagamento` quando está paga; `data_saida` nunca é anterior à `data_entrada`.
- **Restrições de unicidade** — CPF único por morador; uma única contribuição por unidade em cada mês de referência.
- **Histórico temporal** — o campo `data_saida` nulo indica vínculo ativo, permitindo registrar mudanças de morador sem perder o histórico.

---

## 📄 Documentação

A documentação completa — diagnóstico, modelagem detalhada e dicionário de dados de cada entidade — está em [`docs/Documentacao_Projeto.docx`](docs/Documentacao_Projeto.docx) e também dentro do [notebook](notebook/Projeto_Banco_de_Dados.ipynb).

---

## 👥 Autores

Projeto acadêmico desenvolvido em grupo para a disciplina de Banco de Dados (CEAPI) — CDIA / PUC-SP.

- _Seu nome aqui_
- _Integrante 2_
- _Integrante 3_

---

<p align="center"><i>Projeto acadêmico — PUC-SP · 2025</i></p>

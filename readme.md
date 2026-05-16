Aqui está o passo a passo completo organizado de forma clara:

---

## Fase 0 — Preparar o ambiente

**Passo 1: Instalar o Python**
Acesse python.org/downloads, baixe e instale. Durante a instalação, marque obrigatoriamente a opção "Add Python to PATH".

**Passo 2: Instalar as bibliotecas**
Abra o terminal (Prompt de Comando no Windows) e execute:
```
pip install jupyter pandas numpy matplotlib seaborn openpyxl
```

**Passo 3: Instalar o DB Browser for SQLite**
Baixe gratuitamente em sqlitebrowser.org/dl — serve para visualizar o banco de dados gerado.

---

## Fase 1 — Organizar a pasta do projeto

**Passo 4: Criar a estrutura de arquivos**
Crie uma pasta chamada `projeto_transporte` e coloque todos os arquivos baixados dentro dela:
```
projeto_transporte/
├── Pasta1.xlsx                   ← dataset original
├── etl_transporte_app.ipynb      ← notebook Python
├── modelo_sql_transporte.sql     ← script SQL
└── relatorio_storytelling.html   ← relatório visual
```
⚠️ O `Pasta1.xlsx` deve estar na mesma pasta que o `.ipynb`, senão o Python não encontra os dados.

---

## Fase 2 — Rodar o Notebook Python (ETL)

**Passo 5: Abrir o terminal dentro da pasta**
No Windows: abra a pasta no Explorer, clique na barra de endereço, digite `cmd` e pressione Enter.

**Passo 6: Iniciar o Jupyter**
```
jupyter notebook
```
O navegador abre automaticamente em `http://localhost:8888` com a lista de arquivos.

**Passo 7: Executar o notebook**
Clique em `etl_transporte_app.ipynb`. Quando abrir, vá em:
**Kernel → Restart & Run All**

Aguarde 1–3 minutos. Células executadas com sucesso mostram `[1]`, `[2]`, etc.

**Passo 8: Confirmar os arquivos gerados**
Após a execução, dois novos arquivos aparecem na pasta:
```
transporte_limpo.csv   ← dados tratados para o Power BI
transporte.db          ← banco de dados SQLite
```

---

## Fase 3 — Executar o Script SQL

**Passo 9: Abrir o banco no DB Browser**
Inicie o DB Browser for SQLite → clique "Open Database" → selecione `transporte.db`.

**Passo 10: Executar o script SQL**
Clique na aba "Execute SQL". Abra o arquivo `modelo_sql_transporte.sql` em um bloco de notas, copie todo o conteúdo, cole no DB Browser e clique em ▶ Run.

**Passo 11: Testar se funcionou**
Ainda na aba Execute SQL, rode:
```sql
SELECT * FROM vw_kpi_status;
```
Deve retornar 5 linhas com os status das corridas e suas métricas.

---

## Fase 4 — Montar o Dashboard no Power BI

**Passo 12: Instalar o Power BI Desktop**
Baixe gratuitamente em microsoft.com/power-bi/desktop.

**Passo 13: Importar os dados**
No Power BI: Obter dados → Texto/CSV → selecione `transporte_limpo.csv` → Carregar.

**Passo 14: Criar os 3 KPIs obrigatórios**

| KPI | Visual | Campo Eixo | Campo Valor |
|---|---|---|---|
| Taxa Sucesso vs Cancelamento | Gráfico de rosca | `Booking Status` | Contagem |
| Receita por Local | Gráfico de barras | `Pickup Location` | Soma de `Booking Value` |
| Ranking por Veículo | Matriz | `Vehicle Type` | `cancel_reason_unified` |

**Passo 15: Adicionar filtros (Slicers)**
Insira "Segmentação de Dados" para `Vehicle Type`, `order_month` e `vtat_category`.

**Passo 16: Salvar como `.pbix`**
Arquivo → Salvar como → `dashboard_transporte.pbix` na pasta do projeto.

---

## Fase 5 — Abrir o Relatório HTML

**Passo 17: Duplo clique no HTML**
Simplesmente dê duplo clique em `relatorio_storytelling.html`. Abre direto no Chrome/Edge sem precisar de nada instalado. Os gráficos são interativos e funcionam completamente offline.

---

## Resultado final da pasta entregável

```
projeto_transporte/
├── Pasta1.xlsx                   ← dado original
├── etl_transporte_app.ipynb      ← Camada 1: Python ETL
├── transporte_limpo.csv          ← gerado pelo Python
├── transporte.db                 ← gerado pelo Python
├── modelo_sql_transporte.sql     ← Camada 2: SQL + Views
├── dashboard_transporte.pbix     ← Camada 3: Power BI
└── relatorio_storytelling.html   ← Storytelling executivo
```

A ordem correta é sempre: **Python primeiro → SQL segundo → Power BI por último**, pois cada etapa depende dos arquivos gerados pela anterior.
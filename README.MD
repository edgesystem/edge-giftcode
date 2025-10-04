# 🎁 EDGE PROMOTION CODES  
### Sistema Universal de Giftcodes para Servidores FiveM  
💎 Compatível com **QBCore** e **ESX**

---

## 🧩 Sobre

O **Edge Promotion Codes** é um sistema modular de códigos promocionais desenvolvido pelo **Edge System**.  
Permite criar e resgatar códigos que oferecem recompensas em **dinheiro, itens ou veículos**, com limite de uso, expiração e controle individual por jogador.

Desenvolvido com foco em **simplicidade, segurança e escalabilidade**, o sistema é base para futuras integrações com o **Painel Edge Web** — onde será possível visualizar estatísticas, logs e gerar códigos automáticos.

---

## ⚙️ Requisitos

| Dependência | Função |
|--------------|--------|
| **ox_lib** | Interface de input e notificações |
| **oxmysql** | Comunicação com o banco de dados |
| **QBCore / ESX** | Framework principal |
| **ox_inventory / qb-inventory / ps-inventory** | Gerenciamento de recompensas do tipo item |

---

## 🗄️ Banco de Dados

Execute o SQL incluso (`sql.sql`):

```sql
CREATE TABLE IF NOT EXISTS edge_giftcodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255) NOT NULL,
    reward VARCHAR(255) NOT NULL,
    amount INT DEFAULT 1,
    reward_type VARCHAR(50) NOT NULL,
    max_redeem INT DEFAULT 1,
    current_redeem INT DEFAULT 0,
    expire_at DATETIME
);

CREATE TABLE IF NOT EXISTS edge_user_giftcodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,
    code VARCHAR(255) NOT NULL
);
⚙️ Configuração (config.lua)
lua
Copiar código
Config.Framework = 'QBCore' -- ou 'ESX'
Config.CheckUserRedeem = true   -- Evita múltiplos resgates pelo mesmo jogador
Config.LimitRedeem = true       -- Limita o número total de usos
Config.ExpireGiftcode = true    -- Ativa expiração automática
Config.AllowedGroup = 'admin'   -- Grupo que pode criar códigos
Config.Inventory = 'ox_inventory' -- Inventário utilizado
💬 Comandos
👑 /codigoedge
Cria um novo código de presente (apenas administradores).

Campos:

Código (ex: EDGE2025)

Recompensa (item, conta ou veículo)

Quantidade (ex: 1, 10000)

Tipo (money, item, vehicle)

Máximo de usos

Expiração (AAAA-MM-DD)

📦 Exemplo:

yaml
Copiar código
/codigoedge
→ Código: EDGEVIP
→ Recompensa: bank
→ Tipo: money
→ Quantidade: 10000
→ Máximo: 5
→ Expira: 2025-12-31
💬 /codigo
Permite que o jogador insira um código e receba sua recompensa.

📜 Exemplo:

bash
Copiar código
/codigo
→ EDGEVIP
🟢 Mensagem:

“Você recebeu sua recompensa 10000 bank!”

🚗 Recompensas suportadas
Tipo	Ação
money	Adiciona valor à conta (bank, dinheiro, dinheiro_sujo)
item	Entrega item no inventário configurado
vehicle	Spawna veículo e grava na base (player_vehicles / owned_vehicles)

🔒 Segurança e Logs
Proteção contra uso duplicado (CheckUserRedeem)

Validação de expiração (ExpireGiftcode)

Limite total de uso (LimitRedeem)

Logs no console em cada ação:

Criação de código

Tentativas inválidas

Expiração

Resgates bem-sucedidos

Entrega de recompensas

🧠 Todos os logs seguem o padrão:

csharp
Copiar código
[Edge System] ✅ Player João resgatou o código: EDGE2025
🧱 Arquitetura do Sistema
Arquivo	Função
client.lua	Interface com jogador, input e spawn
server.lua	Validação, banco de dados e lógica principal
config.lua	Configurações gerais
sql.sql	Estrutura de tabelas
fxmanifest.lua	Declaração do recurso FiveM

🧠 Planejamento Futuro
Módulo	Função
🌐 Painel Edge Web	Controle total de campanhas e logs
💸 Integração com Stripe/Tebex	Venda direta de giftcodes premium
🧩 API REST	Comunicação com sistemas de cidades (EdgeFlow)
📊 Dashboard Analytics	Métricas de uso e performance
⚡ Sistema de Parceiros	Geração de códigos por afiliados

💚 Créditos
Desenvolvido por: Mestre Edge Thug
Organização: Edge System
Versão: 1.0.0
Frameworks: QBCore / ESX
Bibliotecas: ox_lib, oxmysql, qb/ps/ox inventory
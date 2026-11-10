-- Folha de custos DM
-- Execute este ficheiro no SQL Editor do Supabase.

create extension if not exists pgcrypto;

create table if not exists public.custos_envios (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null default auth.uid() references auth.users(id) on delete restrict,

  data_envio date,
  numero_fatura text,
  cliente_destino text,
  descricao_carga text not null default '',
  transportadora text,

  pv_venda numeric(14,2) not null default 0 check (pv_venda >= 0),
  preco_compra numeric(14,2) not null default 0 check (preco_compra >= 0),
  custo_transporte numeric(14,2) not null default 0 check (custo_transporte >= 0),
  custo_mao_obra numeric(14,2) not null default 0 check (custo_mao_obra >= 0),
  custo_deslocacao numeric(14,2) not null default 0 check (custo_deslocacao >= 0),
  outros_custos_operacionais numeric(14,2) not null default 0 check (outros_custos_operacionais >= 0),
  comissao_vendedor_percentagem numeric(7,4) not null default 0
    check (comissao_vendedor_percentagem >= 0 and comissao_vendedor_percentagem <= 100),
  outros_custos numeric(14,2) not null default 0 check (outros_custos >= 0),

  observacoes text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

comment on table public.custos_envios is
  'Registo partilhado dos custos de cada envio da Domingos & Morgado.';

comment on column public.custos_envios.comissao_vendedor_percentagem is
  'Percentagem sobre o PV. Exemplo: guardar 5 para representar 5%.';

create index if not exists custos_envios_data_idx
  on public.custos_envios (data_envio desc);

create index if not exists custos_envios_fatura_idx
  on public.custos_envios (numero_fatura);

create index if not exists custos_envios_atualizado_idx
  on public.custos_envios (atualizado_em desc);

create or replace function public.atualizar_data_modificacao()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$;

drop trigger if exists custos_envios_atualizado_em on public.custos_envios;
create trigger custos_envios_atualizado_em
before update on public.custos_envios
for each row execute function public.atualizar_data_modificacao();

alter table public.custos_envios enable row level security;

drop policy if exists "Utilizadores autenticados podem consultar custos" on public.custos_envios;
create policy "Utilizadores autenticados podem consultar custos"
on public.custos_envios
for select
to authenticated
using (created_by = auth.uid());

drop policy if exists "Utilizadores autenticados podem criar custos" on public.custos_envios;
create policy "Utilizadores autenticados podem criar custos"
on public.custos_envios
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "Utilizadores autenticados podem atualizar custos" on public.custos_envios;
create policy "Utilizadores autenticados podem atualizar custos"
on public.custos_envios
for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists "Utilizadores autenticados podem eliminar custos" on public.custos_envios;
create policy "Utilizadores autenticados podem eliminar custos"
on public.custos_envios
for delete
to authenticated
using (created_by = auth.uid());

revoke all on table public.custos_envios from anon;
grant select, insert, delete on table public.custos_envios to authenticated;
grant update (
  data_envio,
  numero_fatura,
  cliente_destino,
  descricao_carga,
  transportadora,
  pv_venda,
  preco_compra,
  custo_transporte,
  custo_mao_obra,
  custo_deslocacao,
  outros_custos_operacionais,
  comissao_vendedor_percentagem,
  outros_custos,
  observacoes
) on table public.custos_envios to authenticated;

create or replace view public.custos_envios_calculados
with (security_invoker = true)
as
select
  c.*,
  round(c.pv_venda * c.comissao_vendedor_percentagem / 100, 2) as valor_comissao,
  round(c.custo_mao_obra + c.custo_deslocacao + c.outros_custos_operacionais, 2) as total_custos_operacionais,
  round(
    c.preco_compra
    + c.custo_transporte
    + c.custo_mao_obra
    + c.custo_deslocacao
    + c.outros_custos_operacionais
    + (c.pv_venda * c.comissao_vendedor_percentagem / 100)
    + c.outros_custos,
    2
  ) as custo_total,
  round(
    c.pv_venda - (
      c.preco_compra
      + c.custo_transporte
      + c.custo_mao_obra
      + c.custo_deslocacao
      + c.outros_custos_operacionais
      + (c.pv_venda * c.comissao_vendedor_percentagem / 100)
      + c.outros_custos
    ),
    2
  ) as margem_valor,
  round(c.custo_transporte / nullif(c.pv_venda, 0) * 100, 4) as transporte_percentagem,
  round(c.custo_mao_obra / nullif(c.pv_venda, 0) * 100, 4) as mao_obra_percentagem,
  round(c.custo_deslocacao / nullif(c.pv_venda, 0) * 100, 4) as deslocacao_percentagem,
  c.comissao_vendedor_percentagem as comissao_percentagem,
  round(
    (c.outros_custos_operacionais + c.outros_custos)
    / nullif(c.pv_venda, 0) * 100,
    4
  ) as outros_custos_percentagem,
  round(
    (
      c.pv_venda - (
        c.preco_compra
        + c.custo_transporte
        + c.custo_mao_obra
        + c.custo_deslocacao
        + c.outros_custos_operacionais
        + (c.pv_venda * c.comissao_vendedor_percentagem / 100)
        + c.outros_custos
      )
    ) / nullif(c.pv_venda, 0) * 100,
    4
  ) as margem_percentagem
from public.custos_envios c;

revoke all on table public.custos_envios_calculados from anon;
grant select on table public.custos_envios_calculados to authenticated;

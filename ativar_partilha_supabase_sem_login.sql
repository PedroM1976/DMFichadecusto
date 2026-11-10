-- Execute este ficheiro no SQL Editor do Supabase.
-- Ativa a partilha da folha de custos entre computadores sem login.

alter table public.custos_envios enable row level security;
alter table public.custos_envios alter column created_by drop not null;
alter table public.custos_envios
  add column if not exists outros_custos_detalhe jsonb not null default '[]'::jsonb;

drop policy if exists "Utilizadores autenticados podem consultar custos" on public.custos_envios;
drop policy if exists "Utilizadores autenticados podem criar custos" on public.custos_envios;
drop policy if exists "Utilizadores autenticados podem atualizar custos" on public.custos_envios;
drop policy if exists "Utilizadores autenticados podem eliminar custos" on public.custos_envios;
drop policy if exists "Acesso partilhado pode consultar custos" on public.custos_envios;
drop policy if exists "Acesso partilhado pode criar custos" on public.custos_envios;
drop policy if exists "Acesso partilhado pode atualizar custos" on public.custos_envios;
drop policy if exists "Acesso partilhado pode eliminar custos" on public.custos_envios;

create policy "Acesso partilhado pode consultar custos"
on public.custos_envios for select
to anon, authenticated
using (true);

create policy "Acesso partilhado pode criar custos"
on public.custos_envios for insert
to anon, authenticated
with check (true);

create policy "Acesso partilhado pode atualizar custos"
on public.custos_envios for update
to anon, authenticated
using (true)
with check (true);

create policy "Acesso partilhado pode eliminar custos"
on public.custos_envios for delete
to anon, authenticated
using (true);

grant select, insert, delete on table public.custos_envios to anon, authenticated;

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
  outros_custos_detalhe,
  observacoes
) on table public.custos_envios to anon, authenticated;

grant select on table public.custos_envios_calculados to anon, authenticated;

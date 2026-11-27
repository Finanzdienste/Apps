-- Meine Apps (Workout v274): Wird jede App genutzt? Eine Übersicht über alle.
--
-- Tobi, 25.11.2026: „Können wir mir nicht mal ne masterübersicht aus allen
-- meinen Apps bauen damit ich seh ob die genutzt werden?“
--
-- Die Seite (https://finanzdienste.github.io/Apps/, Repo Finanzdienste/Apps) holt alles
-- mit einem Aufruf: apps_uebersicht(passwort). Gelesen wird nur, was die Apps
-- ohnehin schon melden (README „Meine Apps“): Bildschirmzeit aus Tobis Widget,
-- Rückkanal von Workout und Schilddrüse, Lebenszeichen von Mahlzeit, „zuletzt
-- in der App“ und Haken aus Freizeit, die Kosten von „Frag mal“. Keine Werte,
-- keine Einträge, keine Kennungen – Geräte heißen „Gerät 1a2b“.
--
-- Drei Quellen kennen nur den letzten Tag, keinen Verlauf (nutzung,
-- sd_geraete, freizeit_person/freizeit_bock). Für sie merkt sich apps_tag ab
-- jetzt jeden Tag, an dem jemand die App benutzt hat – über einen Trigger, der
-- nie die Meldung der App selbst stören darf. Rückwirkend steht dort, was die
-- Tabellen noch hergeben.
--
-- Einspielen: Supabase → SQL Editor → am Stück ausführen. Wiederholbar: legt
-- nichts doppelt an und löscht keine Zeilen. Voraussetzung ist admin_liste(text)
-- aus der Einrichtung der Workout-App – dasselbe Passwort, es steht auch hier
-- nicht –, und die Tabellen der anderen Apps, darunter mahlzeit_name aus
-- mahlzeit/supabase/geraet.sql im Repo Workout.

create table if not exists apps_tag (
  app text not null,
  wer text not null,
  tag date not null,
  primary key (app, wer, tag)
);
comment on table apps_tag is 'Meine Apps (Workout-Repo, tools/apps-uebersicht.sql): an welchem Tag wer welche App benutzt hat – für Quellen ohne eigenen Verlauf (Workout-Rückkanal, Schilddrüse, Freizeit).';
alter table apps_tag enable row level security;
revoke all on table apps_tag from anon, authenticated;

-- Wer: nie die Kennung selbst. Mit der Kennung eines Geräts ließe sich dessen
-- Zeile löschen oder überschreiben; die Übersicht braucht nur etwas Stabiles.
--
-- Wem ein Mahlzeit-Gerät gehört (Uwe), steht seit Mahlzeit v19 (27.11.2026) nur
-- in der Datenbank: Tabelle mahlzeit_name, angelegt in
-- mahlzeit/supabase/geraet.sql im Repo Workout. Bis dahin stand die Kennung
-- von Uwes Handy hier fest im Code – in einem öffentlichen Repo, und mit ihr
-- ließ sich überschreiben, was bei Tobi ankommt. Hier steht deshalb keine
-- Kennung eines echten Handys (tests/test-apps.mjs prüft das). Weil die
-- Funktion nachschlägt, ist sie stable statt immutable.
create or replace function apps_wer(app text, kennung text, name text default null)
returns text
language sql stable set search_path = public, pg_temp as $$
  select case
    when app = 'workout' then coalesce(nullif(btrim(name), ''), 'Gerät ' || left(kennung, 4))
    when app = 'schilddruese' then 'Gerät ' || left(kennung, 4)
    when app = 'mahlzeit' then coalesce((select m.name from mahlzeit_name m where m.geraet = kennung), 'Gerät ' || left(kennung, 4))
    else left(md5(kennung), 12)
  end
$$;

create or replace function apps_tag_merken()
returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  heute date := (now() at time zone 'Europe/Berlin')::date;
  a text;
  w text;
  tage date[] := array[heute];
begin
  begin
    if tg_table_name = 'nutzung' then
      a := 'workout';
      w := apps_wer('workout', new.id, new.name);
      -- Der Tag des letzten Trainings ist auch ein Tag in der App.
      if new.zuletzt is not null then tage := tage || new.zuletzt; end if;
    elsif tg_table_name = 'sd_geraete' then
      a := 'schilddruese';
      w := apps_wer('schilddruese', new.id);
    elsif tg_table_name = 'freizeit_person' then
      a := 'freizeit';
      w := apps_wer('freizeit', new.raum || '/' || new.person);
      if tg_op = 'UPDATE' then
        -- Nur „zuletzt in der App“ zählt, nicht ein geänderter Name.
        if new.zuletzt_offen is not distinct from old.zuletzt_offen then return null; end if;
        tage := array[(new.zuletzt_offen at time zone 'Europe/Berlin')::date];
      end if;
    elsif tg_table_name = 'freizeit_bock' then
      a := 'freizeit';
      w := apps_wer('freizeit', new.raum || '/' || new.person);
    end if;
    if a is not null and w is not null then
      insert into apps_tag (app, wer, tag)
      select a, w, t from unnest(tage) t
      where t between date '2026-01-01' and heute + 1
      on conflict do nothing;
    end if;
  exception when others then
    -- Die Übersicht darf nie die Meldung der App selbst kaputt machen.
    null;
  end;
  return null;
end $$;
revoke all on function apps_tag_merken() from public, anon, authenticated;

drop trigger if exists apps_tag on nutzung;
create trigger apps_tag after insert or update on nutzung
  for each row execute function apps_tag_merken();
drop trigger if exists apps_tag on sd_geraete;
create trigger apps_tag after insert or update on sd_geraete
  for each row execute function apps_tag_merken();
drop trigger if exists apps_tag on freizeit_person;
create trigger apps_tag after insert or update on freizeit_person
  for each row execute function apps_tag_merken();
drop trigger if exists apps_tag on freizeit_bock;
create trigger apps_tag after insert or update on freizeit_bock
  for each row execute function apps_tag_merken();
comment on trigger apps_tag on freizeit_person is 'Meine Apps (Workout-Repo, tools/apps-uebersicht.sql): merkt den Tag in apps_tag. Fängt jeden eigenen Fehler ab.';
comment on trigger apps_tag on freizeit_bock is 'Meine Apps (Workout-Repo, tools/apps-uebersicht.sql): merkt den Tag in apps_tag. Fängt jeden eigenen Fehler ab.';

-- Rückwirkend, was die Tabellen noch hergeben.
insert into apps_tag (app, wer, tag)
select 'workout', apps_wer('workout', id, name), (gesehen at time zone 'Europe/Berlin')::date
  from nutzung where gesehen >= date '2026-09-01'
union select 'workout', apps_wer('workout', id, name), zuletzt
  from nutzung where zuletzt >= date '2026-09-01' and gesehen >= date '2026-09-01'
union select 'schilddruese', apps_wer('schilddruese', id), zuletzt from sd_geraete where zuletzt is not null
union select 'schilddruese', apps_wer('schilddruese', id), erstmals from sd_geraete where erstmals is not null
union select 'freizeit', apps_wer('freizeit', raum || '/' || person), (zuletzt_offen at time zone 'Europe/Berlin')::date
  from freizeit_person where zuletzt_offen is not null
union select 'freizeit', apps_wer('freizeit', raum || '/' || person), (angelegt at time zone 'Europe/Berlin')::date
  from freizeit_person
union select 'freizeit', apps_wer('freizeit', raum || '/' || person), (geaendert at time zone 'Europe/Berlin')::date
  from freizeit_bock where geaendert is not null
on conflict do nothing;

-- Die Übersicht. Ein Aufruf, alles der letzten 60 Tage.
create or replace function apps_uebersicht(pass text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  heute date := (now() at time zone 'Europe/Berlin')::date;
  ab date := heute - 59;
begin
  -- Dasselbe Passwort wie die Übersicht der Workout-App: falsch heißt eine
  -- Sekunde warten und Abbruch („nope“).
  perform 1 from admin_liste(pass) limit 1;

  return jsonb_build_object(
    'stand', now(),
    'heute', heute,
    'bildschirmzeit', coalesce((
      select jsonb_agg(jsonb_build_object('app', app, 'tag', tag, 'sekunden', s) order by app, tag)
      from (select app, tag, sum(sekunden)::int s from bildschirmzeit
            where tag >= ab group by app, tag) x), '[]'::jsonb),
    'widget', (select max(gelesen) from bildschirmzeit_geraet),
    'tage', coalesce((
      select jsonb_agg(jsonb_build_object('app', app, 'wer', wer, 'tag', tag) order by app, wer, tag)
      from apps_tag where tag >= ab), '[]'::jsonb),
    'workout', coalesce((
      select jsonb_agg(jsonb_build_object('wer', w, 'geraete', g, 'gesehen', s, 'trainiert', z, 'einheiten', e) order by s desc)
      from (select apps_wer('workout', id, name) w, count(*) g, max(gesehen) s, max(zuletzt) z, max(einheiten) e
            from nutzung where gesehen >= now() - interval '180 days' group by 1) x), '[]'::jsonb),
    'schilddruese', coalesce((
      select jsonb_agg(jsonb_build_object('wer', apps_wer('schilddruese', id), 'erstmals', erstmals,
               'zuletzt', zuletzt, 'tage', tage, 'startbildschirm', startbildschirm) order by zuletzt desc)
      from sd_geraete), '[]'::jsonb),
    'mahlzeit', coalesce((
      select jsonb_agg(jsonb_build_object('wer', w, 'tag', tag, 'essen', essen, 'hafer', hafer, 'sport', sport,
               'werte', werte, 'als_app', als_app, 'at', at) order by w, tag)
      from (select apps_wer('mahlzeit', geraet) w, tag, max(essen) essen, max(hafer) hafer, max(sport) sport,
                   max(werte) werte, bool_or(als_app) als_app, max(at) at
            from mahlzeit_nutzung where tag >= ab and geraet <> 'testclaude01' group by 1, 2) x), '[]'::jsonb),
    'mahlzeit_ki', coalesce((
      select jsonb_agg(jsonb_build_object('tag', t, 'n', n) order by t)
      from (select (at at time zone 'Europe/Berlin')::date t, count(*) n from mahlzeit_ki
            where at >= ab group by 1) x), '[]'::jsonb),
    'freizeit', coalesce((
      select jsonb_agg(jsonb_build_object('wer', apps_wer('freizeit', p.raum || '/' || p.person), 'name', p.name,
               'angelegt', p.angelegt, 'offen', p.zuletzt_offen,
               'bock', (select max(b.geaendert) from freizeit_bock b where b.raum = p.raum and b.person = p.person))
             order by p.angelegt)
      from freizeit_person p), '[]'::jsonb),
    'fragmal_konten', coalesce((
      select jsonb_agg(jsonb_build_object('nr', nr, 'angelegt', angelegt, 'zuletzt', zuletzt) order by nr)
      from (select row_number() over (order by u.created_at) nr, u.created_at angelegt,
                   greatest(u.last_sign_in_at,
                            (select max(greatest(s.refreshed_at, s.updated_at)) from auth.sessions s where s.user_id = u.id)) zuletzt
            from auth.users u) x), '[]'::jsonb),
    'fragmal', coalesce((
      select jsonb_agg(jsonb_build_object('app', app, 'konto', nr, 'tag', t, 'n', n) order by app, t)
      from (select k.app, (k.zeit at time zone 'Europe/Berlin')::date t, kn.nr, count(*) n
            from fragmal_kosten k
            left join (select id, row_number() over (order by created_at) nr from auth.users) kn on kn.id = k.nutzer
            where k.zeit >= ab group by 1, 2, 3) x), '[]'::jsonb),
    -- Seit a7: wer in Boxenstopp an welchem Tag etwas geändert hat (boxenstopp_aktiv, unten)
    'boxenstopp', coalesce((
      select jsonb_agg(jsonb_build_object('wer', wer, 'liste', liste, 'tag', tag, 'anzahl', anzahl, 'zuletzt', zuletzt) order by wer, tag)
      from boxenstopp_aktiv where tag >= ab), '[]'::jsonb),
    'boxenstopp_stand', (select max(at) from boxenstopp_aktiv)
  );
end $$;

revoke all on function apps_wer(text, text, text) from public, anon, authenticated;
revoke all on function apps_uebersicht(text) from public, anon, authenticated;
grant execute on function apps_uebersicht(text) to anon;

-- Meine Apps a4 (26.11.2026): Uwes Werte aus Mahlzeit, tiefer als nur „benutzt“.
-- Tobi: „Dachte wir haben bei Uwe jetzt eingestellt dass wir seine Sachen
-- tiefgehend sehen können“ – Uwe ist einverstanden (Mahlzeit v10/v13, README
-- dort). Je Gerät die Werte der letzten 60 Tage (Gewicht, Blutzucker, HbA1c,
-- Schlaf, Schritte; mahlzeit_werte) und was die Uhr direkt geschickt hat
-- (mahlzeit_uhr). Seit Mahlzeit v14 (Meine Apps a5) auch, was er isst
-- (mahlzeit_essen, mahlzeit/supabase/essen.sql) – erst nach seinem „Ja“ in der
-- App. Dasselbe Passwort wie die anderen Übersichten.
create or replace function mahlzeit_lesen(pass text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  ab date := (now() at time zone 'Europe/Berlin')::date - 59;
begin
  perform 1 from admin_liste(pass) limit 1;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'wer', apps_wer('mahlzeit', g.geraet),
             'werte', coalesce((
               select jsonb_agg(jsonb_build_object('tag', w.tag, 'art', w.art, 'wert', w.wert, 'uhr', w.uhr,
                                                   'wann', w.wann, 'quelle', w.quelle) order by w.tag, w.uhr nulls first)
               from mahlzeit_werte w where w.geraet = g.geraet and w.tag >= ab), '[]'::jsonb),
             'uhr', coalesce((
               select jsonb_agg(jsonb_build_object('tag', u.tag, 'art', u.art, 'wert', u.wert) order by u.tag)
               from mahlzeit_uhr u where u.geraet = g.geraet and u.tag >= ab), '[]'::jsonb),
             'essen', coalesce((
               select jsonb_agg(jsonb_build_object('tag', e.tag, 'zeit', e.zeit, 'name', e.name, 'portion', e.portion,
                                                   'menge', e.menge, 'kcal', e.kcal, 'kh', e.kh, 'ei', e.ei, 'hafer', e.hafer)
                                order by e.tag, e.at, e.id)
               from mahlzeit_essen e where e.geraet = g.geraet and e.tag >= ab), '[]'::jsonb))
           order by exists (select 1 from mahlzeit_name m where m.geraet = g.geraet) desc, g.geraet)
    from (select geraet from mahlzeit_werte union select geraet from mahlzeit_uhr union select geraet from mahlzeit_essen) g
    where g.geraet <> 'testclaude01'), '[]'::jsonb);
end $$;
revoke all on function mahlzeit_lesen(text) from public, anon, authenticated;
grant execute on function mahlzeit_lesen(text) to anon;

-- Meine Apps a7 (26.11.2026): Boxenstopp meldet auch Amy und Marielle.
-- Tobi: „Boxenstopp soll natürlich auch marielle und Amy melden“. Boxenstopp
-- weiß es schon: Im Dashboard auf Tobis Handy steht aus den Commits der
-- Listen, wer wann was ändert – das wurde Amy und Marielle in der App gesagt
-- („Tobi hat jetzt ein Dashboard … wann du was änderst“). Tobis Boxenstopp
-- (js/aktiv-melden.js im Repo Boxenstopp) schickt davon nur die Zahl der
-- Änderungen je Person und Tag, höchstens stündlich. Ersetzt wird je Liste
-- ab p_von – so kommen Korrekturen an, und ein Gerät, das eine Gast-Liste
-- nicht kennt, löscht deren Tage nicht.
create table if not exists boxenstopp_aktiv (
  wer text not null,
  liste text not null,
  tag date not null,
  anzahl integer not null,
  zuletzt timestamptz,
  at timestamptz not null default now(),
  primary key (wer, liste, tag)
);
comment on table boxenstopp_aktiv is 'Meine Apps a7: wer in Boxenstopp an welchem Tag wie viel geändert hat (aus dem Dashboard auf Tobis Handy). Lesen nur über apps_uebersicht(pass).';
alter table boxenstopp_aktiv enable row level security;
revoke all on table boxenstopp_aktiv from anon, authenticated;

create or replace function boxenstopp_aktiv_melden(p_von date, p_listen jsonb, p_tage jsonb)
returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  n integer;
begin
  if p_von is null or p_von < current_date - 70 or p_von > current_date + 1 then raise exception 'von'; end if;
  if jsonb_typeof(p_listen) <> 'array' or jsonb_array_length(p_listen) > 30 then raise exception 'listen'; end if;
  if jsonb_typeof(p_tage) <> 'array' or jsonb_array_length(p_tage) > 3000 then raise exception 'tage'; end if;
  delete from boxenstopp_aktiv
   where tag >= p_von and liste in (select left(x, 60) from jsonb_array_elements_text(p_listen) x);
  insert into boxenstopp_aktiv (wer, liste, tag, anzahl, zuletzt)
  select left(btrim(t->>'wer'), 40), left(t->>'liste', 60), (t->>'tag')::date,
         least(greatest(coalesce((t->>'anzahl')::int, 0), 0), 100000),
         case when (t->>'zuletzt') ~ '^\d{4}-\d{2}-\d{2}T' then (t->>'zuletzt')::timestamptz end
  from jsonb_array_elements(p_tage) t
  where coalesce(btrim(t->>'wer'), '') <> '' and coalesce(t->>'liste', '') <> ''
    and case when (t->>'tag') ~ '^\d{4}-\d{2}-\d{2}$' then (t->>'tag')::date >= p_von else false end
    and (t->>'liste') in (select x from jsonb_array_elements_text(p_listen) x)
  on conflict (wer, liste, tag) do update set anzahl = excluded.anzahl, zuletzt = excluded.zuletzt, at = now();
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function boxenstopp_aktiv_melden(date, jsonb, jsonb) from public, anon, authenticated;
grant execute on function boxenstopp_aktiv_melden(date, jsonb, jsonb) to anon;

drop extension if exists "pg_net";

create type "public"."categoria_activo_enum" as enum ('PC', 'COMUNICACION', 'SOFTWARE', 'GENERICO');

create sequence "public"."area_de_activo_id_seq";

create sequence "public"."ciudad_de_activo_id_seq";

create sequence "public"."condicion_de_activo_id_seq";

create sequence "public"."custodio_id_seq";

create sequence "public"."marca_id_seq";

create sequence "public"."proveedor_id_seq";

create sequence "public"."rol_id_seq";

create sequence "public"."sede_de_activo_id_seq";

create sequence "public"."tipo_de_activo_id_seq";


  create table "public"."activo" (
    "id" uuid not null default gen_random_uuid(),
    "numero_serie" character varying,
    "id_custodio" integer,
    "id_condicion_activo" integer,
    "id_tipo_activo" integer not null,
    "id_ciudad_activo" integer,
    "id_sede_activo" integer,
    "id_area_activo" integer,
    "ip" character varying,
    "nombre" character varying,
    "codigo" text,
    "fecha_adquisicion" date,
    "fecha_entrega" date,
    "coordenada" character varying,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_creation" uuid,
    "user_on_update" uuid,
    "id_provedor" integer,
    "categoria_activo" character varying not null
      );


alter table "public"."activo" enable row level security;


  create table "public"."area_activo" (
    "id" integer not null default nextval('public.area_de_activo_id_seq'::regclass),
    "area" character varying(45) not null,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."area_activo" enable row level security;


  create table "public"."ciudad_activo" (
    "id" integer not null default nextval('public.ciudad_de_activo_id_seq'::regclass),
    "ciudad" character varying(45) not null,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."ciudad_activo" enable row level security;


  create table "public"."condicion_activo" (
    "id" integer not null default nextval('public.condicion_de_activo_id_seq'::regclass),
    "condicion" character varying(45) not null,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."condicion_activo" enable row level security;


  create table "public"."custodio" (
    "id" integer not null default nextval('public.custodio_id_seq'::regclass),
    "username" character varying(100),
    "email" character varying(100),
    "nombre_completo" character varying(100),
    "fecha_sincronizacion" timestamp without time zone
      );


alter table "public"."custodio" enable row level security;


  create table "public"."historial_activo" (
    "id" uuid not null default gen_random_uuid(),
    "id_activo" uuid,
    "tipo_operacion" character varying,
    "timestamp_changed_at" timestamp without time zone default now(),
    "user_on_change" uuid,
    "snapshot_json" jsonb
      );


alter table "public"."historial_activo" enable row level security;


  create table "public"."info_equipo_comunicacion" (
    "id" integer generated always as identity not null,
    "id_marca" integer,
    "id_activo" uuid not null,
    "modelo" character varying,
    "num_puertos" integer,
    "tipo_extension" character varying,
    "observaciones" character varying
      );


alter table "public"."info_equipo_comunicacion" enable row level security;


  create table "public"."info_equipo_generico" (
    "id" integer generated always as identity not null,
    "id_marca" integer,
    "id_activo" uuid not null,
    "modelo" character varying,
    "cargador_codigo" character varying,
    "num_conexiones" integer,
    "var_impresora_color" character varying,
    "var_monitor_tipo_conexion" character varying,
    "observaciones" character varying
      );


alter table "public"."info_equipo_generico" enable row level security;


  create table "public"."info_pc" (
    "id" integer generated always as identity not null,
    "id_marca" integer,
    "id_activo" uuid not null,
    "modelo" character varying,
    "procesador" character varying,
    "almacenamiento" character varying,
    "ram" character varying,
    "cargador_codigo" character varying,
    "num_puertos" integer,
    "observaciones" character varying
      );


alter table "public"."info_pc" enable row level security;


  create table "public"."info_software" (
    "id" integer generated always as identity not null,
    "id_activo" uuid not null,
    "proveedor" character varying,
    "fecha_inicio" date,
    "fecha_fin" date,
    "observaciones" character varying
      );


alter table "public"."info_software" enable row level security;


  create table "public"."mantenimiento" (
    "id" uuid not null default gen_random_uuid(),
    "id_activo" uuid not null,
    "fecha_programada" date,
    "fecha_realizada" date,
    "tipo" character varying,
    "estado" character varying,
    "observacion" character varying,
    "timestamp_created_at" timestamp without time zone default now(),
    "timestamp_updated_at" timestamp without time zone default now(),
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."mantenimiento" enable row level security;


  create table "public"."marca" (
    "id" integer not null default nextval('public.marca_id_seq'::regclass),
    "marca_proveedor" character varying(45) not null,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."marca" enable row level security;


  create table "public"."proveedor" (
    "id" integer not null default nextval('public.proveedor_id_seq'::regclass),
    "nombre" character varying(45),
    "descripcion" character varying(45),
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_creation" uuid,
    "user_on_update" uuid
      );


alter table "public"."proveedor" enable row level security;


  create table "public"."rol" (
    "id" integer not null default nextval('public.rol_id_seq'::regclass),
    "nombre" character varying(50) not null,
    "descripcion" character varying(100)
      );


alter table "public"."rol" enable row level security;


  create table "public"."sede_activo" (
    "id" integer not null default nextval('public.sede_de_activo_id_seq'::regclass),
    "sede" character varying(45) not null,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid
      );


alter table "public"."sede_activo" enable row level security;


  create table "public"."tipo_activo" (
    "id" integer not null default nextval('public.tipo_de_activo_id_seq'::regclass),
    "tipo" character varying(45) not null,
    "descripcion" text,
    "timestamp_created_at" timestamp without time zone,
    "timestamp_updated_at" timestamp without time zone,
    "user_on_update" uuid,
    "user_on_creation" uuid,
    "categoria" public.categoria_activo_enum default 'GENERICO'::public.categoria_activo_enum
      );


alter table "public"."tipo_activo" enable row level security;


  create table "public"."usuario_rol" (
    "user_id" uuid not null,
    "rol_id" integer not null
      );


alter table "public"."usuario_rol" enable row level security;

alter sequence "public"."area_de_activo_id_seq" owned by "public"."area_activo"."id";

alter sequence "public"."ciudad_de_activo_id_seq" owned by "public"."ciudad_activo"."id";

alter sequence "public"."condicion_de_activo_id_seq" owned by "public"."condicion_activo"."id";

alter sequence "public"."custodio_id_seq" owned by "public"."custodio"."id";

alter sequence "public"."marca_id_seq" owned by "public"."marca"."id";

alter sequence "public"."proveedor_id_seq" owned by "public"."proveedor"."id";

alter sequence "public"."rol_id_seq" owned by "public"."rol"."id";

alter sequence "public"."sede_de_activo_id_seq" owned by "public"."sede_activo"."id";

alter sequence "public"."tipo_de_activo_id_seq" owned by "public"."tipo_activo"."id";

CREATE UNIQUE INDEX activo_numero_serie_key ON public.activo USING btree (numero_serie);

CREATE UNIQUE INDEX activo_pkey ON public.activo USING btree (id);

CREATE UNIQUE INDEX area_de_activo_pkey ON public.area_activo USING btree (id);

CREATE UNIQUE INDEX ciudad_de_activo_pkey ON public.ciudad_activo USING btree (id);

CREATE UNIQUE INDEX condicion_de_activo_pkey ON public.condicion_activo USING btree (id);

CREATE UNIQUE INDEX custodio_pkey ON public.custodio USING btree (id);

CREATE UNIQUE INDEX historial_activo_pkey ON public.historial_activo USING btree (id);

CREATE INDEX idx_info_eq_com_id_activo ON public.info_equipo_comunicacion USING btree (id_activo);

CREATE INDEX idx_info_eq_gen_id_activo ON public.info_equipo_generico USING btree (id_activo);

CREATE INDEX idx_info_pc_id_activo ON public.info_pc USING btree (id_activo);

CREATE INDEX idx_info_sw_id_activo ON public.info_software USING btree (id_activo);

CREATE UNIQUE INDEX info_equipo_comunicacion_pkey ON public.info_equipo_comunicacion USING btree (id);

CREATE UNIQUE INDEX info_equipo_generico_pkey ON public.info_equipo_generico USING btree (id);

CREATE UNIQUE INDEX info_pc_pkey ON public.info_pc USING btree (id);

CREATE UNIQUE INDEX info_software_pkey ON public.info_software USING btree (id);

CREATE UNIQUE INDEX mantenimiento_pkey ON public.mantenimiento USING btree (id);

CREATE UNIQUE INDEX marca_pkey ON public.marca USING btree (id);

CREATE UNIQUE INDEX proveedor_pkey ON public.proveedor USING btree (id);

CREATE UNIQUE INDEX rol_nombre_key ON public.rol USING btree (nombre);

CREATE UNIQUE INDEX rol_pkey ON public.rol USING btree (id);

CREATE UNIQUE INDEX sede_de_activo_pkey ON public.sede_activo USING btree (id);

CREATE UNIQUE INDEX tipo_de_activo_pkey ON public.tipo_activo USING btree (id);

CREATE UNIQUE INDEX usuario_rol_pkey ON public.usuario_rol USING btree (user_id, rol_id);

alter table "public"."activo" add constraint "activo_pkey" PRIMARY KEY using index "activo_pkey";

alter table "public"."area_activo" add constraint "area_de_activo_pkey" PRIMARY KEY using index "area_de_activo_pkey";

alter table "public"."ciudad_activo" add constraint "ciudad_de_activo_pkey" PRIMARY KEY using index "ciudad_de_activo_pkey";

alter table "public"."condicion_activo" add constraint "condicion_de_activo_pkey" PRIMARY KEY using index "condicion_de_activo_pkey";

alter table "public"."custodio" add constraint "custodio_pkey" PRIMARY KEY using index "custodio_pkey";

alter table "public"."historial_activo" add constraint "historial_activo_pkey" PRIMARY KEY using index "historial_activo_pkey";

alter table "public"."info_equipo_comunicacion" add constraint "info_equipo_comunicacion_pkey" PRIMARY KEY using index "info_equipo_comunicacion_pkey";

alter table "public"."info_equipo_generico" add constraint "info_equipo_generico_pkey" PRIMARY KEY using index "info_equipo_generico_pkey";

alter table "public"."info_pc" add constraint "info_pc_pkey" PRIMARY KEY using index "info_pc_pkey";

alter table "public"."info_software" add constraint "info_software_pkey" PRIMARY KEY using index "info_software_pkey";

alter table "public"."mantenimiento" add constraint "mantenimiento_pkey" PRIMARY KEY using index "mantenimiento_pkey";

alter table "public"."marca" add constraint "marca_pkey" PRIMARY KEY using index "marca_pkey";

alter table "public"."proveedor" add constraint "proveedor_pkey" PRIMARY KEY using index "proveedor_pkey";

alter table "public"."rol" add constraint "rol_pkey" PRIMARY KEY using index "rol_pkey";

alter table "public"."sede_activo" add constraint "sede_de_activo_pkey" PRIMARY KEY using index "sede_de_activo_pkey";

alter table "public"."tipo_activo" add constraint "tipo_de_activo_pkey" PRIMARY KEY using index "tipo_de_activo_pkey";

alter table "public"."usuario_rol" add constraint "usuario_rol_pkey" PRIMARY KEY using index "usuario_rol_pkey";

alter table "public"."activo" add constraint "activo_id_area_fkey" FOREIGN KEY (id_area_activo) REFERENCES public.area_activo(id) not valid;

alter table "public"."activo" validate constraint "activo_id_area_fkey";

alter table "public"."activo" add constraint "activo_id_ciudad_fkey" FOREIGN KEY (id_ciudad_activo) REFERENCES public.ciudad_activo(id) not valid;

alter table "public"."activo" validate constraint "activo_id_ciudad_fkey";

alter table "public"."activo" add constraint "activo_id_condicion_fkey" FOREIGN KEY (id_condicion_activo) REFERENCES public.condicion_activo(id) not valid;

alter table "public"."activo" validate constraint "activo_id_condicion_fkey";

alter table "public"."activo" add constraint "activo_id_custodio_fkey" FOREIGN KEY (id_custodio) REFERENCES public.custodio(id) not valid;

alter table "public"."activo" validate constraint "activo_id_custodio_fkey";

alter table "public"."activo" add constraint "activo_id_provedor_fkey" FOREIGN KEY (id_provedor) REFERENCES public.proveedor(id) not valid;

alter table "public"."activo" validate constraint "activo_id_provedor_fkey";

alter table "public"."activo" add constraint "activo_id_sede_fkey" FOREIGN KEY (id_sede_activo) REFERENCES public.sede_activo(id) not valid;

alter table "public"."activo" validate constraint "activo_id_sede_fkey";

alter table "public"."activo" add constraint "activo_id_tipo_fkey" FOREIGN KEY (id_tipo_activo) REFERENCES public.tipo_activo(id) not valid;

alter table "public"."activo" validate constraint "activo_id_tipo_fkey";

alter table "public"."activo" add constraint "activo_numero_serie_key" UNIQUE using index "activo_numero_serie_key";

alter table "public"."info_equipo_comunicacion" add constraint "info_comunicacion_id_activo_fkey" FOREIGN KEY (id_activo) REFERENCES public.activo(id) ON DELETE CASCADE not valid;

alter table "public"."info_equipo_comunicacion" validate constraint "info_comunicacion_id_activo_fkey";

alter table "public"."info_equipo_comunicacion" add constraint "info_comunicacion_id_marca_fkey" FOREIGN KEY (id_marca) REFERENCES public.marca(id) not valid;

alter table "public"."info_equipo_comunicacion" validate constraint "info_comunicacion_id_marca_fkey";

alter table "public"."info_equipo_generico" add constraint "info_generico_id_activo_fkey" FOREIGN KEY (id_activo) REFERENCES public.activo(id) ON DELETE CASCADE not valid;

alter table "public"."info_equipo_generico" validate constraint "info_generico_id_activo_fkey";

alter table "public"."info_equipo_generico" add constraint "info_generico_id_marca_fkey" FOREIGN KEY (id_marca) REFERENCES public.marca(id) not valid;

alter table "public"."info_equipo_generico" validate constraint "info_generico_id_marca_fkey";

alter table "public"."info_pc" add constraint "info_pc_id_activo_fkey" FOREIGN KEY (id_activo) REFERENCES public.activo(id) ON DELETE CASCADE not valid;

alter table "public"."info_pc" validate constraint "info_pc_id_activo_fkey";

alter table "public"."info_pc" add constraint "info_pc_id_marca_fkey" FOREIGN KEY (id_marca) REFERENCES public.marca(id) not valid;

alter table "public"."info_pc" validate constraint "info_pc_id_marca_fkey";

alter table "public"."info_software" add constraint "info_software_id_activo_fkey" FOREIGN KEY (id_activo) REFERENCES public.activo(id) ON DELETE CASCADE not valid;

alter table "public"."info_software" validate constraint "info_software_id_activo_fkey";

alter table "public"."mantenimiento" add constraint "mantenimiento_id_activo_fkey" FOREIGN KEY (id_activo) REFERENCES public.activo(id) ON DELETE CASCADE not valid;

alter table "public"."mantenimiento" validate constraint "mantenimiento_id_activo_fkey";

alter table "public"."rol" add constraint "rol_nombre_key" UNIQUE using index "rol_nombre_key";

alter table "public"."usuario_rol" add constraint "usuario_rol_rol_id_fkey" FOREIGN KEY (rol_id) REFERENCES public.rol(id) ON DELETE CASCADE not valid;

alter table "public"."usuario_rol" validate constraint "usuario_rol_rol_id_fkey";

alter table "public"."usuario_rol" add constraint "usuario_rol_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."usuario_rol" validate constraint "usuario_rol_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.actualizar_activo_equipo_comunicacion(p_id_activo uuid, p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_ip text, p_fecha_entrega date, p_coordenada text, p_id_marca integer, p_modelo text, p_num_puertos integer, p_tipo_extension text, p_observaciones text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_categoria text;
BEGIN
    SELECT categoria_activo INTO v_categoria FROM activo WHERE id = p_id_activo;
    IF v_categoria IS NULL THEN RAISE EXCEPTION 'El activo no existe'; END IF;
    IF v_categoria <> 'COMUNICACION' THEN RAISE EXCEPTION 'El activo no es COMUNICACION'; END IF;
    UPDATE activo SET
        numero_serie = p_numero_serie, nombre = p_nombre, codigo = p_codigo,
        id_tipo_activo = p_id_tipo_activo, id_condicion_activo = p_id_condicion_activo,
        id_custodio = p_id_custodio, id_ciudad_activo = p_id_ciudad_activo, id_sede_activo = p_id_sede_activo,
        id_area_activo = p_id_area_activo, id_provedor = p_id_provedor, fecha_adquisicion = p_fecha_adquisicion,
        ip = p_ip, fecha_entrega = p_fecha_entrega, coordenada = p_coordenada
    WHERE id = p_id_activo;
    UPDATE info_equipo_comunicacion SET
        id_marca = p_id_marca, modelo = p_modelo, num_puertos = p_num_puertos,
        tipo_extension = p_tipo_extension, observaciones = p_observaciones
    WHERE id_activo = p_id_activo;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.actualizar_activo_equipo_generico(p_id_activo uuid, p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_fecha_entrega date, p_coordenada text, p_id_marca integer, p_modelo text, p_observaciones text, p_cargador_codigo text, p_num_conexiones integer, p_var_impresora_color text, p_var_monitor_tipo_conexion text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_categoria text;
BEGIN
    SELECT categoria_activo INTO v_categoria FROM activo WHERE id = p_id_activo;
    IF v_categoria IS NULL THEN RAISE EXCEPTION 'El activo no existe'; END IF;
    IF v_categoria <> 'GENERICO' THEN RAISE EXCEPTION 'El activo no es GENERICO'; END IF;
    UPDATE activo SET
        numero_serie = p_numero_serie, nombre = p_nombre, codigo = p_codigo,
        id_tipo_activo = p_id_tipo_activo, id_condicion_activo = p_id_condicion_activo,
        id_custodio = p_id_custodio, id_ciudad_activo = p_id_ciudad_activo, id_sede_activo = p_id_sede_activo,
        id_area_activo = p_id_area_activo, id_provedor = p_id_provedor,
        fecha_adquisicion = p_fecha_adquisicion, fecha_entrega = p_fecha_entrega, coordenada = p_coordenada
    WHERE id = p_id_activo;
    UPDATE info_equipo_generico SET
        id_marca = p_id_marca, modelo = p_modelo, observaciones = p_observaciones,
        cargador_codigo = p_cargador_codigo, num_conexiones = p_num_conexiones,
        var_impresora_color = p_var_impresora_color, var_monitor_tipo_conexion = p_var_monitor_tipo_conexion
    WHERE id_activo = p_id_activo;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.actualizar_activo_pc(p_id_activo uuid, p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_ip text, p_fecha_entrega date, p_coordenada text, p_procesador text, p_ram text, p_almacenamiento text, p_id_marca integer, p_modelo text, p_cargador_codigo text, p_num_puertos integer, p_observaciones text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_categoria text;
BEGIN
    SELECT categoria_activo INTO v_categoria FROM activo WHERE id = p_id_activo;
    IF v_categoria IS NULL THEN RAISE EXCEPTION 'El activo no existe'; END IF;
    IF v_categoria <> 'PC' THEN RAISE EXCEPTION 'El activo no es PC'; END IF;
    UPDATE activo SET
        numero_serie = p_numero_serie, nombre = p_nombre, codigo = p_codigo,
        id_tipo_activo = p_id_tipo_activo, id_condicion_activo = p_id_condicion_activo,
        id_custodio = p_id_custodio, id_ciudad_activo = p_id_ciudad_activo, id_sede_activo = p_id_sede_activo,
        id_area_activo = p_id_area_activo, id_provedor = p_id_provedor, fecha_adquisicion = p_fecha_adquisicion,
        ip = p_ip, fecha_entrega = p_fecha_entrega, coordenada = p_coordenada
    WHERE id = p_id_activo;
    UPDATE info_pc SET
        procesador = p_procesador, ram = p_ram, almacenamiento = p_almacenamiento,
        id_marca = p_id_marca, modelo = p_modelo, cargador_codigo = p_cargador_codigo,
        num_puertos = p_num_puertos, observaciones = p_observaciones
    WHERE id_activo = p_id_activo;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.actualizar_activo_software(p_id_activo uuid, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_area_activo integer, p_id_provedor integer, p_proveedor text, p_fecha_inicio date, p_fecha_fin date, p_observaciones text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_categoria text;
BEGIN
    SELECT categoria_activo INTO v_categoria FROM activo WHERE id = p_id_activo;
    IF v_categoria IS NULL THEN RAISE EXCEPTION 'El activo no existe'; END IF;
    IF v_categoria <> 'SOFTWARE' THEN RAISE EXCEPTION 'El activo no es SOFTWARE'; END IF;
    UPDATE activo SET
        nombre = p_nombre, codigo = p_codigo, id_tipo_activo = p_id_tipo_activo,
        id_condicion_activo = p_id_condicion_activo, id_custodio = p_id_custodio,
        id_area_activo = p_id_area_activo, id_provedor = p_id_provedor
    WHERE id = p_id_activo;
    UPDATE info_software SET
        proveedor = p_proveedor, fecha_inicio = p_fecha_inicio,
        fecha_fin = p_fecha_fin, observaciones = p_observaciones
    WHERE id_activo = p_id_activo;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.crear_activo_equipo_comunicacion(p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_ip text, p_fecha_entrega date, p_coordenada text, p_id_marca integer, p_modelo text, p_num_puertos integer, p_tipo_extension text, p_observaciones text, p_id_activo uuid DEFAULT gen_random_uuid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO activo (
        id, numero_serie, nombre, codigo, id_tipo_activo, id_condicion_activo,
        id_custodio, id_ciudad_activo, id_sede_activo, id_area_activo, id_provedor,
        categoria_activo, fecha_adquisicion, ip, fecha_entrega, coordenada
    ) VALUES (
        p_id_activo, p_numero_serie, p_nombre, p_codigo, p_id_tipo_activo, p_id_condicion_activo,
        p_id_custodio, p_id_ciudad_activo, p_id_sede_activo, p_id_area_activo, p_id_provedor,
        'COMUNICACION', p_fecha_adquisicion, p_ip, p_fecha_entrega, p_coordenada
    );
    INSERT INTO info_equipo_comunicacion (
        id_activo, id_marca, modelo, num_puertos, tipo_extension, observaciones
    ) VALUES (
        p_id_activo, p_id_marca, p_modelo, p_num_puertos, p_tipo_extension, p_observaciones
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.crear_activo_equipo_generico(p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_fecha_entrega date, p_coordenada text, p_id_marca integer, p_modelo text, p_cargador_codigo text, p_num_conexiones integer, p_var_impresora_color text, p_var_monitor_tipo_conexion text, p_observaciones text, p_id_activo uuid DEFAULT gen_random_uuid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO activo (
        id, numero_serie, nombre, codigo, id_tipo_activo, id_condicion_activo,
        id_custodio, id_ciudad_activo, id_sede_activo, id_area_activo, id_provedor,
        categoria_activo, fecha_adquisicion, fecha_entrega, coordenada
    ) VALUES (
        p_id_activo, p_numero_serie, p_nombre, p_codigo, p_id_tipo_activo, p_id_condicion_activo,
        p_id_custodio, p_id_ciudad_activo, p_id_sede_activo, p_id_area_activo, p_id_provedor,
        'GENERICO', p_fecha_adquisicion, p_fecha_entrega, p_coordenada
    );
    INSERT INTO info_equipo_generico (
        id_activo, id_marca, modelo, cargador_codigo, num_conexiones, var_impresora_color, var_monitor_tipo_conexion, observaciones
    ) VALUES (
        p_id_activo, p_id_marca, p_modelo, p_cargador_codigo, p_num_conexiones, p_var_impresora_color, p_var_monitor_tipo_conexion, p_observaciones
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.crear_activo_pc(p_numero_serie text, p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_ciudad_activo integer, p_id_sede_activo integer, p_id_area_activo integer, p_id_provedor integer, p_fecha_adquisicion date, p_ip text, p_fecha_entrega date, p_coordenada text, p_procesador text, p_ram text, p_almacenamiento text, p_id_marca integer, p_modelo text, p_cargador_codigo text, p_num_puertos integer, p_observaciones text, p_id_activo uuid DEFAULT gen_random_uuid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO activo (
        id, numero_serie, nombre, codigo, id_tipo_activo, id_condicion_activo,
        id_custodio, id_ciudad_activo, id_sede_activo, id_area_activo, id_provedor,
        categoria_activo, fecha_adquisicion, ip, fecha_entrega, coordenada
    ) VALUES (
        p_id_activo, p_numero_serie, p_nombre, p_codigo, p_id_tipo_activo, p_id_condicion_activo,
        p_id_custodio, p_id_ciudad_activo, p_id_sede_activo, p_id_area_activo, p_id_provedor,
        'PC', p_fecha_adquisicion, p_ip, p_fecha_entrega, p_coordenada
    );
    INSERT INTO info_pc (
        id_activo, procesador, ram, almacenamiento, id_marca, modelo, cargador_codigo, num_puertos, observaciones
    ) VALUES (
        p_id_activo, p_procesador, p_ram, p_almacenamiento, p_id_marca, p_modelo, p_cargador_codigo, p_num_puertos, p_observaciones
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.crear_activo_software(p_nombre text, p_codigo text, p_id_tipo_activo integer, p_id_condicion_activo integer, p_id_custodio integer, p_id_area_activo integer, p_id_provedor integer, p_proveedor text, p_fecha_inicio date, p_fecha_fin date, p_observaciones text, p_id_activo uuid DEFAULT gen_random_uuid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO activo (
        id, nombre, codigo, id_tipo_activo, id_condicion_activo,
        id_custodio, id_area_activo, id_provedor, categoria_activo
    ) VALUES (
        p_id_activo, p_nombre, p_codigo, p_id_tipo_activo, p_id_condicion_activo,
        p_id_custodio, p_id_area_activo, p_id_provedor, 'SOFTWARE'
    );
    INSERT INTO info_software (
        id_activo, proveedor, fecha_inicio, fecha_fin, observaciones
    ) VALUES (
        p_id_activo, p_proveedor, p_fecha_inicio, p_fecha_fin, p_observaciones
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.eliminar_activo(p_id_activo uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    DELETE FROM info_pc WHERE id_activo = p_id_activo;
    DELETE FROM info_equipo_comunicacion WHERE id_activo = p_id_activo;
    DELETE FROM info_equipo_generico WHERE id_activo = p_id_activo;
    DELETE FROM info_software WHERE id_activo = p_id_activo;
    DELETE FROM activo WHERE id = p_id_activo;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_historial_activo_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.historial_activo (id_activo, tipo_operacion, timestamp_changed_at, user_on_change, snapshot_json)
  VALUES (OLD.id, 'DELETE', now(), auth.uid(), to_jsonb(OLD));
  RETURN OLD;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_historial_activo_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin

  -- Insertar en historial_activo
  insert into public.historial_activo (
    id_activo,
    tipo_operacion,
    timestamp_changed_at,
    user_on_change,
    snapshot_json
  )
  values (
    new.id,
    'INSERT',
    now(),
    auth.uid(),
    to_jsonb(new)
  );

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_historial_activo_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin

  -- Registrar historial
  insert into public.historial_activo (
    id_activo,
    tipo_operacion,
    timestamp_changed_at,
    user_on_change,
    snapshot_json
  )
  values (
    new.id,
    'UPDATE',
    now(),
    auth.uid(),
    to_jsonb(new)
  );

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_insertar_timestamps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.timestamp_created_at := NOW();
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.timestamp_updated_at := NOW();
    END IF;
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.fn_usuario_auditar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.user_on_creation := auth.uid();
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.user_on_update := auth.uid();
    END IF;
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.fn_validar_categoria_activo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_categoria text;
    total integer;
BEGIN
    SELECT categoria_activo INTO v_categoria FROM public.activo WHERE id = NEW.id_activo;
    IF v_categoria IS NULL THEN RAISE EXCEPTION 'El activo no tiene categoria definida.'; END IF;
    IF (TG_TABLE_NAME = 'info_pc' AND v_categoria <> 'PC') OR
       (TG_TABLE_NAME = 'info_equipo_comunicacion' AND v_categoria <> 'COMUNICACION') OR
       (TG_TABLE_NAME = 'info_software' AND v_categoria <> 'SOFTWARE') OR
       (TG_TABLE_NAME = 'info_equipo_generico' AND v_categoria <> 'GENERICO') THEN
        RAISE EXCEPTION 'La categoria del activo no coincide con la tabla destino.';
    END IF;
    SELECT
        (SELECT count(*) FROM public.info_pc WHERE id_activo = NEW.id_activo) +
        (SELECT count(*) FROM public.info_equipo_comunicacion WHERE id_activo = NEW.id_activo) +
        (SELECT count(*) FROM public.info_software WHERE id_activo = NEW.id_activo) +
        (SELECT count(*) FROM public.info_equipo_generico WHERE id_activo = NEW.id_activo)
    INTO total;
    IF total > 1 THEN RAISE EXCEPTION 'Un activo solo puede pertenecer a UNA tabla hija.'; END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_activos_completos()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
  RETURN (
    SELECT COALESCE(jsonb_agg(
      row_to_json(a.*)::jsonb ||
      jsonb_build_object(
        -- Relaciones Foráneas Directas (Diccionarios / Objetos)
        'tipo_activo', (SELECT jsonb_build_object('tipo', ta.tipo) FROM tipo_activo ta WHERE ta.id = a.id_tipo_activo),
        'condicion_activo', (SELECT jsonb_build_object('condicion', ca.condicion) FROM condicion_activo ca WHERE ca.id = a.id_condicion_activo),
        'ciudad_activo', (SELECT jsonb_build_object('ciudad', cia.ciudad) FROM ciudad_activo cia WHERE cia.id = a.id_ciudad_activo),
        'sede_activo', (SELECT jsonb_build_object('sede', sa.sede) FROM sede_activo sa WHERE sa.id = a.id_sede_activo),
        'area_activo', (SELECT jsonb_build_object('area', aa.area) FROM area_activo aa WHERE aa.id = a.id_area_activo),
        'proveedor', (SELECT jsonb_build_object('nombre', p.nombre) FROM proveedor p WHERE p.id = a.id_provedor),
        'custodio', (SELECT jsonb_build_object('nombre_completo', c.nombre_completo) FROM custodio c WHERE c.id = a.id_custodio),
        
        -- Relaciones "Uno a Muchos" o Específicas (Arreglos / Listas de objetos)
        'info_pc', COALESCE((
          SELECT jsonb_agg(
            row_to_json(ipc.*)::jsonb || 
            jsonb_build_object('marca', (SELECT jsonb_build_object('marca_proveedor', m.marca_proveedor) FROM marca m WHERE m.id = ipc.id_marca))
          )
          FROM info_pc ipc WHERE ipc.id_activo = a.id
        ), '[]'::jsonb),

        'info_equipo_comunicacion', COALESCE((
          SELECT jsonb_agg(
            row_to_json(iec.*)::jsonb || 
            jsonb_build_object('marca', (SELECT jsonb_build_object('marca_proveedor', m.marca_proveedor) FROM marca m WHERE m.id = iec.id_marca))
          )
          FROM info_equipo_comunicacion iec WHERE iec.id_activo = a.id
        ), '[]'::jsonb),

        'info_equipo_generico', COALESCE((
          SELECT jsonb_agg(
            row_to_json(ieg.*)::jsonb || 
            jsonb_build_object('marca', (SELECT jsonb_build_object('marca_proveedor', m.marca_proveedor) FROM marca m WHERE m.id = ieg.id_marca))
          )
          FROM info_equipo_generico ieg WHERE ieg.id_activo = a.id
        ), '[]'::jsonb),

        'info_software', COALESCE((
          SELECT jsonb_agg(row_to_json(isw.*))
          FROM info_software isw WHERE isw.id_activo = a.id
        ), '[]'::jsonb)
      )
    ), '[]'::jsonb)
    FROM activo a
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user_default_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    prestamo_role_id integer;
begin
    -- Obtener el id del rol PRESTAMO
    select id
    into prestamo_role_id
    from public.rol
    where nombre = 'PRESTAMO'
    limit 1;

    -- Insertar el rol por defecto
    insert into public.usuario_rol (user_id, rol_id)
    values (new.id, prestamo_role_id);

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.usuario_rol ur
    join public.rol r on r.id = ur.rol_id
    where ur.user_id = auth.uid()
      and r.nombre = 'ADMIN'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_prestamo()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT EXISTS (
    SELECT 1
    FROM usuario_rol ur
    JOIN rol r ON r.id = ur.rol_id
    WHERE ur.user_id = auth.uid()
    AND r.nombre = 'PRESTAMO'
);
$function$
;

CREATE OR REPLACE FUNCTION public.is_ti()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT EXISTS (
    SELECT 1
    FROM usuario_rol ur
    JOIN rol r ON r.id = ur.rol_id
    WHERE ur.user_id = auth.uid()
    AND r.nombre = 'TI'
);
$function$
;

create or replace view "public"."vista_usuarios_admin" as  SELECT ur.user_id,
    ur.rol_id,
    r.nombre AS rol,
    (au.raw_user_meta_data ->> 'name'::text) AS nombre_usuario,
    au.email
   FROM ((public.usuario_rol ur
     JOIN public.rol r ON ((ur.rol_id = r.id)))
     JOIN auth.users au ON ((ur.user_id = au.id)));


grant delete on table "public"."activo" to "anon";

grant insert on table "public"."activo" to "anon";

grant references on table "public"."activo" to "anon";

grant select on table "public"."activo" to "anon";

grant trigger on table "public"."activo" to "anon";

grant truncate on table "public"."activo" to "anon";

grant update on table "public"."activo" to "anon";

grant delete on table "public"."activo" to "authenticated";

grant insert on table "public"."activo" to "authenticated";

grant references on table "public"."activo" to "authenticated";

grant select on table "public"."activo" to "authenticated";

grant trigger on table "public"."activo" to "authenticated";

grant truncate on table "public"."activo" to "authenticated";

grant update on table "public"."activo" to "authenticated";

grant delete on table "public"."activo" to "service_role";

grant insert on table "public"."activo" to "service_role";

grant references on table "public"."activo" to "service_role";

grant select on table "public"."activo" to "service_role";

grant trigger on table "public"."activo" to "service_role";

grant truncate on table "public"."activo" to "service_role";

grant update on table "public"."activo" to "service_role";

grant delete on table "public"."area_activo" to "anon";

grant insert on table "public"."area_activo" to "anon";

grant references on table "public"."area_activo" to "anon";

grant select on table "public"."area_activo" to "anon";

grant trigger on table "public"."area_activo" to "anon";

grant truncate on table "public"."area_activo" to "anon";

grant update on table "public"."area_activo" to "anon";

grant delete on table "public"."area_activo" to "authenticated";

grant insert on table "public"."area_activo" to "authenticated";

grant references on table "public"."area_activo" to "authenticated";

grant select on table "public"."area_activo" to "authenticated";

grant trigger on table "public"."area_activo" to "authenticated";

grant truncate on table "public"."area_activo" to "authenticated";

grant update on table "public"."area_activo" to "authenticated";

grant delete on table "public"."area_activo" to "service_role";

grant insert on table "public"."area_activo" to "service_role";

grant references on table "public"."area_activo" to "service_role";

grant select on table "public"."area_activo" to "service_role";

grant trigger on table "public"."area_activo" to "service_role";

grant truncate on table "public"."area_activo" to "service_role";

grant update on table "public"."area_activo" to "service_role";

grant delete on table "public"."ciudad_activo" to "anon";

grant insert on table "public"."ciudad_activo" to "anon";

grant references on table "public"."ciudad_activo" to "anon";

grant select on table "public"."ciudad_activo" to "anon";

grant trigger on table "public"."ciudad_activo" to "anon";

grant truncate on table "public"."ciudad_activo" to "anon";

grant update on table "public"."ciudad_activo" to "anon";

grant delete on table "public"."ciudad_activo" to "authenticated";

grant insert on table "public"."ciudad_activo" to "authenticated";

grant references on table "public"."ciudad_activo" to "authenticated";

grant select on table "public"."ciudad_activo" to "authenticated";

grant trigger on table "public"."ciudad_activo" to "authenticated";

grant truncate on table "public"."ciudad_activo" to "authenticated";

grant update on table "public"."ciudad_activo" to "authenticated";

grant delete on table "public"."ciudad_activo" to "service_role";

grant insert on table "public"."ciudad_activo" to "service_role";

grant references on table "public"."ciudad_activo" to "service_role";

grant select on table "public"."ciudad_activo" to "service_role";

grant trigger on table "public"."ciudad_activo" to "service_role";

grant truncate on table "public"."ciudad_activo" to "service_role";

grant update on table "public"."ciudad_activo" to "service_role";

grant delete on table "public"."condicion_activo" to "anon";

grant insert on table "public"."condicion_activo" to "anon";

grant references on table "public"."condicion_activo" to "anon";

grant select on table "public"."condicion_activo" to "anon";

grant trigger on table "public"."condicion_activo" to "anon";

grant truncate on table "public"."condicion_activo" to "anon";

grant update on table "public"."condicion_activo" to "anon";

grant delete on table "public"."condicion_activo" to "authenticated";

grant insert on table "public"."condicion_activo" to "authenticated";

grant references on table "public"."condicion_activo" to "authenticated";

grant select on table "public"."condicion_activo" to "authenticated";

grant trigger on table "public"."condicion_activo" to "authenticated";

grant truncate on table "public"."condicion_activo" to "authenticated";

grant update on table "public"."condicion_activo" to "authenticated";

grant delete on table "public"."condicion_activo" to "service_role";

grant insert on table "public"."condicion_activo" to "service_role";

grant references on table "public"."condicion_activo" to "service_role";

grant select on table "public"."condicion_activo" to "service_role";

grant trigger on table "public"."condicion_activo" to "service_role";

grant truncate on table "public"."condicion_activo" to "service_role";

grant update on table "public"."condicion_activo" to "service_role";

grant delete on table "public"."custodio" to "anon";

grant insert on table "public"."custodio" to "anon";

grant references on table "public"."custodio" to "anon";

grant select on table "public"."custodio" to "anon";

grant trigger on table "public"."custodio" to "anon";

grant truncate on table "public"."custodio" to "anon";

grant update on table "public"."custodio" to "anon";

grant delete on table "public"."custodio" to "authenticated";

grant insert on table "public"."custodio" to "authenticated";

grant references on table "public"."custodio" to "authenticated";

grant select on table "public"."custodio" to "authenticated";

grant trigger on table "public"."custodio" to "authenticated";

grant truncate on table "public"."custodio" to "authenticated";

grant update on table "public"."custodio" to "authenticated";

grant delete on table "public"."custodio" to "service_role";

grant insert on table "public"."custodio" to "service_role";

grant references on table "public"."custodio" to "service_role";

grant select on table "public"."custodio" to "service_role";

grant trigger on table "public"."custodio" to "service_role";

grant truncate on table "public"."custodio" to "service_role";

grant update on table "public"."custodio" to "service_role";

grant delete on table "public"."historial_activo" to "anon";

grant insert on table "public"."historial_activo" to "anon";

grant references on table "public"."historial_activo" to "anon";

grant select on table "public"."historial_activo" to "anon";

grant trigger on table "public"."historial_activo" to "anon";

grant truncate on table "public"."historial_activo" to "anon";

grant update on table "public"."historial_activo" to "anon";

grant delete on table "public"."historial_activo" to "authenticated";

grant insert on table "public"."historial_activo" to "authenticated";

grant references on table "public"."historial_activo" to "authenticated";

grant select on table "public"."historial_activo" to "authenticated";

grant trigger on table "public"."historial_activo" to "authenticated";

grant truncate on table "public"."historial_activo" to "authenticated";

grant update on table "public"."historial_activo" to "authenticated";

grant delete on table "public"."historial_activo" to "service_role";

grant insert on table "public"."historial_activo" to "service_role";

grant references on table "public"."historial_activo" to "service_role";

grant select on table "public"."historial_activo" to "service_role";

grant trigger on table "public"."historial_activo" to "service_role";

grant truncate on table "public"."historial_activo" to "service_role";

grant update on table "public"."historial_activo" to "service_role";

grant delete on table "public"."info_equipo_comunicacion" to "anon";

grant insert on table "public"."info_equipo_comunicacion" to "anon";

grant references on table "public"."info_equipo_comunicacion" to "anon";

grant select on table "public"."info_equipo_comunicacion" to "anon";

grant trigger on table "public"."info_equipo_comunicacion" to "anon";

grant truncate on table "public"."info_equipo_comunicacion" to "anon";

grant update on table "public"."info_equipo_comunicacion" to "anon";

grant delete on table "public"."info_equipo_comunicacion" to "authenticated";

grant insert on table "public"."info_equipo_comunicacion" to "authenticated";

grant references on table "public"."info_equipo_comunicacion" to "authenticated";

grant select on table "public"."info_equipo_comunicacion" to "authenticated";

grant trigger on table "public"."info_equipo_comunicacion" to "authenticated";

grant truncate on table "public"."info_equipo_comunicacion" to "authenticated";

grant update on table "public"."info_equipo_comunicacion" to "authenticated";

grant delete on table "public"."info_equipo_comunicacion" to "service_role";

grant insert on table "public"."info_equipo_comunicacion" to "service_role";

grant references on table "public"."info_equipo_comunicacion" to "service_role";

grant select on table "public"."info_equipo_comunicacion" to "service_role";

grant trigger on table "public"."info_equipo_comunicacion" to "service_role";

grant truncate on table "public"."info_equipo_comunicacion" to "service_role";

grant update on table "public"."info_equipo_comunicacion" to "service_role";

grant delete on table "public"."info_equipo_generico" to "anon";

grant insert on table "public"."info_equipo_generico" to "anon";

grant references on table "public"."info_equipo_generico" to "anon";

grant select on table "public"."info_equipo_generico" to "anon";

grant trigger on table "public"."info_equipo_generico" to "anon";

grant truncate on table "public"."info_equipo_generico" to "anon";

grant update on table "public"."info_equipo_generico" to "anon";

grant delete on table "public"."info_equipo_generico" to "authenticated";

grant insert on table "public"."info_equipo_generico" to "authenticated";

grant references on table "public"."info_equipo_generico" to "authenticated";

grant select on table "public"."info_equipo_generico" to "authenticated";

grant trigger on table "public"."info_equipo_generico" to "authenticated";

grant truncate on table "public"."info_equipo_generico" to "authenticated";

grant update on table "public"."info_equipo_generico" to "authenticated";

grant delete on table "public"."info_equipo_generico" to "service_role";

grant insert on table "public"."info_equipo_generico" to "service_role";

grant references on table "public"."info_equipo_generico" to "service_role";

grant select on table "public"."info_equipo_generico" to "service_role";

grant trigger on table "public"."info_equipo_generico" to "service_role";

grant truncate on table "public"."info_equipo_generico" to "service_role";

grant update on table "public"."info_equipo_generico" to "service_role";

grant delete on table "public"."info_pc" to "anon";

grant insert on table "public"."info_pc" to "anon";

grant references on table "public"."info_pc" to "anon";

grant select on table "public"."info_pc" to "anon";

grant trigger on table "public"."info_pc" to "anon";

grant truncate on table "public"."info_pc" to "anon";

grant update on table "public"."info_pc" to "anon";

grant delete on table "public"."info_pc" to "authenticated";

grant insert on table "public"."info_pc" to "authenticated";

grant references on table "public"."info_pc" to "authenticated";

grant select on table "public"."info_pc" to "authenticated";

grant trigger on table "public"."info_pc" to "authenticated";

grant truncate on table "public"."info_pc" to "authenticated";

grant update on table "public"."info_pc" to "authenticated";

grant delete on table "public"."info_pc" to "service_role";

grant insert on table "public"."info_pc" to "service_role";

grant references on table "public"."info_pc" to "service_role";

grant select on table "public"."info_pc" to "service_role";

grant trigger on table "public"."info_pc" to "service_role";

grant truncate on table "public"."info_pc" to "service_role";

grant update on table "public"."info_pc" to "service_role";

grant delete on table "public"."info_software" to "anon";

grant insert on table "public"."info_software" to "anon";

grant references on table "public"."info_software" to "anon";

grant select on table "public"."info_software" to "anon";

grant trigger on table "public"."info_software" to "anon";

grant truncate on table "public"."info_software" to "anon";

grant update on table "public"."info_software" to "anon";

grant delete on table "public"."info_software" to "authenticated";

grant insert on table "public"."info_software" to "authenticated";

grant references on table "public"."info_software" to "authenticated";

grant select on table "public"."info_software" to "authenticated";

grant trigger on table "public"."info_software" to "authenticated";

grant truncate on table "public"."info_software" to "authenticated";

grant update on table "public"."info_software" to "authenticated";

grant delete on table "public"."info_software" to "service_role";

grant insert on table "public"."info_software" to "service_role";

grant references on table "public"."info_software" to "service_role";

grant select on table "public"."info_software" to "service_role";

grant trigger on table "public"."info_software" to "service_role";

grant truncate on table "public"."info_software" to "service_role";

grant update on table "public"."info_software" to "service_role";

grant delete on table "public"."mantenimiento" to "anon";

grant insert on table "public"."mantenimiento" to "anon";

grant references on table "public"."mantenimiento" to "anon";

grant select on table "public"."mantenimiento" to "anon";

grant trigger on table "public"."mantenimiento" to "anon";

grant truncate on table "public"."mantenimiento" to "anon";

grant update on table "public"."mantenimiento" to "anon";

grant delete on table "public"."mantenimiento" to "authenticated";

grant insert on table "public"."mantenimiento" to "authenticated";

grant references on table "public"."mantenimiento" to "authenticated";

grant select on table "public"."mantenimiento" to "authenticated";

grant trigger on table "public"."mantenimiento" to "authenticated";

grant truncate on table "public"."mantenimiento" to "authenticated";

grant update on table "public"."mantenimiento" to "authenticated";

grant delete on table "public"."mantenimiento" to "service_role";

grant insert on table "public"."mantenimiento" to "service_role";

grant references on table "public"."mantenimiento" to "service_role";

grant select on table "public"."mantenimiento" to "service_role";

grant trigger on table "public"."mantenimiento" to "service_role";

grant truncate on table "public"."mantenimiento" to "service_role";

grant update on table "public"."mantenimiento" to "service_role";

grant delete on table "public"."marca" to "anon";

grant insert on table "public"."marca" to "anon";

grant references on table "public"."marca" to "anon";

grant select on table "public"."marca" to "anon";

grant trigger on table "public"."marca" to "anon";

grant truncate on table "public"."marca" to "anon";

grant update on table "public"."marca" to "anon";

grant delete on table "public"."marca" to "authenticated";

grant insert on table "public"."marca" to "authenticated";

grant references on table "public"."marca" to "authenticated";

grant select on table "public"."marca" to "authenticated";

grant trigger on table "public"."marca" to "authenticated";

grant truncate on table "public"."marca" to "authenticated";

grant update on table "public"."marca" to "authenticated";

grant delete on table "public"."marca" to "service_role";

grant insert on table "public"."marca" to "service_role";

grant references on table "public"."marca" to "service_role";

grant select on table "public"."marca" to "service_role";

grant trigger on table "public"."marca" to "service_role";

grant truncate on table "public"."marca" to "service_role";

grant update on table "public"."marca" to "service_role";

grant delete on table "public"."proveedor" to "anon";

grant insert on table "public"."proveedor" to "anon";

grant references on table "public"."proveedor" to "anon";

grant select on table "public"."proveedor" to "anon";

grant trigger on table "public"."proveedor" to "anon";

grant truncate on table "public"."proveedor" to "anon";

grant update on table "public"."proveedor" to "anon";

grant delete on table "public"."proveedor" to "authenticated";

grant insert on table "public"."proveedor" to "authenticated";

grant references on table "public"."proveedor" to "authenticated";

grant select on table "public"."proveedor" to "authenticated";

grant trigger on table "public"."proveedor" to "authenticated";

grant truncate on table "public"."proveedor" to "authenticated";

grant update on table "public"."proveedor" to "authenticated";

grant delete on table "public"."proveedor" to "service_role";

grant insert on table "public"."proveedor" to "service_role";

grant references on table "public"."proveedor" to "service_role";

grant select on table "public"."proveedor" to "service_role";

grant trigger on table "public"."proveedor" to "service_role";

grant truncate on table "public"."proveedor" to "service_role";

grant update on table "public"."proveedor" to "service_role";

grant delete on table "public"."rol" to "anon";

grant insert on table "public"."rol" to "anon";

grant references on table "public"."rol" to "anon";

grant select on table "public"."rol" to "anon";

grant trigger on table "public"."rol" to "anon";

grant truncate on table "public"."rol" to "anon";

grant update on table "public"."rol" to "anon";

grant delete on table "public"."rol" to "authenticated";

grant insert on table "public"."rol" to "authenticated";

grant references on table "public"."rol" to "authenticated";

grant select on table "public"."rol" to "authenticated";

grant trigger on table "public"."rol" to "authenticated";

grant truncate on table "public"."rol" to "authenticated";

grant update on table "public"."rol" to "authenticated";

grant delete on table "public"."rol" to "service_role";

grant insert on table "public"."rol" to "service_role";

grant references on table "public"."rol" to "service_role";

grant select on table "public"."rol" to "service_role";

grant trigger on table "public"."rol" to "service_role";

grant truncate on table "public"."rol" to "service_role";

grant update on table "public"."rol" to "service_role";

grant delete on table "public"."sede_activo" to "anon";

grant insert on table "public"."sede_activo" to "anon";

grant references on table "public"."sede_activo" to "anon";

grant select on table "public"."sede_activo" to "anon";

grant trigger on table "public"."sede_activo" to "anon";

grant truncate on table "public"."sede_activo" to "anon";

grant update on table "public"."sede_activo" to "anon";

grant delete on table "public"."sede_activo" to "authenticated";

grant insert on table "public"."sede_activo" to "authenticated";

grant references on table "public"."sede_activo" to "authenticated";

grant select on table "public"."sede_activo" to "authenticated";

grant trigger on table "public"."sede_activo" to "authenticated";

grant truncate on table "public"."sede_activo" to "authenticated";

grant update on table "public"."sede_activo" to "authenticated";

grant delete on table "public"."sede_activo" to "service_role";

grant insert on table "public"."sede_activo" to "service_role";

grant references on table "public"."sede_activo" to "service_role";

grant select on table "public"."sede_activo" to "service_role";

grant trigger on table "public"."sede_activo" to "service_role";

grant truncate on table "public"."sede_activo" to "service_role";

grant update on table "public"."sede_activo" to "service_role";

grant delete on table "public"."tipo_activo" to "anon";

grant insert on table "public"."tipo_activo" to "anon";

grant references on table "public"."tipo_activo" to "anon";

grant select on table "public"."tipo_activo" to "anon";

grant trigger on table "public"."tipo_activo" to "anon";

grant truncate on table "public"."tipo_activo" to "anon";

grant update on table "public"."tipo_activo" to "anon";

grant delete on table "public"."tipo_activo" to "authenticated";

grant insert on table "public"."tipo_activo" to "authenticated";

grant references on table "public"."tipo_activo" to "authenticated";

grant select on table "public"."tipo_activo" to "authenticated";

grant trigger on table "public"."tipo_activo" to "authenticated";

grant truncate on table "public"."tipo_activo" to "authenticated";

grant update on table "public"."tipo_activo" to "authenticated";

grant delete on table "public"."tipo_activo" to "service_role";

grant insert on table "public"."tipo_activo" to "service_role";

grant references on table "public"."tipo_activo" to "service_role";

grant select on table "public"."tipo_activo" to "service_role";

grant trigger on table "public"."tipo_activo" to "service_role";

grant truncate on table "public"."tipo_activo" to "service_role";

grant update on table "public"."tipo_activo" to "service_role";

grant delete on table "public"."usuario_rol" to "anon";

grant insert on table "public"."usuario_rol" to "anon";

grant references on table "public"."usuario_rol" to "anon";

grant select on table "public"."usuario_rol" to "anon";

grant trigger on table "public"."usuario_rol" to "anon";

grant truncate on table "public"."usuario_rol" to "anon";

grant update on table "public"."usuario_rol" to "anon";

grant delete on table "public"."usuario_rol" to "authenticated";

grant insert on table "public"."usuario_rol" to "authenticated";

grant references on table "public"."usuario_rol" to "authenticated";

grant select on table "public"."usuario_rol" to "authenticated";

grant trigger on table "public"."usuario_rol" to "authenticated";

grant truncate on table "public"."usuario_rol" to "authenticated";

grant update on table "public"."usuario_rol" to "authenticated";

grant delete on table "public"."usuario_rol" to "service_role";

grant insert on table "public"."usuario_rol" to "service_role";

grant references on table "public"."usuario_rol" to "service_role";

grant select on table "public"."usuario_rol" to "service_role";

grant trigger on table "public"."usuario_rol" to "service_role";

grant truncate on table "public"."usuario_rol" to "service_role";

grant update on table "public"."usuario_rol" to "service_role";


  create policy "all_select_activo"
  on "public"."activo"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_update_activo"
  on "public"."activo"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()))
with check ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_area"
  on "public"."area_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_area"
  on "public"."area_activo"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_ciudad"
  on "public"."ciudad_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_ciudad"
  on "public"."ciudad_activo"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_condicion"
  on "public"."condicion_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_condicion"
  on "public"."condicion_activo"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_custodio"
  on "public"."custodio"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_tipo_provedor"
  on "public"."custodio"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_historial"
  on "public"."historial_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "all_select_info_equipo_comunicacion"
  on "public"."info_equipo_comunicacion"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_update_info_equipo_comunicacion"
  on "public"."info_equipo_comunicacion"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()))
with check ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_select_info_equipo_generico"
  on "public"."info_equipo_generico"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_update_info_equipo_generico"
  on "public"."info_equipo_generico"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()))
with check ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_select_info_pc"
  on "public"."info_pc"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_update_info_pc"
  on "public"."info_pc"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()))
with check ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_select_info_software"
  on "public"."info_software"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "all_update_info_software"
  on "public"."info_software"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_ti() OR public.is_prestamo()))
with check ((public.is_admin() OR public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_mantenimiento"
  on "public"."mantenimiento"
  as permissive
  for all
  to public
using ((public.is_admin() OR public.is_ti()))
with check ((public.is_admin() OR public.is_ti()));



  create policy "Policy with security definer functions"
  on "public"."marca"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_marca"
  on "public"."marca"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_proveedor"
  on "public"."proveedor"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_tipo_provedor"
  on "public"."proveedor"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "all_full_rol"
  on "public"."rol"
  as permissive
  for all
  to public
using ((auth.uid() IS NOT NULL))
with check ((auth.uid() IS NOT NULL));



  create policy "admin_full_sede"
  on "public"."sede_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_sede"
  on "public"."sede_activo"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "admin_full_tipo_activo"
  on "public"."tipo_activo"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "read_ti_prestamo_tipo_activo"
  on "public"."tipo_activo"
  as permissive
  for select
  to public
using ((public.is_ti() OR public.is_prestamo()));



  create policy "all_full_usuario_rol"
  on "public"."usuario_rol"
  as permissive
  for all
  to public
using ((auth.uid() IS NOT NULL))
with check ((auth.uid() IS NOT NULL));


CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_historial_activo_delete AFTER DELETE ON public.activo FOR EACH ROW EXECUTE FUNCTION public.fn_historial_activo_delete();

CREATE TRIGGER trg_historial_activo_insert AFTER INSERT ON public.activo FOR EACH ROW EXECUTE FUNCTION public.fn_historial_activo_insert();

CREATE TRIGGER trg_historial_activo_update BEFORE UPDATE ON public.activo FOR EACH ROW EXECUTE FUNCTION public.fn_historial_activo_update();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.area_activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.area_activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.ciudad_activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.ciudad_activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.condicion_activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.condicion_activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_validar_comunicacion BEFORE INSERT OR UPDATE ON public.info_equipo_comunicacion FOR EACH ROW EXECUTE FUNCTION public.fn_validar_categoria_activo();

CREATE TRIGGER trg_validar_generico BEFORE INSERT OR UPDATE ON public.info_equipo_generico FOR EACH ROW EXECUTE FUNCTION public.fn_validar_categoria_activo();

CREATE TRIGGER trg_validar_pc BEFORE INSERT OR UPDATE ON public.info_pc FOR EACH ROW EXECUTE FUNCTION public.fn_validar_categoria_activo();

CREATE TRIGGER trg_validar_software BEFORE INSERT OR UPDATE ON public.info_software FOR EACH ROW EXECUTE FUNCTION public.fn_validar_categoria_activo();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.marca FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.marca FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.proveedor FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.proveedor FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.sede_activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.sede_activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER trg_activo_timestamps BEFORE INSERT OR UPDATE ON public.tipo_activo FOR EACH ROW EXECUTE FUNCTION public.fn_insertar_timestamps();

CREATE TRIGGER trg_activo_user BEFORE INSERT OR UPDATE ON public.tipo_activo FOR EACH ROW EXECUTE FUNCTION public.fn_usuario_auditar();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_default_role();



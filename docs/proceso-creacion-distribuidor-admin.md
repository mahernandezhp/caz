# Proceso de Creacion de un Distribuidor Admin

Este documento describe el flujo completo para habilitar un nuevo distribuidor en el Portal de Distribuidores Cruz Azul, incluyendo la automatizacion implementada en Apex.

## Resumen del Flujo

```
1. Crear Account (Distribuidor)
2. Activar IsPartner en la Account
3. Crear Contact relacionado a la Account
4. Crear relacion Cuenta-Zona (CAZ_Cuenta_y_Zona__c)
5. Habilitar Contact como usuario Partner Community
   └─ Automatico: se asigna PSG "CAZ Portal Distribuidor Admin"
   └─ Automatico: se agrega al grupo publico de su zona
   └─ Automatico: obtiene acceso a las Plantas de su zona
```

## Paso a Paso

### 1. Crear la Cuenta Distribuidora

- Crear un registro de Account con los datos del distribuidor.
- Activar el campo `IsPartner = true` (debe hacerse despues de la insercion, no se puede establecer al crear).

### 2. Relacionar la Cuenta con su(s) Zona(s)

- Crear un registro de `CAZ_Cuenta_y_Zona__c` (junction object) vinculando:
  - `CAZ_Cuenta__c` → la Account del distribuidor
  - `CAZ_Zona__c` → la zona geografica correspondiente
- Una cuenta puede estar relacionada a multiples zonas.

### 3. Crear el Contacto

- Crear un Contact relacionado a la Account del distribuidor.
- Campos minimos: FirstName, LastName, Email, AccountId.

### 4. Habilitar como Usuario de la Comunidad

- Desde el registro del Contact, usar el boton **"Enable Partner User"** o crear el User via API.
- Asignar el perfil **"Portal Distribuidor - Partner Community User"** (Id: `00eWD000003PZLpYAO`).
- Este es el perfil que identifica a un distribuidor admin (a diferencia de los members que usan "Portal Distribuidor - Base - Login").

## Automatizaciones que se Disparan

### Al crear el User (CAZ_UserTrigger → after insert)

#### 1. Asignacion de Permission Set Group (`CAZ_UserPermissionSetHandler`)

- **Condicion**: el User tiene perfil "Portal Distribuidor - Partner Community User".
- **Accion**: asigna el PSG `CAZ_Portal_Distribuidor_Admin` via metodo `@future`.
- **Excluye**: usuarios con otros perfiles (ej. "Portal Distribuidor - Base - Login" para members creados desde el portal).

**Archivos**:
- `triggers/CAZ_UserTrigger.trigger`
- `classes/CAZ_UserPermissionSetHandler.cls`
- `classes/CAZ_UserPermissionSetHandlerTest.cls`

#### 2. Membresia en Grupo de Zona (`CAZ_ZonaSharingHandler`)

- **Condicion**: el User tiene un ContactId (es usuario portal).
- **Accion**: busca las zonas asociadas a la Account del Contact (via `CAZ_Cuenta_y_Zona__c`) y agrega al User como miembro del grupo publico de cada zona.
- Se ejecuta via metodo `@future` para evitar errores de MIXED_DML_OPERATION.

**Archivos**:
- `classes/CAZ_ZonaSharingHandler.cls`
- `classes/CAZ_ZonaSharingHandlerTest.cls`

### Al crear/modificar relacion Cuenta-Zona (CAZ_CuentaZonaTrigger → before insert, after insert/delete)

#### Validacion de duplicados (`CAZ_CuentaZonaValidationHandler`)

- **Evento**: `before insert`
- **Accion**: impide crear un registro `CAZ_Cuenta_y_Zona__c` si ya existe la misma combinacion Cuenta + Zona.
- Valida tanto contra registros existentes en la base de datos como contra duplicados dentro del mismo lote (bulk insert).
- Mensajes de error:
  - `"Esta Cuenta ya está relacionada con esta Zona."` — si ya existe en BD.
  - `"Ya existe otra relación en este lote para la misma Cuenta y Zona."` — si hay duplicado en el mismo batch.

**Archivos**:
- `classes/CAZ_CuentaZonaValidationHandler.cls`
- `classes/CAZ_CuentaZonaValidationHandlerTest.cls`

#### Reconciliacion de membresia de grupos

- **Evento**: `after insert`, `after delete`
- **Accion**: reconcilia las membresías de grupo de todos los usuarios portal activos de esa cuenta.
- Si se agrega una nueva zona → los usuarios se agregan al grupo de esa zona.
- Si se elimina una zona → los usuarios se remueven del grupo de esa zona.

**Archivos**:
- `triggers/CAZ_CuentaZonaTrigger.trigger`

### Al crear una nueva Zona (CAZ_ZonaTrigger → after insert)

- **Accion**: crea un Public Group con nombre `CAZ Zona {NombreZona}` y guarda su Id en `CAZ_Zona__c.CAZ_GrupoCompartidoId__c`.

**Archivos**:
- `triggers/CAZ_ZonaTrigger.trigger`
- `classes/CAZ_ZonaGroupHandler.cls`
- `classes/CAZ_ZonaGroupHandlerTest.cls`

### Al crear/modificar una Planta (CAZ_PlantaTrigger → after insert/update)

- **Condicion**: la Planta tiene una zona asignada (`CAZ_Zona__c`) y esta cambia o es nueva.
- **Accion**: crea un registro `CAZ_Planta__Share` con `AccessLevel = Read` hacia el grupo publico de la zona.
- Si cambia la zona, elimina el share anterior y crea uno nuevo.

**Archivos**:
- `triggers/CAZ_PlantaTrigger.trigger`
- `classes/CAZ_PlantaShareHandler.cls`
- `classes/CAZ_PlantaShareHandlerTest.cls`

## Modelo de Sharing de Plantas

```
CAZ_Zona__c ──────────────┐
  └─ CAZ_GrupoCompartidoId__c ──→ Group (Public Group "CAZ Zona X")
                                      │
CAZ_Planta__c                         │
  └─ CAZ_Zona__c ──→ CAZ_Planta__Share ──→ Group (Read)
                                      │
User (Portal)                         │
  └─ Contact.AccountId               │
       └─ CAZ_Cuenta_y_Zona__c ──→ GroupMember ──→ Group
```

**Resultado**: Un usuario distribuidor solo ve las Plantas cuya Zona coincide con la(s) zona(s) de su cuenta.

**Prerequisito**: El OWD (Org-Wide Default) de `CAZ_Planta__c` debe estar en **Private** para external users (`externalSharingModel = Private`).

## Nota sobre Members (usuarios no-admin)

Cuando un distribuidor admin crea un member desde el portal:
- El member obtiene el perfil **"Portal Distribuidor - Base - Login"** (licencia Partner Community Login).
- El trigger de User **no** le asigna el PSG `CAZ_Portal_Distribuidor_Admin` (solo aplica al perfil admin).
- El admin selecciona manualmente los Permission Sets desde la pantalla del portal.
- El member **si** recibe automaticamente la membresia en los grupos de zona (porque tiene ContactId y su Account tiene relaciones Cuenta-Zona).

## Script de Backfill

Para datos existentes (zonas, plantas y usuarios creados antes de estos triggers), se incluye el script:

```
scripts/apex/backfill_zona_sharing.apex
```

Ejecutar una sola vez con:
```bash
sf apex run -f scripts/apex/backfill_zona_sharing.apex -o capptus-caz-dev
```

Este script:
1. Crea grupos publicos para las 8 zonas existentes.
2. Comparte las plantas existentes con el grupo de su zona.
3. Reconcilia la membresia de grupo para los 19 usuarios portal existentes.

## Cambio en Account Trigger

Se removio la llamada a `createPartnerRolesAsync` del trigger `CAZ_AccountPartnerRoleTrigger`. Este metodo creaba 3 UserRoles custom (Ejecutivo/Gestor/Usuario) al activar `IsPartner`, pero Salesforce ya maneja la jerarquia de roles automaticamente al habilitar el primer usuario portal. El trigger ahora solo ejecuta la logica de cobranza (`CAZ_CobranzaAccountTriggerHandler.enqueueCobranzaCases`).

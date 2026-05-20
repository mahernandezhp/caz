# Portal de distribuidores - contexto de configuracion

Org usada: `capptus-caz-dev`

Sitio de prueba: `test`

URL base de comunidad: `https://customer-connect-47072--devcap.sandbox.my.site.com/testprm`

## Objetivo del POC

Permitir que un usuario distribuidor admin pueda entrar al portal, crear y administrar miembros relacionados a su cuenta distribuidora, y usar el flujo estandar de Partner Community para alta de usuarios.

## Configuracion aplicada

- Se habilito el sitio `test` como sitio de prueba del POC.
- Se uso el perfil `Portal Distribuidor - Partner Community User` para usuarios Partner Community.
- Se configuro Delegated Administration con el grupo `CAZ Portal Admins`.
- El grupo `CAZ Portal Admins` incluye usuarios administradores del portal que pueden administrar miembros delegados.
- En Delegated Administration se habilitaron perfiles externos delegables:
  - `Portal Distribuidor - Base - Login`
  - `Portal Distribuidor - Partner Community User`
  - `External Apps Login User`
- Se configuraron permission sets delegables:
  - `CAZ_Distribuidor`
  - `CAZ_Distribuidor_Admin`
- Se corrigio el permission set `CAZ_Distribuidor_Admin` para mantener solo permisos requeridos del portal y remover acceso a la clase custom eliminada.

## Perfil y dropdown de Add Member

El problema donde no aparecia el perfil al crear miembros se resolvio desde Setup Classic, activando/configurando la relacion del perfil en la seccion de perfiles externos delegables.

La causa fue configuracion de Delegated External User Profiles, no un bug del componente estandar.

## Roles de cuentas Partner

Se agrego automatizacion Apex para crear roles de cuenta Partner cuando una cuenta cambia a `IsPartner = true`.

Metadata relacionada:

- `CAZ_AccountPartnerRoleTrigger`
- `CAZ_AccountPartnerRoleHandler`
- `CAZ_AccountPartnerRoleHandlerTest`

La automatizacion crea los roles faltantes para que la cuenta Partner pueda operar con usuarios externos y roles jerarquicos esperados.

## Componente custom removido

El LWC `cazAddPortalMember` y su controller Apex fueron una solucion temporal mientras se diagnosticaba el dropdown de perfiles.

Al resolverse la configuracion estandar de Delegated Administration, el componente custom ya no es necesario.

Se eliminaron del proyecto:

- `force-app/main/default/lwc/cazAddPortalMember`
- `CAZ_PortalMemberController`
- `CAZ_PortalMemberControllerTest`

Tambien se removio el acceso Apex de `CAZ_Distribuidor_Admin`.

## Estado del sitio

La pagina `Account Management Custom` del ExperienceBundle `test1` ya no contiene el componente `c:cazAddPortalMember` en la version de Builder recuperada.

Archivo local de respaldo:

- `force-app/main/default/experiences/test1/views/accountManagementCustom.json`

Estado operativo:

- El sitio `test` fue publicado desde Experience Builder despues de remover el componente.
- `LightningComponentBundle:cazAddPortalMember` fue eliminado de la org.

## Manifest relacionado

El manifest de respaldo del POC esta en:

- `manifest/package-portal-distribuidores-poc.xml`

Incluye la metadata funcional relacionada al POC: Delegated Administration, grupo admin, Network `test`, permission sets, portal delegable permission sets, Communities settings y la automatizacion de roles Partner.

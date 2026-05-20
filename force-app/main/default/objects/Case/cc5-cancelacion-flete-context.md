Este es un resumen ejecutivo y técnico del proceso CC5 (Cancelación de Flete), diseñado como contexto para ser utilizado en una sesión de Gemini. Este material sintetiza la información operativa, técnica y de configuración necesaria para entender el flujo dentro del proyecto de transformación digital de Cruz Azul.

Contexto del Proceso CC5: Cancelación de Flete

1. Resumen Ejecutivo

El proceso CC5 tiene como objetivo garantizar la correcta anulación de fletes con errores o ajustes comerciales y la generación de nuevas órdenes de flete con la información fiscal y contable correcta, asegurando el cumplimiento normativo ante el SAT y la coherencia de datos entre Salesforce y JD Edwards.

El proceso involucra a cinco áreas principales: Crédito y Cobranza, Gerencia Comercial, Gerencia de Logística, Gerencia Fiscal y Gerencia de Ventas, quienes participan en la validación, autorización y ejecución de la cancelación.

2. Definición Operativa (Flujo de Estados)

El proceso se gestiona sobre el objeto Case con Record Type "CancelacionFlete" y un Business Process dedicado con 7 estados:

Status              Responsable             Acción Clave
Borrador            Distribuidor / CC       Creación de la solicitud de cancelación con Orden de Venta (Lookup a Order) y Factura KD en PDF.
En proceso 1        Gerencia Comercial      Evaluación inicial de procedencia. Si no procede, se rechaza.
En proceso 2        Gerencia Logística      Verificación con transportista del retiro. Envío de Memorándum Interno (MI) a Gerencia Fiscal.
En proceso 3        Gerencia Fiscal         Revisión del MI. Se solicita Vo.Bo. a Gerencia de Ventas.
En proceso 4        Gerencia de Ventas      Vo.Bo. otorgado. Se notifica a CC y al distribuidor para cancelación ante SAT.
Autorizado          Gerencia Fiscal         Se autoriza la cancelación del flete. El distribuidor debe aceptar en portal SAT.
Cerrado Exitoso     Gerencia Fiscal         Cancelación completada en ERP. Factura sustituida lista para cobranza.
Cerrado Rechazado   Ger. Comercial/Logíst.  Solicitud no procedió. Se notifica al distribuidor.

Transiciones válidas:
- Borrador → En proceso 1
- En proceso 1 → En proceso 2 | Cerrado Rechazado | Borrador (regreso)
- En proceso 2 → En proceso 3 | Cerrado Rechazado | En proceso 1 (regreso)
- En proceso 3 → En proceso 4
- En proceso 4 → Autorizado
- Autorizado → Cerrado Exitoso
- Cualquier estado → Cerrado Rechazado (con motivo)

3. Enfoque Arquitectónico

Se utiliza la arquitectura: Case + Trigger Handler + Objeto hijo CAZ_HistorialEtapa__c

Esta decisión se tomó tras evaluar 4 alternativas:
- Field History Tracking: Solo complemento (no registra duración ni rebotes).
- Entitlement + Milestones: Registra tiempos pero no identifica quién ejecutó cada paso.
- Approval Process: Registra quién y cuándo, pero es rígido para 7 estados con múltiples áreas y no soporta Slack.
- Objeto hijo + Trigger: Cubre las 3 dimensiones (quién, cuándo, duración), soporta rebotes, es flexible y se integra con Slack.

4. Configuración en Salesforce

Para soportar este proceso, se implementan los siguientes componentes técnicos:

    Objeto Case: Record Type "CancelacionFlete" con Business Process "Cancelacion Flete".

    Objeto hijo CAZ_HistorialEtapa__c: Registra cada transición de status con:
        - CAZ_Case__c: Master-Detail(Case) — Caso padre.
        - CAZ_Etapa__c: Text — Status al que entró.
        - CAZ_FechaEntrada__c: DateTime — Cuándo entró a esta etapa.
        - CAZ_FechaSalida__c: DateTime — Cuándo salió (se llena en la siguiente transición).
        - CAZ_Responsable__c: Lookup(User) — Quién ejecutó el cambio de status.
        - CAZ_DuracionHoras__c: Formula — (FechaSalida - FechaEntrada) * 24.
        - CAZ_Iteracion__c: Number — Número de vez que pasa por esta etapa (manejo de rebotes).
        - CAZ_Comentarios__c: Long Text Area — Notas del responsable.
        - CAZ_PropietarioCaso__c: Text — Queue o usuario asignado al caso en ese momento.

    Campo Orden de Venta: CAZ_OrdenVenta__c Lookup(Order) en Case — Relación directa con la Orden de Venta.

    Campos reutilizados de Case:
        - CAZ_RFC__c: Datos fiscales del distribuidor.
        - CAZ_ComprobanteReferencia__c: Acuse SAT.
        - CAZ_MotivoRechazo__c: Motivo de rechazo.
        - CAZ_NumeroProvisionJDE__c: Referencia JDE.
        - CAZ_Respuesta__c: Respuesta al distribuidor.

    Trigger: CAZ_CaseTrigger.trigger → CAZ_CaseTriggerHandler.cls
        - before insert: Auto-asigna AccountId del usuario de comunidad (distribuidor).
        - before update: Validaciones de documentos, restricción de transiciones, asignación de Owner a Queue por status, timestamps.
        - after insert: Crea primer registro de CAZ_HistorialEtapa__c.
        - after update: Cierra registro de historial anterior, crea nuevo registro, dispara notificaciones.

    Automatización de Notificaciones:
        Slack (integración nativa): Flow Record-Triggered con slackPostMessage usando Slack_Notifications__mdt.
            - Borrador → Gerente Comercial
            - En proceso 1 → Logística
            - En proceso 2 → Gerencia Fiscal
            - En proceso 3 → Gerencia de Ventas
            - En proceso 4 → Crédito y Cobranza
            - Autorizado → Gerente de Logística
            - Cerrado Exitoso → CC y Gerente Comercial

        Email: Plantillas para el distribuidor.
            - En proceso 4 → "Se ha generado la cancelación ante el SAT. Favor de aceptar y enviar acuse."
            - Cerrado Rechazado → "Su solicitud no procedió."

    Validación de Documentos: Usando CAZ_DocumentoSolicitud__mdt (patrón existente en Devolución).
        Se valida que los documentos obligatorios estén adjuntos (ContentDocumentLink) antes de permitir la transición Borrador → En proceso 1.

5. Permisos y Asignaciones

Estrategia: Profile único "Gerentes" + Public Groups + Queues por área.

    Profile: Un solo profile "Gerentes" para todos los usuarios internos. Controla acceso base a Case y campos.

    Queues (asignación de ownership por status):
        Queue                   API Name                Existe    Owner cuando status es
        Crédito y Cobranza      CreditoCobranza         Sí        (notificaciones, etapa final)
        Gerente Comercial       CAZ_GerenteComercial    Nuevo     En proceso 1
        Logística               CAZ_Logistica           Nuevo     En proceso 2
        Gerencia Fiscal         CAZ_GerenciaFiscal      Nuevo     En proceso 3, Autorizado
        Gerencia de Ventas      CAZ_GerenciaVentas      Nuevo     En proceso 4

    Grupos Slack (notificaciones):
        Grupo                           API Name                        Existe
        Crédito y Cobranza              CAZ_Slack_CreditoCobranza       Sí
        Gerente Comercial               CAZ_Slack_GerenteComercial      Nuevo
        Logística                       CAZ_Slack_Logistica             Nuevo
        Gerencia Fiscal                 CAZ_Slack_GerenciaFiscal        Nuevo
        Gerencia de Ventas              CAZ_Slack_GerenciaVentas        Nuevo

    Asignación automática en trigger handler:
        Status → En proceso 1: OwnerId = Queue CAZ_GerenteComercial
        Status → En proceso 2: OwnerId = Queue CAZ_Logistica
        Status → En proceso 3: OwnerId = Queue CAZ_GerenciaFiscal
        Status → En proceso 4: OwnerId = Queue CAZ_GerenciaVentas
        Status → Autorizado:   OwnerId = Queue CAZ_GerenciaFiscal
        Status → Borrador (regreso): OwnerId = CreatedById

6. Trazabilidad

El proceso garantiza trazabilidad completa mediante 3 capas:

    Capa 1 — Field History Tracking (nativo): Se activa tracking en el campo Status del Case. Registra quién, cuándo y de/a qué valor cambió. Retención de 18 meses.

    Capa 2 — Objeto hijo CAZ_HistorialEtapa__c (custom): Cada cambio de status crea un registro con: etapa, fecha entrada, fecha salida, responsable, duración e iteración. Soporta rebotes (si un caso va y viene entre etapas, cada paso genera un registro independiente).

    Capa 3 — Campos fórmula en Case (complemento): Campos que calculan el tiempo acumulado en cada área para dashboards y KPIs rápidos.

7. Integración con JD Edwards (ERP)

La anulación contable del flete en JDE se realiza de forma manual por ahora. Los campos de referencia en Salesforce permiten la trazabilidad:
    - CAZ_NumeroProvisionJDE__c: Número de provisión o referencia JDE.
    - CAZ_ComprobanteReferencia__c: Acuse de cancelación ante SAT.

Patrón de integración existente para futuro callout: CAZ_WS_IU_OrdenesDeVenta, CAZ_WS_IU_Cuentas (REST Web Services).

8. Aspectos Especiales

    Memorándum Interno (MI) Digital: Actualmente se genera en papel. Se digitaliza como ContentVersion adjunto al Case. Se envía por Slack con folio del caso. Requiere Vo.Bo. de Gerencia de Ventas antes de continuar.

    Facturas con Antigüedad mayor a 5 años: El SAT exige aprobación previa del cliente (distribuidor) para cancelar. Campo fórmula que calcula antigüedad desde la fecha de la Orden de Venta. El trigger bloquea el avance a "Autorizado" si la factura tiene más de 5 años y no se ha adjuntado el acuse de aceptación SAT del distribuidor.

    Refacturación: Después de la cancelación, se genera una nueva factura de reemplazo en JDE. Se trata como "modificación de precio" o corrección. Incluye nota aclaratoria y relación con documento sustituido. La nueva factura se timbra y se notifica al distribuidor.

9. Objetivos Funcionales y Cobertura

    Objetivo                            Componente que lo resuelve
    Cumplimiento fiscal                 Trigger (validaciones) + DocumentoSolicitud__mdt + campos fiscales
    Automatización y trazabilidad       CAZ_HistorialEtapa__c + Field History + queues automáticas
    Integridad contable                 Manual en JDE + campos de referencia en SF
    Gestión coordinada                  Flow + Slack_Notifications__mdt + 6 Grupos Slack
    Sincronización de sistemas          Manual JDE + campos de status para tracking
    Validación de documentos            Trigger: ContentDocumentLink vs DocumentoSolicitud__mdt
    Control de antigüedad               Fórmula antigüedad + trigger bloquea sin acuse SAT
    Notificación y evidencia            Slack + Email + ContentVersion + HistorialEtapa
    Reducción de errores                Trigger: transiciones restringidas + validaciones automáticas

10. Roles y Permisos

Los perfiles involucrados con acceso a este proceso son:

    Distribuidor (usuario de comunidad): Crea la solicitud desde el portal. Solo ve sus propios casos.
    Gerente Comercial: Evalúa procedencia inicial. Puede aprobar o rechazar.
    Gerente de Logística: Verifica retiro con transportista. Genera MI Digital.
    Gerente Fiscal: Genera cancelación ante SAT y en ERP. Autoriza la cancelación.
    Gerente de Ventas: Otorga Vo.Bo. sobre el MI.
    Crédito y Cobranza: Recibe notificaciones y gestiona la cobranza con la factura sustituida.
    Todos los gerentes comparten el profile "Gerentes" y se diferencian por membresía en Public Groups y Queues.

11. Infraestructura Reutilizable del Proyecto

    Componente                          Estado          Acción para CC5
    CAZ_CaseTrigger.trigger             Existe          Agregar before insert, after insert, after update
    CAZ_CaseTriggerHandler.cls          Existe (vacío)  Agregar lógica CC5
    Slack_Notifications__mdt            Existe          7 registros nuevos
    CAZ_DocumentoSolicitud__mdt         Existe          Registros para docs CC5
    Cola CreditoCobranza                Existe          Reutilizar
    cazMyCases LWC                      Existe          Integrar CC5 al listado
    Campos Case reutilizables           Existen         RFC, MotivoRechazo, ComprobanteRef, NumProvJDE, Respuesta

Este es un resumen ejecutivo y técnico del proceso CC3 (Cobranza general y negociación de deuda), diseñado como contexto para ser utilizado en una sesión de Gemini. Este material sintetiza la información operativa, técnica y de configuración necesaria para entender el flujo dentro del proyecto de transformación digital de Cruz Azul.
Contexto del Proceso CC3: Cobranza General y Negociación de Deuda
1. Resumen Ejecutivo
El proceso CC3 tiene como objetivo centralizar y automatizar la gestión de la cartera vencida de los distribuidores de Cruz Azul mediante Salesforce. Busca transformar el seguimiento manual en una operación proactiva que clasifica la deuda por antigüedad (Buckets) y define acciones específicas que van desde la gestión comercial hasta el cobro jurídico.1
2
3
2. Definición Operativa (Buckets de Antigüedad)
El proceso se activa cuando se detectan saldos vencidos, clasificando las cuentas en cuatro niveles de riesgo, cada uno con responsables y acciones diferenciadas:1
4
Bucket	Días de Atraso	Responsable Principal	Acción Clave
Verde	1 a 5 días	Ejecutivo de Cuenta	Notificación inicial de liquidación de deuda.
Amarillo	6 a 30 días	Jefe Administrativo / Comercial	Gestión de negociación de pago y contacto directo.
Naranja	31 a 90 días	Jefe Administrativo / Jurídico	Solicitud y emisión de Convenio de Pago.
Rojo	+91 días	Jurídico	Inicio de proceso con expediente legal para recuperación.
3. Configuración en Salesforce
Para soportar este proceso, se implementan los siguientes componentes técnicos en la plataforma:5

    Objeto Caso (Case): Se utiliza el Record Type "Cobranza y Negociación" para el seguimiento.5
    6
    Campos Personalizados: Habilitación de campos para buckets de antigüedad, estatus de negociación e historial de convenios.5
    Gestión de ANS (SLA): Configuración de Milestones y Entitlements para asegurar que las negociaciones no excedan los tiempos permitidos en cada bucket (por ejemplo, escalación automática de Amarillo a Naranja).5
    6
    Automatización de Notificaciones:
        Slack: Alertas a canales de Crédito, Cobranza y Jurídico según el nivel de riesgo.3
        5
        Email: Plantillas para el distribuidor sobre el inicio del proceso y condiciones de pago.4
        5

4. Integración con JD Edwards (ERP)
La efectividad del proceso CC3 depende de la sincronización de datos con el ERP:2
5

    Sincronización de Saldos: Consumo del servicio de saldos en tiempo real para actualizar el estado del caso en Salesforce.5
    Actualización de Condiciones: Una vez aprobado un convenio de pago en Salesforce, las nuevas condiciones crediticias se envían automáticamente a JD Edwards para su aplicación.5

5. Roles y Permisos
Los perfiles involucrados con permisos de lectura y modificación en este proceso son:7

    Ejecutivo de Cuenta: Gestión operativa inicial.
    Jefe Administrativo: Supervisión y negociación.
    Jurídico: Emisión de convenios y procesos legales.
    Gerencia: Supervisión de KPIs y recuperación de cartera a través de dashboards en Tableau.2
    3





    El flujo de un seguimiento de un caso para el proceso CC3 (Cobranza general y negociación de deuda) en Salesforce está diseñado para transformar la gestión de cartera vencida en una operación proactiva y estructurada. El objetivo central es centralizar el seguimiento de los distribuidores con saldos vencidos, automatizar las notificaciones y formalizar las negociaciones a través de convenios de pago.1
2

A continuación se describe el flujo detallado desde su inicio hasta el cierre:
1. Inicio y Clasificación del Caso
El proceso se activa automáticamente cuando el sistema detecta días de crédito vencidos en la cuenta de un distribuidor, sincronizando la información con el ERP (JD Edwards).1
3

    Creación del Caso: Se genera un registro de tipo "Cobranza y Negociación" en el objeto Caso.1
    Asignación de Bucket: Dependiendo de la antigüedad de la deuda, el caso se clasifica en uno de los cuatro niveles de riesgo o "Buckets":2
        Verde: 1 a 5 días de atraso.
        Amarillo: 6 a 30 días de atraso.
        Naranja: 31 a 90 días de atraso.
        Rojo: Más de 91 días de atraso.

2. Gestión Operativa y Negociación
Cada bucket define responsabilidades y acciones específicas para buscar la recuperación de la deuda:

    Gestión Comercial (Buckets Verde y Amarillo): El Ejecutivo de Cuenta o el Jefe Administrativo recibe una notificación inicial vía Slack y correo electrónico para contactar al distribuidor. El objetivo es gestionar una promesa de pago o liquidación inmediata.1
    2
    Escalación y ANS (SLA): Si no hay respuesta dentro de los tiempos permitidos, las reglas de Milestones escalan el caso automáticamente al siguiente bucket (ej. de Amarillo a Naranja) para aumentar la presión de cobro.1

3. Formalización del Convenio (Bucket Naranja)
Cuando el adeudo persiste pero existe voluntad de pago, interviene el área Jurídica para formalizar el compromiso:

    Solicitud de Convenio: El Jefe Administrativo solicita a Jurídico la emisión de un Convenio de Pago.2
    Emisión y Cita: Se notifica al distribuidor sobre las condiciones de pago y se agenda una cita para la firma del convenio.2
    Proceso de Aprobación: Antes de aplicarse, el convenio debe pasar por un flujo de aprobación en Salesforce para validar las condiciones pactadas.1

4. Recuperación Legal (Bucket Rojo)
Si el caso alcanza el bucket Rojo (+91 días), se notifica a Jurídico para iniciar formalmente un proceso con expediente legal para recuperar el adeudo por la vía jurídica.2
5. Cierre e Integración con ERP
El objetivo final se cumple cuando se regulariza la situación financiera del distribuidor:

    Sincronización de Condiciones: Una vez aprobado el convenio en Salesforce, las nuevas condiciones crediticias se envían automáticamente a JD Edwards para actualizar el estatus del cliente.1
    Actualización de Saldos: Salesforce consume continuamente el servicio de saldos de JDE para reflejar el estado real del caso y cerrarlo cuando la deuda es liquidada.1
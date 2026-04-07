public with sharing class OrderRescheduleForFlowAction {

    public class Request {
        @InvocableVariable(required=true label='Order Id')
        public Id orderId;

        @InvocableVariable(required=true label='New Effective Date')
        public Date newEffectiveDate;

        @InvocableVariable(required=true label='Draft Status')
        public String draftStatus;

        @InvocableVariable(required=true label='Final Status')
        public String finalStatus;
    }

    public class Result {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Order Id')
        public Id orderId;

        @InvocableVariable(label='Previous Status')
        public String previousStatus;

        @InvocableVariable(label='Previous Status Code')
        public String previousStatusCode;

        @InvocableVariable(label='Draft Status Applied')
        public String draftStatusApplied;

        @InvocableVariable(label='Draft Status Code Applied')
        public String draftStatusCodeApplied;

        @InvocableVariable(label='Final Status Applied')
        public String finalStatusApplied;

        @InvocableVariable(label='Final Status Code Applied')
        public String finalStatusCodeApplied;

        @InvocableVariable(label='Final Effective Date')
        public Date finalEffectiveDate;
    }

    @InvocableMethod(label='Reschedule Order In Same Transaction')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> orderIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.orderId != null) {
                orderIds.add(req.orderId);
            }
        }

        Map<Id, Order> ordersById = new Map<Id, Order>();
        if (!orderIds.isEmpty()) {
            ordersById = new Map<Id, Order>([
                SELECT Id, Status, StatusCode, EffectiveDate
                FROM Order
                WHERE Id IN :orderIds
                FOR UPDATE
            ]);
        }

        for (Request req : requests) {
            Result res = new Result();
            res.success = false;
            res.orderId = (req == null) ? null : req.orderId;

            try {
                if (req == null) {
                    res.message = 'La solicitud es nula.';
                    results.add(res);
                    continue;
                }

                if (req.orderId == null) {
                    res.message = 'Debe proporcionarse el Order Id.';
                    results.add(res);
                    continue;
                }

                if (req.newEffectiveDate == null) {
                    res.message = 'Debe proporcionarse la nueva EffectiveDate.';
                    results.add(res);
                    continue;
                }

                if (String.isBlank(req.draftStatus)) {
                    res.message = 'Debe proporcionarse el Draft Status.';
                    results.add(res);
                    continue;
                }

                if (String.isBlank(req.finalStatus)) {
                    res.message = 'Debe proporcionarse el Final Status.';
                    results.add(res);
                    continue;
                }

                Order currentOrder = ordersById.get(req.orderId);
                if (currentOrder == null) {
                    res.message = 'No se encontró la orden.';
                    results.add(res);
                    continue;
                }

                res.previousStatus = currentOrder.Status;
                res.previousStatusCode = currentOrder.StatusCode;

                // 1) Pasar a Draft
                update new Order(
                    Id = req.orderId,
                    Status = req.draftStatus.trim()
                );

                Order afterDraft = [
                    SELECT Id, Status, StatusCode, EffectiveDate
                    FROM Order
                    WHERE Id = :req.orderId
                    LIMIT 1
                ];

                res.draftStatusApplied = afterDraft.Status;
                res.draftStatusCodeApplied = afterDraft.StatusCode;

                if (afterDraft.StatusCode != 'Draft') {
                    res.message =
                        'La orden no quedó en categoría Draft. ' +
                        'Status actual: ' + afterDraft.Status +
                        ' / StatusCode actual: ' + afterDraft.StatusCode;
                    results.add(res);
                    continue;
                }

                // 2) Actualizar EffectiveDate ya en Draft
                update new Order(
                    Id = req.orderId,
                    EffectiveDate = req.newEffectiveDate
                );

                Order afterDateChange = [
                    SELECT Id, Status, StatusCode, EffectiveDate
                    FROM Order
                    WHERE Id = :req.orderId
                    LIMIT 1
                ];

                if (afterDateChange.EffectiveDate != req.newEffectiveDate) {
                    res.message =
                        'No fue posible actualizar EffectiveDate. ' +
                        'Fecha actual: ' + String.valueOf(afterDateChange.EffectiveDate);
                    results.add(res);
                    continue;
                }

                // 3) Regresar al status final
                update new Order(
                    Id = req.orderId,
                    Status = req.finalStatus.trim()
                );

                Order finalOrder = [
                    SELECT Id, Status, StatusCode, EffectiveDate
                    FROM Order
                    WHERE Id = :req.orderId
                    LIMIT 1
                ];

                res.finalStatusApplied = finalOrder.Status;
                res.finalStatusCodeApplied = finalOrder.StatusCode;
                res.finalEffectiveDate = finalOrder.EffectiveDate;

                if (finalOrder.Status != req.finalStatus.trim()) {
                    res.message =
                        'La EffectiveDate se actualizó, pero la orden no regresó al status final esperado. ' +
                        'Status final real: ' + finalOrder.Status;
                    results.add(res);
                    continue;
                }

                if (finalOrder.EffectiveDate != req.newEffectiveDate) {
                    res.message =
                        'La orden regresó al status final, pero la EffectiveDate final no coincide. ' +
                        'Fecha final real: ' + String.valueOf(finalOrder.EffectiveDate);
                    results.add(res);
                    continue;
                }

                res.success = true;
                res.message = 'La orden fue desactivada, reprogramada y reactivada correctamente.';
                results.add(res);

            } catch (Exception e) {
                res.message = 'Error procesando la orden: ' + e.getMessage();
                results.add(res);
            }
        }

        return results;
    }
}
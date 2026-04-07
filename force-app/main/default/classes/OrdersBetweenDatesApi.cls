@RestResource(urlMapping='/v1/orders/*')
global with sharing class OrdersBetweenDatesApi {

    global class OrderItemDTO {
        public String id;
        public String orderId;

        public String product2Id;
        public String productName;
        public String productCode;

        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal totalPrice;

        public String pricebookEntryId;
        public String description;

        public Datetime createdDate;
        public Datetime lastModifiedDate;
    }

    global class OrderDTO {
        public String id;
        public String orderNumber;

        public String accountId;
        public String accountName;

        public String status;
        public String type;
        public String effectiveDate; // Date -> String

        public String pricebook2Id;
        public String currencyIsoCode; // solo si existe

        public Decimal totalAmount;

        public Datetime createdDate;
        public Datetime lastModifiedDate;

        public List<OrderItemDTO> items = new List<OrderItemDTO>();
    }

    global class ResponseDTO {
        public Datetime start;
        public Datetime endDt;
        public Integer limitSize;
        public Integer offsetSize;

        public Integer ordersCount;
        public Integer orderItemsCount;

        public List<OrderDTO> orders = new List<OrderDTO>();
    }

    @HttpGet
    global static ResponseDTO getOrders() {
        RestRequest req = RestContext.request;

        Datetime startDt = parseIsoDatetimeRequired(req.params.get('start'), 'start');
        Datetime endDt   = parseIsoDatetimeRequired(req.params.get('end'), 'end');

        if (endDt <= startDt) {
            throw badRequest('Invalid range: end must be greater than start.');
        }

        Integer limitSize  = parseIntOrDefault(req.params.get('limit'), 200);
        Integer offsetSize = parseIntOrDefault(req.params.get('offset'), 0);

        if (limitSize <= 0) limitSize = 200;
        if (limitSize > 500) limitSize = 500;
        if (offsetSize < 0) offsetSize = 0;

        // Campo opcional (multi-currency)
        Boolean hasCurrencyIso = Schema.SObjectType.Order.fields.getMap().containsKey('CurrencyIsoCode');

        // SELECT dinámico (para poder meter limit/offset y campo opcional)
        String selectClause =
            'SELECT Id, OrderNumber, AccountId, Account.Name, Status, Type, EffectiveDate, Pricebook2Id, TotalAmount, CreatedDate, LastModifiedDate'
            + (hasCurrencyIso ? ', CurrencyIsoCode' : '');

        String soql =
            selectClause +
            ' FROM Order' +
            ' WHERE LastModifiedDate >= :startDt AND LastModifiedDate < :endDt' +
            ' ORDER BY LastModifiedDate ASC, Id ASC' +
            ' LIMIT ' + String.valueOf(limitSize) +
            ' OFFSET ' + String.valueOf(offsetSize);

        List<Order> orders = Database.query(soql);

        Map<Id, OrderDTO> dtoById = new Map<Id, OrderDTO>();
        for (Order o : orders) {
            OrderDTO dto = new OrderDTO();
            dto.id = (String)o.Id;
            dto.orderNumber = o.OrderNumber;

            dto.accountId = (String)o.AccountId;
            dto.accountName = (o.Account != null) ? o.Account.Name : null;

            dto.status = o.Status;
            dto.type = o.Type;
            dto.effectiveDate = (o.EffectiveDate != null) ? String.valueOf(o.EffectiveDate) : null;

            dto.pricebook2Id = (String)o.Pricebook2Id;

            if (hasCurrencyIso) {
                // acceder por get() para no depender del campo en compilación
                Object cur = o.get('CurrencyIsoCode');
                dto.currencyIsoCode = (cur == null) ? null : String.valueOf(cur);
            }

            dto.totalAmount = o.TotalAmount;
            dto.createdDate = o.CreatedDate;
            dto.lastModifiedDate = o.LastModifiedDate;

            dtoById.put(o.Id, dto);
        }

        Integer itemsCount = 0;
        if (!dtoById.isEmpty()) {
            List<OrderItem> items = [
                SELECT
                    Id, OrderId,
                    Quantity, UnitPrice, TotalPrice,
                    PricebookEntryId, Description,
                    PricebookEntry.Product2Id,
                    PricebookEntry.Product2.Name,
                    PricebookEntry.Product2.ProductCode,
                    CreatedDate, LastModifiedDate
                FROM OrderItem
                WHERE OrderId IN :dtoById.keySet()
                ORDER BY OrderId ASC, Id ASC
            ];

            for (OrderItem oi : items) {
                OrderItemDTO idto = new OrderItemDTO();
                idto.id = (String)oi.Id;
                idto.orderId = (String)oi.OrderId;

                idto.quantity = oi.Quantity;
                idto.unitPrice = oi.UnitPrice;
                idto.totalPrice = oi.TotalPrice;

                idto.pricebookEntryId = (String)oi.PricebookEntryId;
                idto.description = oi.Description;

                if (oi.PricebookEntry != null && oi.PricebookEntry.Product2 != null) {
                    idto.product2Id = (String)oi.PricebookEntry.Product2Id;
                    idto.productName = oi.PricebookEntry.Product2.Name;
                    idto.productCode = oi.PricebookEntry.Product2.ProductCode;
                }

                idto.createdDate = oi.CreatedDate;
                idto.lastModifiedDate = oi.LastModifiedDate;

                dtoById.get(oi.OrderId).items.add(idto);
                itemsCount++;
            }
        }

        ResponseDTO res = new ResponseDTO();
        res.start = startDt;
        res.endDt = endDt;
        res.limitSize = limitSize;
        res.offsetSize = offsetSize;

        res.orders = dtoById.values();
        res.ordersCount = res.orders.size();
        res.orderItemsCount = itemsCount;

        return res;
    }

    // ---- helpers ----

    private static Datetime parseIsoDatetimeRequired(String raw, String paramName) {
        if (String.isBlank(raw)) {
            throw badRequest('Missing required query param: ' + paramName);
        }

        String normalized = raw.trim().replace('T', ' ');
        if (normalized.endsWith('Z')) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        if (normalized.length() == 16) {
            normalized = normalized + ':00';
        }

        try {
            return Datetime.valueOfGmt(normalized);
        } catch (Exception e) {
            throw badRequest('Invalid datetime for ' + paramName + '. Use ISO-8601 UTC like 2026-03-03T10:15:30Z');
        }
    }

    private static Integer parseIntOrDefault(String raw, Integer defaultVal) {
        if (String.isBlank(raw)) return defaultVal;
        try {
            return Integer.valueOf(raw);
        } catch (Exception e) {
            return defaultVal;
        }
    }

    private static AuraHandledException badRequest(String message) {
        RestContext.response.statusCode = 400;
        return new AuraHandledException(message);
    }
}
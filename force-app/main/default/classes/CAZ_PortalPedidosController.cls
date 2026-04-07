/**
 * ============================================================
 * Autor  : Juan Jose Loyola
 * Clase  : CAZ_PortalPedidosController
 *
 * Objetivo:
 * - Obtener el contexto del usuario autenticado de comunidad
 * - Localizar su Contact y Account
 * - Consultar las órdenes (Order) de esa Account
 *
 * Seguridad:
 * - with sharing
 * - SOQL con WITH USER_MODE
 *
 * Nota importante:
 * - Esta clase SOLO consulta.
 * - La creación del Order se hace desde el LWC.
 * ============================================================
 */
public with sharing class CAZ_PortalPedidosController {

    public class OrderContextDTO {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String userName;
        @AuraEnabled public List<OrderRowDTO> orders;
    }

    public class OrderRowDTO {
        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public Date effectiveDate;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public String description;
    }

    @AuraEnabled
    public static OrderContextDTO getMyOrdersContext() {
        Id currentUserId = UserInfo.getUserId();

        User currentUser = [
            SELECT Id, Name, ContactId
            FROM User
            WHERE Id = :currentUserId
            WITH USER_MODE
            LIMIT 1
        ];

        if (currentUser.ContactId == null) {
            throw new AuraHandledException(
                'El usuario actual no tiene un Contacto asociado.'
            );
        }

        Contact currentContact = [
            SELECT Id, AccountId, Account.Name
            FROM Contact
            WHERE Id = :currentUser.ContactId
            WITH USER_MODE
            LIMIT 1
        ];

        if (currentContact.AccountId == null) {
            throw new AuraHandledException(
                'El Contacto asociado al usuario no tiene una Cuenta relacionada.'
            );
        }

        List<Order> orderList = [
            SELECT Id,
                   OrderNumber,
                   EffectiveDate,
                   Status,
                   TotalAmount,
                   Description
            FROM Order
            WHERE AccountId = :currentContact.AccountId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];

        OrderContextDTO dto = new OrderContextDTO();
        dto.accountId = currentContact.AccountId;
        dto.accountName = currentContact.Account.Name;
        dto.contactId = currentContact.Id;
        dto.userName = currentUser.Name;
        dto.orders = new List<OrderRowDTO>();

        for (Order ord : orderList) {
            OrderRowDTO row = new OrderRowDTO();
            row.orderId = ord.Id;
            row.orderNumber = ord.OrderNumber;
            row.effectiveDate = ord.EffectiveDate;
            row.status = ord.Status;
            row.totalAmount = ord.TotalAmount;
            row.description = ord.Description;
            dto.orders.add(row);
        }

        return dto;
    }
}
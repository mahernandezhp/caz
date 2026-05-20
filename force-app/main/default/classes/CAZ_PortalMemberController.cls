public with sharing class CAZ_PortalMemberController {

    public class MemberOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public MemberOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class MemberFormData {
        @AuraEnabled public List<MemberOption> profiles;
        @AuraEnabled public List<MemberOption> roles;
        @AuraEnabled public List<MemberOption> permissionSets;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
    }

    @AuraEnabled(cacheable=true)
    public static MemberFormData getFormData() {
        MemberFormData data = new MemberFormData();

        User currentUser = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (currentUser.ContactId == null) {
            throw new AuraHandledException('El usuario actual no tiene un contacto asociado.');
        }
        data.accountId = currentUser.Contact.AccountId;
        data.accountName = currentUser.Contact.Account.Name;

        data.profiles = new List<MemberOption>();
        for (Profile p : [
            SELECT Id, Name
            FROM Profile
            WHERE UserLicense.LicenseDefinitionKey IN ('PID_Partner_Community', 'PID_Partner_Community_Login')
            AND Name LIKE 'Portal Distribuidor%'
            ORDER BY Name
        ]) {
            data.profiles.add(new MemberOption(p.Name, p.Id));
        }

        data.roles = new List<MemberOption>();
        for (UserRole r : [
            SELECT Id, Name FROM UserRole
            WHERE PortalAccountId = :data.accountId
            ORDER BY Name
        ]) {
            data.roles.add(new MemberOption(r.Name, r.Id));
        }

        data.permissionSets = new List<MemberOption>();
        for (PermissionSet ps : [
            SELECT Id, Label
            FROM PermissionSet
            WHERE Name IN ('CAZ_Distribuidor', 'CAZ_Distribuidor_Admin')
            ORDER BY Label
        ]) {
            data.permissionSets.add(new MemberOption(ps.Label, ps.Id));
        }

        return data;
    }

    @AuraEnabled
    public static Id createPortalMember(
        String firstName,
        String lastName,
        String email,
        Id profileId,
        Id roleId,
        List<Id> permissionSetIds,
        Id accountId
    ) {
        if (String.isBlank(lastName) || String.isBlank(email) || profileId == null || accountId == null) {
            throw new AuraHandledException('Faltan campos requeridos.');
        }

        try {
            Contact c = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                AccountId = accountId
            );
            insert c;

            createUserAsync(
                c.Id, firstName, lastName, email, profileId, roleId,
                permissionSetIds == null ? new List<Id>() : permissionSetIds
            );

            return c.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @future
    public static void createUserAsync(
        Id contactId,
        String firstName,
        String lastName,
        String email,
        Id profileId,
        Id roleId,
        List<Id> permissionSetIds
    ) {
        try {
            String baseUsername = email + '.' + UserInfo.getOrganizationId().substring(0, 5).toLowerCase();
            String alias = ((firstName == null ? '' : firstName.substring(0, Math.min(1, firstName.length()))) + lastName).replaceAll('[^a-zA-Z0-9]', '').toLowerCase();
            if (alias.length() > 8) alias = alias.substring(0, 8);
            if (alias.length() == 0) alias = 'usr' + String.valueOf(Datetime.now().getTime()).right(5);

            User u = new User(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Username = baseUsername,
                Alias = alias,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'es',
                LocaleSidKey = 'es_MX',
                TimeZoneSidKey = 'America/Mexico_City',
                ProfileId = profileId,
                ContactId = contactId,
                UserRoleId = roleId
            );
            insert u;

            if (permissionSetIds != null && !permissionSetIds.isEmpty()) {
                List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
                for (Id psId : permissionSetIds) {
                    psas.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = psId));
                }
                insert psas;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error creating user async: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}

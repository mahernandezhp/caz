// ============================================================
// Setup: Usuario de Comunidad - Distribuidor CAZ
// Crea: Account > Contact > Community User > PermissionSet
// ============================================================

// 1. Buscar o crear Account (Distribuidor)
Account acc;
List<Account> existingAccs = [SELECT Id FROM Account WHERE Name = 'Distribuidora Cruz Azul Demo' LIMIT 1];
if (!existingAccs.isEmpty()) {
    acc = existingAccs[0];
    System.debug('Account existente: ' + acc.Id);
} else {
    acc = new Account(
        Name = 'Distribuidora Cruz Azul Demo',
        BillingCity = 'Ciudad de México',
        BillingCountry = 'México',
        Phone = '55-5424-9000'
    );
    insert acc;
    System.debug('Account creado: ' + acc.Id);
}

// 2. Buscar o crear Contact
Contact con;
List<Contact> existingCons = [SELECT Id FROM Contact WHERE Email = 'distribuidor.demo@caztest.com' LIMIT 1];
if (!existingCons.isEmpty()) {
    con = existingCons[0];
    System.debug('Contact existente: ' + con.Id);
} else {
    con = new Contact(
        FirstName = 'Juan',
        LastName = 'Distribuidor Demo',
        Email = 'distribuidor.demo@caztest.com',
        Phone = '55-1234-5678',
        AccountId = acc.Id
    );
    insert con;
    System.debug('Contact creado: ' + con.Id);
}

// 3. Obtener perfil Customer Community Plus User
Profile communityProfile = [
    SELECT Id FROM Profile
    WHERE Name = 'Customer Community Plus User'
    LIMIT 1
];

// 4. Buscar o crear Community User
User commUser;
List<User> existingUsers = [SELECT Id FROM User WHERE Username = 'distribuidor.demo@caztest.com.caz' LIMIT 1];
if (!existingUsers.isEmpty()) {
    commUser = existingUsers[0];
    System.debug('Usuario existente: ' + commUser.Id);
} else {
    commUser = new User(
        FirstName = 'Juan',
        LastName = 'Distribuidor Demo',
        Email = 'distribuidor.demo@caztest.com',
        Username = 'distribuidor.demo@caztest.com.caz',
        Alias = 'jdist',
        CommunityNickname = 'jdistribuidor',
        TimeZoneSidKey = 'America/Mexico_City',
        LocaleSidKey = 'es_MX',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'es',
        ProfileId = communityProfile.Id,
        ContactId = con.Id,
        IsActive = true
    );
    insert commUser;
    System.debug('Usuario creado: ' + commUser.Id);
}

// 5. Asignar Permission Set CAZ_Distribuidor
PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CAZ_Distribuidor' LIMIT 1];
List<PermissionSetAssignment> existingPSA = [
    SELECT Id FROM PermissionSetAssignment
    WHERE AssigneeId = :commUser.Id AND PermissionSetId = :ps.Id
];
if (existingPSA.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = commUser.Id, PermissionSetId = ps.Id);
    System.debug('PermissionSet asignado');
} else {
    System.debug('PermissionSet ya asignado');
}

// 6. NetworkMember se gestiona automáticamente al asignar el perfil de comunidad al site
// El acceso al portal se configura en Experience Builder > Administration > Members

System.debug('=== SETUP COMPLETADO ===');
System.debug('Usuario: distribuidor.demo@caztest.com.caz');
System.debug('Account ID: ' + acc.Id);
System.debug('Contact ID: ' + con.Id);
System.debug('User ID: ' + commUser.Id);

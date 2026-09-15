# Problèmes Firestore à résoudre

## 1. Erreurs de permission (PERMISSION_DENIED)

### Collection `providers`
**Erreur**: `Listen for QueryWrapper(query=Query(target=Query(providers where ownerId==eOvbTEkwcfM7vCoXfkY838zxd2j2 order by __name__);limitType=LIMIT_TO_FIRST)) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}`

**Cause**: Les règles de sécurité Firestore n'autorisent pas les providers à lire leur propre collection.

**Solution requise**: Mettre à jour les règles Firestore pour permettre aux providers de lire leurs propres profils.

Exemple de règle à ajouter:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Providers peuvent lire leurs propres profils
    match /providers/{providerId} {
      allow read: if request.auth != null && resource.data.ownerId == request.auth.uid;
      allow write: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    
    // Collection providers - query par ownerId
    match /providers/{providerId} {
      allow list: if request.auth != null;
    }
  }
}
```

### Collection `conversations`
**Erreur**: `Listen for QueryWrapper(query=Query(target=Query(conversations/eOvbTEkwcfM7vCoXfkY838zxd2j2_qFovk1N6ViSxRuB1sHljPqazYHm2 order by __name__);limitType=LIMIT_TO_FIRST)) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}`

**Cause**: Les règles de sécurité Firestore n'autorisent pas la lecture/écriture des conversations.

**Solution requise**: Mettre à jour les règles Firestore pour permettre aux utilisateurs participants de lire/écrire leurs conversations.

Exemple de règle à ajouter:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Conversations - uniquement les participants peuvent lire/écrire
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
    }
    
    // Messages - uniquement les participants de la conversation peuvent lire/écrire
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(resource.data.conversationId)).data.participantIds;
    }
  }
}
```

---

## 2. Index manquant pour `service_requests`

**Erreur**: `The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/servmarket-296fa/firestore/indexes?create_composite=Cllwcm9qZWN0cy9zZXJ2bWFya2V0LTI5NmZhL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zZXJ2aWNlX3JlcXVlc3RzL2luZGV4ZXMvXxABGg4KCnByb3ZpZGVySWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC`

**Cause**: La requête sur `service_requests` avec `where('providerId', isEqualTo: ...)` et `orderBy('createdAt', descending: true)` nécessite un index composite.

**Solution requise**: Créer l'index composite dans la console Firebase.

**Étapes**:
1. Cliquez sur le lien fourni dans l'erreur: https://console.firebase.google.com/v1/r/project/servmarket-296fa/firestore/indexes?create_composite=Cllwcm9qZWN0cy9zZXJ2bWFya2V0LTI5NmZhL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zZXJ2aWNlX3JlcXVlc3RzL2luZGV4ZXMvXxABGg4KCnByb3ZpZGVySWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC
2. Ou manuellement dans Firebase Console:
   - Allez dans Firestore > Indexes
   - Cliquez sur "Add composite index"
   - Collection: `service_requests`
   - Fields:
     - `providerId` (Ascending)
     - `createdAt` (Descending)
3. Cliquez sur "Create"

---

## 3. Collection `service_requests` - règles de sécurité

**Recommandation**: Ajouter des règles pour sécuriser la collection `service_requests`:

```firestore
match /service_requests/{requestId} {
  // Le client peut lire ses propres demandes
  allow read: if request.auth != null && 
    (resource.data.clientId == request.auth.uid || 
     resource.data.providerId == request.auth.uid);
  
  // Le client peut créer des demandes
  allow create: if request.auth != null && 
    request.resource.data.clientId == request.auth.uid;
  
  // Le provider peut mettre à jour le statut
  allow update: if request.auth != null && 
    resource.data.providerId == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']);
}
```

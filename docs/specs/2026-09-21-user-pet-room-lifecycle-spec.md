# 2026-09-21 使用者、多寵物管理與聊天室生命週期契約規格 (User, Pet & Room Lifecycle Spec v1)

- **狀態**：Draft / Proposed
- **日期**：2026-09-21
- **適用範圍**：`pet_digit` (Flutter Frontend) 與 `pet_digit_backend` (Firebase Backend)

---

## 1. 背景與目標

### 1.1 現有局限
1. **房間寫死**：前端 [`ChatShell`](file:///Users/appgongyong/Documents/Codex/2026-09-18/referenced-chatgpt-conversation-this-is-an/lib/chat/presentation/chat_shell.dart) 目前寫死 `'friends'` / `'family'`，缺乏真實的建立房間、搜尋好友與成員管理機制。
2. **單機 Demo 寵物**：目前代碼中的柯基、貓、鸚鵡僅是驗證底層物理碰撞與動作幀渲染的 Demo 物件，缺乏真實「主人（User）」與「名下擁有多隻寵物（Pets）」的資料綁定。
3. **無真實註冊登入**：先前為 Emulator 與 Staging 僅提供臨時的匿名認證，無法持久化使用者與好友關係。

### 1.2 設計目標
1. **使用者身分與個人檔案（User Profile）**：支援真實認證、暱稱、頭像、唯一搜尋標籤（`searchTag`）與預設主寵設定。
2. **多寵物註冊與管理（1:N Pet Management）**：
   - 主人可登記多隻寵物（包含真實照片、物種、品種、生日、性格）。
   - 寵物物種（`species`）決定聊天室底層動態像素圖資（狗 / 貓 / 鸚鵡）。
   - 寵物性格（`personality`）提供後續行為決策（`PetBehaviorSelector`）權重。
3. **聊天室成立規則（Room Establishment）**：
   - **1 對 1 私聊**：確定性 ID（`dm_{minUid}_{maxUid}`），防止重複建房。
   - **多人群聊**：支援自訂房名與頭像，發起人為 Owner，支援成員邀請。
4. **房間內多寵物調度（In-Room Multi-Pet Summoning）**：
   - 預設帶入主人的「預設主寵（`defaultPet`）」。
   - 主人可打開房間寵物抽屜，自由勾選讓自己名下的「部分」或「全部」寵物同時進房。
   - 成員寵物以深快照（Snapshot）寫入房間成員資訊，消除高頻跨表讀取。
5. **聊天列表高效載入（Fan-out Room Summaries）**：
   - 藉由 `/users/{uid}/roomSummaries/{roomId}` 提供瞬間載入的聊天列表，解決 Firestore 無法跨 room 集合反向索引的限制。

---

## 2. 資料庫結構規格 (Firestore Schemas)

```text
Firestore Root
 ├── users/{uid}                              (主人主檔)
 │    ├── pets/{petId}                        (名下寵物主檔, 1:N)
 │    └── roomSummaries/{roomId}              (該主人的聊天列表快照)
 │
 ├── searchTags/{searchTagLower}              (搜尋標籤索引與唯一性保證)
 │
 └── rooms/{roomId}                           (聊天室主體)
      ├── members/{uid}                       (房間成員與攜帶寵物快照)
      ├── messages/{messageId}                (聊天訊息)
      └── clientRequests/{clientId}           (冪等請求鎖)
```

### 2.1 主人個人檔案：`/users/{uid}`
```typescript
interface UserProfile {
  uid: string;                 // Firebase Auth UID
  nickname: string;            // 暱稱 (1-30 字元)
  avatarUrl: string;           // 主人大頭貼 URL 或 Storage 路徑
  searchTag: string;           // 專屬搜尋標籤 (例如 "corgi_master")
  searchTagLower: string;      // 小寫標籤，用於不分大小寫查詢
  defaultPetId: string;        // 當前預設出場的主寵物 ID
  createdAt: Timestamp;        // 建立時間
  updatedAt: Timestamp;        // 更新時間
}
```

### 2.2 搜尋標籤唯一性索引：`/searchTags/{searchTagLower}`
* 用於確保全局 `searchTag` 不重複，並提供 O(1) 的標籤查找：
```typescript
interface SearchTagIndex {
  searchTag: string;
  uid: string;
  createdAt: Timestamp;
}
```

### 2.3 寵物主檔：`/users/{uid}/pets/{petId}`
```typescript
interface PetProfile {
  petId: string;               // 唯一 UUID
  ownerUid: string;            // 主人 UID
  name: string;                // 寵物名字 (例如「波比」)
  species: 'dog' | 'cat' | 'parrot'; // 物種 (決定底層像素骨架)
  breed: string;               // 品種 (例如 "corgi", "shiba", "british_shorthair")
  avatarUrl: string;           // 寵物真實照片 URL
  gender?: 'male' | 'female' | 'neutered' | 'unknown';
  birthday?: Timestamp;        // 生日 / 年齡
  personality: string;         // 性格標籤 (playful / cautious / curious / calm)
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 2.4 聊天室主體：`/rooms/{roomId}`
```typescript
interface RoomDocument {
  roomId: string;              // 房間 ID (1v1 為 dm_{uidA}_{uidB}，群聊為 UUID)
  type: 'direct' | 'group';    // 類型
  name: string;                // 群聊名稱 (私聊時可為空或預設)
  avatarUrl?: string;          // 群聊頭像
  createdBy: string;           // 發起人 UID
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastMessage?: {
    text: string;
    senderId: string;
    kind: string;
    createdAt: Timestamp;
  };
  memberCount: number;
}
```

### 2.5 房間成員與攜帶寵物：`/rooms/{roomId}/members/{uid}`
```typescript
interface RoomMember {
  uid: string;
  role: 'owner' | 'admin' | 'member';
  active: boolean;             // 是否處於房間中
  joinedAt: Timestamp;
  // 該主人在此房間中啟用的寵物快照（支援 1 隻、多隻或全部）
  pets: PetRoomSnapshot[];
}

interface PetRoomSnapshot {
  petId: string;
  name: string;
  species: 'dog' | 'cat' | 'parrot';
  breed: string;
  avatarUrl: string;
  personality: string;
}
```

### 2.6 個人聊天室摘要：`/users/{uid}/roomSummaries/{roomId}`
```typescript
interface RoomSummary {
  roomId: string;
  type: 'direct' | 'group';
  name: string;                // 顯示名稱 (1v1 為對方暱稱，群聊為房名)
  avatarUrl?: string;          // 顯示頭像 (1v1 為對方頭像，群聊為群頭像)
  lastMessageText?: string;
  lastMessageSenderId?: string;
  lastMessageAt?: Timestamp;
  unreadCount: number;
  active: boolean;             // 是否仍為有效成員
  updatedAt: Timestamp;
}
```

---

## 3. Cloud Functions (Callable API) 契約

所有寫入操作均禁止 Client 直接呼叫 Firestore，統一透過 Firebase Functions (v2 `onCall`)。

### 3.1 使用者與個人檔案 API
1. **`upsertUserProfile`**
   - **入參**：`{ nickname: string, avatarUrl: string, searchTag: string }`
   - **邏輯**：
     1. 檢查 Caller 身分。
     2. 檢查 `searchTag` 格式（3-20 字元，英數字與底線）。
     3. 事務中檢查 `/searchTags/{searchTagLower}`，若已被他人占用則拋出 `already-exists`。
     4. 寫入 `/users/{uid}` 與 `/searchTags/{searchTagLower}`。
   - **回傳**：`UserProfile`

2. **`searchUsers`**
   - **入參**：`{ query: string, limit?: number }`
   - **邏輯**：
     - 若 `query` 以 `@` 開頭，精確匹配 `searchTags`。
     - 若無，依 `searchTagLower` 前綴或 `nickname` 前綴查詢。
   - **回傳**：`Array<{ uid: string, nickname: string, avatarUrl: string, defaultPetId?: string }>`

### 3.2 寵物管理 API
1. **`registerPet`**
   - **入參**：
     ```typescript
     {
       name: string;
       species: 'dog' | 'cat' | 'parrot';
       breed: string;
       avatarUrl: string;
       gender?: 'male' | 'female' | 'neutered';
       birthday?: string;
       personality?: string;
       setAsDefault?: boolean;
     }
     ```
   - **邏輯**：
     1. 生成唯一 `petId`。
     2. 寫入 `/users/{uid}/pets/{petId}`。
     3. 若該用戶尚無 `defaultPetId` 或 `setAsDefault == true`，自動更新 `/users/{uid}.defaultPetId = petId`。
   - **回傳**：`PetProfile`

2. **`updatePet`**
   - **入參**：`{ petId: string, updates: Partial<PetProfile> }`
   - **邏輯**：更新寵物資訊，禁止變更 `petId` 與 `ownerUid`。

3. **`setDefaultPet`**
   - **入參**：`{ petId: string }`
   - **邏輯**：驗證該寵物存在且屬於 Caller，更新 `/users/{uid}.defaultPetId = petId`。

### 3.3 聊天室成立與多寵物調度 API
1. **`createRoom`**
   - **入參**：
     ```typescript
     {
       type: 'direct' | 'group';
       inviteeUids: string[];
       name?: string;
       avatarUrl?: string;
     }
     ```
   - **邏輯**：
     - **1 對 1 私聊 (`direct`)**：
       - `inviteeUids` 長度必須恰為 1，且不能為自己。
       - 計算確定性房號：`const roomId = 'dm_' + [callerUid, targetUid].sort().join('_')`。
       - 若該房已存在，直接將雙方設為 `active: true` 並返回 `roomId`。
       - 分別讀取雙方的 `defaultPetId` 寵物資料，建立預設攜帶快照。
     - **多人群聊 (`group`)**：
       - `name` 為必填。
       - 生成 UUID `roomId`。
       - Caller 為 `role: 'owner'`，受邀者為 `role: 'member'`。
       - 遍歷所有成員的 `defaultPetId` 生成預設攜帶快照。
     - 事務寫入：
       - `/rooms/{roomId}`
       - 每個成員的 `/rooms/{roomId}/members/{uid}`（含預設 `pets: [defaultPetSnapshot]`）
       - 每個成員的 `/users/{uid}/roomSummaries/{roomId}`
   - **回傳**：`{ roomId: string, type: string, memberCount: number }`

2. **`updateRoomPets` (房間多寵物調度)**
   - **入參**：`{ roomId: string, petIds: string[] }`
   - **邏輯**：
     1. 驗證 Caller 是該房間的有效活躍成員 (`isMember`)。
     2. 驗證 `petIds` 中的每隻寵物都屬於 Caller (`/users/{uid}/pets/{petId}`)。
     3. 抓取這幾隻寵物的最新快照，寫入 `/rooms/{roomId}/members/{callerUid}.pets = snapshots`。
   - **回傳**：`{ success: true, activePets: PetRoomSnapshot[] }`

3. **`leaveRoom`**
   - **入參**：`{ roomId: string }`
   - **邏輯**：
     1. 更新 `/rooms/{roomId}/members/{callerUid}.active = false`。
     2. 清空該成員在此房間的寵物快照：`pets = []`。
     3. 更新 Caller 的 `/users/{uid}/roomSummaries/{roomId}.active = false`。
     4. 若為群聊且所有人皆離開，進行房間歸檔。

---

## 4. Firestore 安全規則 (Security Rules) 增補規劃

在現有的 [`firestore.rules`](file:///Users/appgongyong/Documents/Codex/2026-09-18/pet_digit_backend/firestore.rules) 基礎上擴充：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isOwner(uid) { return signedIn() && request.auth.uid == uid; }
    function isMember(roomId) {
      return signedIn() &&
        exists(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid)).data.active == true;
    }

    // 搜尋標籤：僅允許登入用戶唯讀，所有寫入全由 Cloud Functions 處理
    match /searchTags/{tag} {
      allow read: if signedIn();
      allow write: if false;
    }

    // 房間：嚴格禁止 Client 直寫，讀取必須是成員
    match /rooms/{roomId} {
      allow read: if isMember(roomId);
      allow write: if false;

      match /members/{uid} {
        allow read: if isMember(roomId);
        allow write: if false;
      }
      match /messages/{messageId} {
        allow read: if isMember(roomId);
        allow write: if false;
      }
      match /clientRequests/{clientId} { allow read, write: if false; }
    }

    // 使用者：個人可讀寫自身檔案、名下寵物與聊天列表摘要
    match /users/{uid} {
      allow read: if signedIn(); // 允許登入者查看其他使用者基本公開檔案
      allow write: if isOwner(uid);

      match /pets/{petId} {
        allow read: if signedIn(); // 允許登入者檢視寵物公開資料
        allow write: if isOwner(uid);
      }
      match /devices/{deviceId} { allow read, write: if isOwner(uid); }
      match /roomSummaries/{roomId} {
        allow read: if isOwner(uid);
        allow write: if false; // 由 Cloud Functions 同步寫入，防止 Client 竄改未讀與最後訊息
      }
    }
  }
}
```

---

## 5. 前端實作與整合架構

1. **認證與登入流程**：
   - 首次登入判斷 `/users/{uid}` 是否存在。
   - 若無，導向註冊引導精靈（Onboarding Wizard）：
     - Step 1: 填寫主人暱稱、上傳頭像、選擇 `searchTag`。
     - Step 2: **強制登記首隻寵物**（名字、物種、品種、真實照片、性格）。
2. **寵物背包（Pet Manager）**：
   - 瀏覽名下多隻寵物列表。
   - 新增、修改、切換預設主寵。
3. **聊天列表（Chat List View）**：
   - 監聽 `/users/{uid}/roomSummaries`（按 `updatedAt desc` 排序）。
   - 點擊對話進入聊天室。
4. **聊天室內多寵物同台（Multi-Pet World）**：
   - 監聽 `/rooms/{roomId}/members`，集合所有活躍成員的 `pets` 陣列。
   - [`PetWorldController`](file:///Users/appgongyong/Documents/Codex/2026-09-18/referenced-chatgpt-conversation-this-is-an/lib/pet/domain/pet_world_controller.dart) 依據 `species` 為每隻寵物建立獨立的運動實體與懸浮姓名標籤。
   - 聊天室右上角提供「🐾 寵物調度」抽屜，讓主人隨時勾選（部分或全部）自己的寵物進退場。

---

## 6. 驗收矩陣 (Acceptance Matrix)

| 項目 | 測試項目 | 預期結果 |
|---|---|---|
| User | 唯一 searchTag 註冊 | 重複 searchTag 拋出 `already-exists`；小寫統一索引 |
| Pet | 首隻寵物登記 | 自動指派為 `defaultPetId`，資料完整寫入子集合 |
| Pet | 多寵物登記與切換 | 可登記多隻不同物種寵物，支援切換預設寵物 |
| Room | 1v1 私聊建立 | 房號確定性；重複發起不建立重複房間；預設各自帶入主寵快照 |
| Room | 多人群聊建立 | 成功建立房間與成員，所有成員同步寫入 `roomSummaries` |
| Room | 房間寵物調度 | 呼叫 `updateRoomPets` 勾選 2 隻寵物，房間成員快照即時更新為 2 隻寵物 |
| Room | 成員離開房間 | 成員狀態變為 inactive，寵物快照清空，摘要標記 inactive |

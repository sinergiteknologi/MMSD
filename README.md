# new_mmsd_apps vs NewMMSDApps

Flutter `new_mmsd_apps` adalah konversi dari Android Java `NewMMSDApps`. Menu utama dan kontrak SOAP sudah terpasang ke UI. Beberapa alur Android masih ringkas (PDF native, TranAct, simulasi master lengkap).

Acuan Android: `T102` Prospect, `T103/T104` unit, `T201/T202` list, `T203` status, `T204/T205` edit customer, `T206` edit unit, `T207` SPK list, `T208/T209` form SPK, `T901` cetak/share SPK, `T601/T1001` filter report, `T701` simulasi.

## Status ringkas

| Area | Status |
|---|---|
| Splash, versi, login bisnis/server, session | Sesuai sebagian |
| Menu + authority (`001`–`012`) | Sesuai |
| Sync master Brand/Type/Model/Color/Activity/City/District | Sesuai |
| Prospect Find Customer + FGOC + multi-unit | Sesuai |
| Prospect List / FU / Hot / True + ganti status + edit | Sesuai |
| SPK Registration / SPK List / Indent | Sesuai |
| Report & Report CRM | Sesuai |
| Simulasi | Sesuai sebagian |
| Change Password | Sesuai |
| Call / SMS / WhatsApp | Sesuai |
| Cetak PDF native | Belum ada |

## Yang sudah sesuai

- Splash cek `Versi`, restore session, login `GetDataBisnis` + `Login` cabang `0001`.
- Menu: Prospect, Prospect List, FU, Hot, True, SPK Registration, SPK List, Report, Report CRM, Simulasi, Change Password. Item disaring `USER_MAINAUT`.
- Refresh master: Brand, Type, Model, Color, Activity, SubActivity, City, District.
- Prospect personal: Find Customer (`GetFindProspect2`), cek telepon, kota.
- Prospect company/FGOC: cari `GetDataFGOC`, cek `GetExistPhoneNumberFGOC`.
- Multi-unit `HISTORYUNIT` lalu upload `UploadNewData4` (field unit di-join `|`).
- List history: filter tanggal, `GetDataHistory` / `GetDataHistorySPK`.
- Select list: edit customer/unit (`GetDataCustomer`, `GetDataHistoryEdit`) + Change Status (`UploadStatus`).
- SPK Registration: form personal/company `UploadCreateSPK2` (brand, unit, lokasi, FGOC, faktur, TOP).
- SPK List: status `Approved` → `GetDataSPKIndent` + share WhatsApp; selain itu edit via `GetDataCustomerSPK`.
- Report filter: scope Sales/SPV/Branch, status, brand/type/model, activity, fleet, tipe customer + Call/WA/SMS/salin nomor.
- Simulasi kredit lokal (OTR, DP, tenor, bunga, asuransi, provisi, admin).
- Change Password (`UploadNewPassword`).

## Yang belum sesuai

### Change status (`T203`)

- Alamat, KTP, birth date, religion, TOP, job, LOB masih dikirim kosong.
- `UploadStatusHP` dan `GetFUProspect` belum dipakai UI.

### SPK

- Android `T901` merender PDF. Flutter menampilkan data indent + share/salin, tanpa file PDF.

### Report

- Tabel CRM Android punya grouping/subtotal. Flutter tabel datar.

### Simulasi (`T701`)

- Opsi model/leasing/tenor dari master Android belum lengkap.

### Lainnya

- `GetDataTranAct` / `UploadTranAct` / `T_TRANACT` belum ada layar.
- Force update Android buka Play Store; Flutter hanya salin tautan.
- UI Flutter (grid + kartu) beda dari drawer Android; fungsi menu yang sama.

## API sudah ada, UI belum

| Operasi | Dipakai UI? |
|---|---|
| `GetFindProspect2`, `GetExistPhoneNumber`, `UploadNewData4` | Ya |
| `GetDataFGOC`, `GetExistPhoneNumberFGOC`, `GetFindProspectFGOC` | Ya |
| `GetDataHistory`, `GetDataHistorySPK`, `UploadStatus`, `UploadNewPassword` | Ya |
| `GetDataCustomer`, `GetDataCustomerSPK`, `GetDataHistoryEdit` | Ya |
| `GetDataSPKIndent` | Ya |
| Report SOAP + filter | Ya |
| `GetDataHistoryWithType` | Ya |
| `GetFUProspect`, `UploadStatusHP` | Belum |
| `GetDataTranAct`, `UploadTranAct` | Belum |

## Jalankan Flutter

```bash
cd new_mmsd_apps
flutter pub get
flutter run
```

Generate icon: `dart run flutter_launcher_icons`

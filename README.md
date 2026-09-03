# ID-Generator

MDG-F ID / number generator framework, converted from the `/S4E/` namespace
to the `Z` customer namespace. abapGit repo, `PREFIX` folder logic, source
under `src/`.

## Framework

| Object | Role |
|---|---|
| `ZIF_MDG_ID_NUMBER_GEN` | Number generator interface (`GENERATE_NUMBER`, `SPLIT_NUMBER`) |
| `ZCL_MDG_ID_NUMGEN_BASE` | Template-method base class: buffers the input structure, resolves the MDG staging table, reads existing IDs (`QUERYING_DB`), structure validation |
| `ZCL_MDG_ID_NUMGEN_FACTORY` | Maps `(entity, project code)` to the concrete generator class / structure |
| `ZCL_MDG_ID_UIBB_FEEDER` | Generic FPM GUIBB form feeder; on `ZATTR_SELECTED` calls the factory and writes the ID into event key `GENERATED_ID`. `IF_FPM_GUIBB_OVS~HANDLE_PHASE_2` is generic (fallback + `SET_OUTPUT_TABLE`); concrete feeders redefine the protected `OVS_HANDLE_PHASE_2` to return the value-help table per field. |
| `ZIF_MDG_ID_CONSTANTS` | Central constants (project codes, attribute names, fixed values) |
| `ZCL_MDG_ID_SG_UTIL` | Company code ↔ plant assignment (buffered stub) |
| `ZCL_MDG_CCTR_RULES` | Rule type container (`TT_FUNC`) |

### Fixes applied during the conversion

* `ZCL_MDG_ID_NUMGEN_BASE=>QUERYING_DB` now clears `IT_MY_DATA` at the start
  (the original appended on every re-query, contaminating the gap scan).
* Dynamic `WHERE` literals use `CL_ABAP_DYN_PRG=>QUOTE` instead of `QUOTE_STR`.
* Guard in `ZCL_MDG_ID_NUMGEN_FACTORY=>GET_NUMBER_GENERATOR` when no class /
  structure is mapped (avoids a dump on empty `CREATE OBJECT` / `CREATE DATA`).
* `ZCL_MDG_SE_PCTR_ID_GEN` uses an explicit loop instead of
  `READ TABLE ... WITH KEY comp+off(len) = ...` and drops the stray trailing
  space in the reference template.

## Example generators

| Object | Entity / Project |
|---|---|
| `ZCL_MDG_SE_PCTR_ID_GEN` | Profit Center / SE – full implementation |
| `ZCL_MDG_CCTRID_RULE` | Cost Center entity feeder base |
| `ZCL_MDG_SE_CCTRID_RULE` | Cost Center / SE feeder (OVS + BRF+) |

## SGRE Bank GL Account ID generator (entity ACCOUNT)

Implements the *SE Bank GL Account Concept (AGORA / WP Treasury)* /
`SGRE_GL_Bank_Account_calculator.xlsx`.

**GL account (10 char SAKNR), fully deterministic:**

```
'00' + group(1-3) + bank code(4-5) + currency code(6-7) + planning digit(8)
```

| Object | Role |
|---|---|
| `ZCL_MDG_SG_ACCT_ID_GEN` | Concrete generator. `GENERATE_NUMBER` assembles the GL account from the four picked values – no DB read. `SPLIT_NUMBER` decodes an existing account. |
| `ZCL_MDG_SG_ACCT_RULES` | Hard-coded lookup tables from the calculator workbook: `GET_BANK_CODES` (201, incl. every "(Bank account# N)" row), `GET_CURRENCY_CODES` (93), `GET_ACCOUNT_GROUPS` (5), `GET_PLANNING_LEVELS` (18). |
| `ZCL_MDG_0G_ACC_ID_A_GEN` | ACCOUNT entity feeder base (`FD_ENTITY = ACCOUNT`). |
| `ZCL_MDG_SG_ACC_ID_A_GEN` | ACCOUNT / SGRE feeder (inherits `ZCL_MDG_0G_ACC_ID_A_GEN`, `FD_PROJECT_NAME = 'SGRE'`); OVS value helps for account group / bank / currency / payment method. Used as the `FPM_FORM_UIBB` feeder class. |
| `ZMDG_S_SG_ACCT_NAMING` | UIBB structure: `COMP_CODE`, `ACCOUNT_GROUP`, `BANK_CODE`, `CURRENCY`, `PAYMENT_METHOD`. |
| `ZE_MDG_BANK_CODE` … `ZE_MDG_PAYMENT_METHOD` | 9 data elements. |
| `ZCL_MDG_FEED_ACC_BASE` | Detail-form feeder base: inherits the standard MDG-F ACCOUNT feeder (`CL_MDGF_GUIBB_ACCOUNT`), redefines `PROCESS_EVENT` to take `GENERATED_ID` off the `ZATTR_SELECTED` event and `MO_ENTITY->SET_PROPERTY( ACCOUNT )`. Mirrors `/S4E/CL_P40_MDG_FEED_CCTR_BASE`. |
| `ZCL_MDG_FEED_ACC_SG` | Project (SGRE) detail feeder; the class the ACCOUNT detail UIBB config points at. Currently just inherits the write-back; grow it for field-property / OVS control like `/S4E/CL_P40_MDG_FEED_CCTR_SG`. |

### How the two UIBBs connect

1. **ID generator UIBB** (`FPM_FORM_UIBB`, feeder `ZCL_MDG_SG_ACC_ID_A_GEN`, structure `ZMDG_S_SG_ACCT_NAMING`) – user picks the values, presses the button that raises `ZATTR_SELECTED`; `ON_ZATTR_SELECTED` puts the generated GL account into FPM event key `GENERATED_ID`.
2. **ACCOUNT detail UIBB** (standard MDG-F form, feeder swapped to `ZCL_MDG_FEED_ACC_SG`) – its `PROCESS_EVENT` sees `ZATTR_SELECTED`, reads `GENERATED_ID` and writes it into the `ACCOUNT` key via `MO_ENTITY->SET_PROPERTY`.

No BAdI needed – the write-back is a `PROCESS_EVENT` redefinition on the standard feeder, exactly like the S4E cost centre solution.

**Rules**

* Position 1-3 – group: `288` Main / `484` Interim In / `485` Interim Out / `253` IHB / `488` Interim IHB.
* Position 4-5 – bank code: the 2-char code of the exact bank row the user picked in the OVS. Each `(Bank account# N)` variant is its own row with its own code (`Deutsche Bank` = `03`, `Deutsche Bank (Bank account# 2)` = `33`, `… # 3` = `3A`, `… # 4` = `3B`). The "use a different code when the bank + currency already exists" rule (concept slide 6) is a manual selection by the user – not derived.
* Position 6-7 – currency code: 2-char code per ISO currency.
* Position 8 – planning digit: Main → `0`, Interim In → `1`, Interim Out → per payment method (`T/U/Y/Z/M/2 → 3`, `A/B/W/X → 6`, `C/H/G → 1`, `D → 2`, `N → 4`, `X-Tax → 5`, `O → 8`, `F → 9`).

**Confirmed against concept slides 5 & 8**

* `253` (IHB main) → position 8 `0` (slide 5 example `25399060`).
* `488` (Interim IHB) → position 8 from the same payment-method table as `485` (slide 5 example `48899063` → digit `3`).
* Payment method `X` appears twice in the source (digit 6 SFS-netting, digit 5 Tax) – first row wins.

**Out of scope:** the cash-management planning levels (`F0` / `01`–`06`, concept slides 9–11) are a separate topic, not part of the GL account.

`ZCL_MDG_ID_NUMGEN_FACTORY` routes `(ACCOUNT, SGRE)` → `ZCL_MDG_SG_ACCT_ID_GEN` / `ZMDG_S_SG_ACCT_NAMING`.

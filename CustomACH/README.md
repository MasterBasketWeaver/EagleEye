# Custom ACH for Eagle Eye

Eagle Eye's add-ons to **Custom ACH** (BryanA BC Developments Inc.), the Payment Journal process that
generates the EFT (ACH) file before the vendor remittances are exported.

| Folder | App | Object IDs |
|---|---|---|
| `Custom ACH App` | Custom ACH Eagle Eye | 81300–81349 |
| `Custom ACH Test App` | Custom ACH Eagle Eye Tests (sandbox only) | 81350–81399 |

**Custom ACH Eagle Eye** gives files from Custom ACH's Generate EFT File the standard entry/addenda count.
The ACHCustom PTE adds one to that count for the offset entry its `BANK OF COMMERCE-V1` format writes as a
footer line, which is right for that format and one over for any format without that line. The fix only
applies to Custom ACH runs (`"BAACH Generate EFT".IsGeneratingEFTFile()`).

**Custom ACH Eagle Eye Tests** generates real `BANK OF COMMERCE-V1` files and checks the offset entry, counts,
totals and entry hash. It joins the Custom ACH Tests suite through `"BAACH Suite".OnAfterAllCodeunits`.

## Dependencies

These apps are not in this repo; download their symbols from the environment before compiling.

- Custom ACH Eagle Eye → Custom ACH 28.0.1.0 → BALIC Licensing 1.0.0.0
- Custom ACH Eagle Eye Tests → Custom ACH Tests 28.0.1.0 and Custom ACH Eagle Eye

Custom ACH, Custom ACH Eagle Eye and BALIC Licensing are installed as PTEs in DEV-SANDBOX.

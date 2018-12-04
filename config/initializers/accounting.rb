CLASSIFICATIONS = [
  { id: 1, :is_debit => true, name: "Harta" },
  { id: 2, :is_debit => false, name: "Utang" },
  { id: 3, :is_debit => false, name: "Modal" },
  { id: 4, :is_debit => false, name: "Pendapatan" },
  { id: 5, :is_debit => true, name: "Beban" }
]

#satu setting inputan "PurchaseOrder", "DirectPurchase"
#AllocatedReturnItem membalikan barang PurchaseOrder / DirectPurchase ke vendor
JOURNALTYPE = ["AccountPayable", "PurchaseOrder", "CashDisbursement", "Sale", "Tax"]

#accounting payment invoice belum ada
# Adjustment masuk ke mana?

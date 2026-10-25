import Mathlib

/-! Executable negative corpus for M0 boundary and false-claim handling. -/
namespace M0

theorem m0_neg_01_not_two_dvd_three : ¬ ((2 : Nat) ∣ 3) := by
  norm_num

theorem m0_neg_02_not_forall_succ_le : ¬ (∀ n : Nat, n + 1 ≤ n) := by
  intro h
  have h0 := h 0
  omega

end M0

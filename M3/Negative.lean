import M0.Benchmark

/-! M3 executable negative corpus: false-claim boundary checks. -/
namespace M3

theorem m3_neg_01_not_two_eq_three : ¬ ((2 : Nat) = 3) := by
  norm_num

theorem m3_neg_02_not_five_lt_three : ¬ ((5 : Nat) < 3) := by
  norm_num

theorem m3_neg_03_not_succ_eq_self : ¬ (∀ n : Nat, n + 1 = n) := by
  intro h
  have h0 := h 0
  omega

end M3

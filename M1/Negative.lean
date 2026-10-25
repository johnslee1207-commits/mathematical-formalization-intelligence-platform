import M0.Benchmark

/-! M1 executable negative corpus: two false-claim boundary checks. -/
namespace M1

theorem m1_neg_01_not_one_lt_zero : ¬ ((1 : Nat) < 0) := by
  omega

theorem m1_neg_02_not_all_zero_lt : ¬ (∀ n : Nat, 0 < n) := by
  intro h
  have h0 := h 0
  omega

end M1


import M0.Benchmark

/-! M7 number theory boundary checks. -/
namespace M7

theorem m7_neg_01_not_prime_one : ¬ Nat.Prime 1 := by norm_num
theorem m7_neg_02_not_three_dvd_four : ¬ ((3 : Nat) ∣ 4) := by norm_num
theorem m7_neg_03_not_gcd_two_three_two : ¬ (Nat.gcd 2 3 = 2) := by norm_num

end M7

import M0.Benchmark

/-! M7 number theory benchmark slice. -/
namespace M7

theorem m7_01_prime_two : Nat.Prime 2 := by norm_num

theorem m7_02_dvd_add_self (n : Nat) : n ∣ n + n := by
  exact ⟨2, by omega⟩

theorem m7_03_mod_self (n : Nat) : n % n = 0 := by
  exact Nat.mod_self n

theorem m7_04_gcd_self (n : Nat) : Nat.gcd n n = n := by
  exact Nat.gcd_self n

theorem m7_05_dvd_trans {a b c : Nat} : a ∣ b → b ∣ c → a ∣ c := by
  exact dvd_trans

end M7

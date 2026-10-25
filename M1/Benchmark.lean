import M0.Benchmark

/-! M1 first proof slice: five Lean/Mathlib formalization cases. -/
namespace M1

theorem m1_01_imp_trans (P Q R : Prop) : (P → Q) → (Q → R) → P → R := by
  intro hPQ hQR hP
  exact hQR (hPQ hP)

theorem m1_02_even_mul_two (n : Nat) : Even (2 * n) := by
  exact ⟨n, by omega⟩

theorem m1_03_sub_self (n : Nat) : n - n = 0 := by
  exact Nat.sub_self n

theorem m1_04_inter_subset_left {α : Type*} {A B : Set α} : A ∩ B ⊆ A := by
  intro x hx
  exact hx.1

theorem m1_05_exists_eq_self (α : Type*) [Nonempty α] : ∃ x : α, x = x := by
  let x : α := Classical.choice (inferInstance : Nonempty α)
  exact ⟨x, rfl⟩

theorem m1_06_or_comm (P Q : Prop) : P ∨ Q → Q ∨ P := by
  intro h
  exact h.elim Or.inr Or.inl

theorem m1_07_mul_le_mul_left {a b : Nat} : a ≤ b → ∀ c, c * a ≤ c * b := by
  intro h c
  exact Nat.mul_le_mul_left c h

theorem m1_08_inter_subset_right {α : Type*} {A B : Set α} : A ∩ B ⊆ B := by
  intro x hx
  exact hx.2

theorem m1_09_dvd_refl (n : Nat) : n ∣ n := by
  exact dvd_refl n

theorem m1_10_exists_zero : ∃ n : Nat, n = 0 := by
  exact ⟨0, rfl⟩

end M1

